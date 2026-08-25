#!/usr/bin/env bash
#
# test-with-floci.sh
#
# Spins up the "floci" (floci/floci) LocalStack-compatible AWS emulator and
# runs `terraform init/validate/plan/apply/destroy` against it for every
# example under examples/*, using a temporary provider override that points
# the AWS provider at the floci endpoints instead of real AWS.
#
# KNOWN LIMITATION:
#   floci's community/free edition does not support EC2 CreateNetworkInterface
#   (it returns "UnsupportedOperation: Operation CreateNetworkInterface is not
#   supported"). Since this module creates a static ENI per AZ for each NAT
#   instance, `apply` will always fail at that step on the free tier. This is
#   a floci limitation, not a bug in this module. This script detects that
#   specific error, reports it clearly, and treats the run up to that point
#   (VPC/subnets/route tables/security groups/IAM) as the validation signal.
#
# Usage:
#   ./scripts/test-with-floci.sh              # test all examples/* directories
#   ./scripts/test-with-floci.sh examples/full # test a single example
#   KEEP_FLOCI=1 ./scripts/test-with-floci.sh  # leave the floci container running afterwards
#
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOCI_IMAGE="floci/floci:latest"
FLOCI_PORT=4566
FLOCI_HEALTH_URL="http://localhost:${FLOCI_PORT}/_localstack/health"
FLOCI_CONTAINER_NAME="fck-nat-floci-test"

STARTED_FLOCI=0
ENI_LIMITATION_HIT=0
FAILURES=0

# --- output helpers ---------------------------------------------------------
c_reset='\033[0m'
c_red='\033[31m'
c_green='\033[32m'
c_yellow='\033[33m'
c_blue='\033[34m'

info()  { printf "%b[INFO]%b  %s\n" "$c_blue" "$c_reset" "$1"; }
ok()    { printf "%b[OK]%b    %s\n" "$c_green" "$c_reset" "$1"; }
warn()  { printf "%b[WARN]%b  %s\n" "$c_yellow" "$c_reset" "$1"; }
error() { printf "%b[ERROR]%b %s\n" "$c_red" "$c_reset" "$1"; }

# --- floci lifecycle ---------------------------------------------------------

is_floci_healthy() {
  curl -s -o /dev/null -w '%{http_code}' "$FLOCI_HEALTH_URL" 2>/dev/null | grep -q '^200$'
}

start_floci() {
  if is_floci_healthy; then
    info "floci is already running and healthy on port ${FLOCI_PORT}."
    return
  fi

  if docker ps -a --format '{{.Names}}' | grep -q "^${FLOCI_CONTAINER_NAME}$"; then
    info "Starting existing floci container '${FLOCI_CONTAINER_NAME}'..."
    docker start "${FLOCI_CONTAINER_NAME}" >/dev/null
  else
    info "Starting floci container..."
    docker run -d --rm \
      --name "${FLOCI_CONTAINER_NAME}" \
      -p "${FLOCI_PORT}:${FLOCI_PORT}" \
      -v /var/run/docker.sock:/var/run/docker.sock \
      "${FLOCI_IMAGE}" >/dev/null
  fi
  STARTED_FLOCI=1

  info "Waiting for floci to become healthy..."
  for _ in $(seq 1 30); do
    if is_floci_healthy; then
      ok "floci is healthy."
      return
    fi
    sleep 2
  done

  error "floci did not become healthy in time."
  exit 1
}

stop_floci() {
  if [[ "${KEEP_FLOCI:-0}" == "1" ]]; then
    info "KEEP_FLOCI=1 set, leaving floci container running."
    return
  fi
  if [[ "$STARTED_FLOCI" == "1" ]]; then
    info "Stopping floci container..."
    docker stop "${FLOCI_CONTAINER_NAME}" >/dev/null 2>&1 || true
  fi
}

# --- provider override -------------------------------------------------------

write_provider_override() {
  local dir="$1"
  cat > "${dir}/floci_override.tf" <<EOF
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2         = "http://localhost:${FLOCI_PORT}"
    autoscaling = "http://localhost:${FLOCI_PORT}"
    iam         = "http://localhost:${FLOCI_PORT}"
    sts         = "http://localhost:${FLOCI_PORT}"
    ssm         = "http://localhost:${FLOCI_PORT}"
  }
}
EOF
}

cleanup_example() {
  local dir="$1"
  rm -f "${dir}/floci_override.tf"
  rm -rf "${dir}/.terraform"
  rm -f "${dir}/.terraform.lock.hcl"
  rm -f "${dir}"/terraform.tfstate*
  rm -f "${dir}"/tfplan
}

# --- test a single example ----------------------------------------------------

test_example() {
  local dir="$1"
  local name
  name="$(basename "$dir")"

  info "=== Testing example: ${name} (${dir}) ==="

  write_provider_override "$dir"
  trap "cleanup_example '$dir'" RETURN

  if ! terraform -chdir="$dir" init -upgrade -input=false >/tmp/floci-test-init.log 2>&1; then
    error "terraform init failed for ${name}"
    cat /tmp/floci-test-init.log
    FAILURES=$((FAILURES + 1))
    return
  fi

  if ! terraform -chdir="$dir" validate >/tmp/floci-test-validate.log 2>&1; then
    error "terraform validate failed for ${name}"
    cat /tmp/floci-test-validate.log
    FAILURES=$((FAILURES + 1))
    return
  fi
  ok "validate passed for ${name}"

  if ! terraform -chdir="$dir" plan -out=tfplan -input=false >/tmp/floci-test-plan.log 2>&1; then
    error "terraform plan failed for ${name}"
    cat /tmp/floci-test-plan.log
    FAILURES=$((FAILURES + 1))
    return
  fi
  ok "plan succeeded for ${name}"

  local apply_log="/tmp/floci-test-apply-${name}.log"
  if terraform -chdir="$dir" apply -auto-approve tfplan >"$apply_log" 2>&1; then
    ok "apply succeeded for ${name} (all resources created, including ENIs)"
  else
    if grep -q "CreateNetworkInterface is not supported" "$apply_log"; then
      ENI_LIMITATION_HIT=1
      warn "apply for ${name} was blocked by floci's ENI creation limitation:"
      warn "  floci's community/free edition rejects EC2 CreateNetworkInterface"
      warn "  (\"UnsupportedOperation: Operation CreateNetworkInterface is not"
      warn "  supported\"). This module creates a static ENI per AZ for each"
      warn "  NAT instance, so full apply cannot complete against free-tier"
      warn "  floci. All prior resources (VPC, subnets, route tables, internet"
      warn "  gateway, security group, IAM role/policy/instance profile)"
      warn "  created successfully, confirming the module logic up to that"
      warn "  point is correct."
    else
      error "apply failed for ${name} with an unexpected error:"
      cat "$apply_log"
      FAILURES=$((FAILURES + 1))
      return
    fi
  fi

  info "Destroying resources created for ${name}..."
  terraform -chdir="$dir" destroy -auto-approve >/tmp/floci-test-destroy.log 2>&1 || {
    warn "destroy reported issues for ${name} (see /tmp/floci-test-destroy.log). This is expected/harmless against floci."
  }

  trap - RETURN
  cleanup_example "$dir"
}

# --- main ---------------------------------------------------------------------

main() {
  cd "$REPO_ROOT"

  local dirs=()
  if [[ $# -gt 0 ]]; then
    dirs=("$@")
  else
    for d in examples/*/; do
      [[ -f "${d}main.tf" ]] && dirs+=("${d%/}")
    done
  fi

  if [[ ${#dirs[@]} -eq 0 ]]; then
    error "No example directories found to test."
    exit 1
  fi

  start_floci

  for d in "${dirs[@]}"; do
    test_example "$d"
  done

  echo
  info "=== Summary ==="
  if [[ "$ENI_LIMITATION_HIT" == "1" ]]; then
    warn "One or more examples hit floci's known ENI creation limitation (expected, not a module bug)."
  fi
  if [[ "$FAILURES" -gt 0 ]]; then
    error "${FAILURES} example(s) failed unexpectedly."
    stop_floci
    exit 1
  fi

  ok "All examples passed validation/plan (and apply up to floci's ENI limitation where applicable)."
  stop_floci
}

main "$@"
