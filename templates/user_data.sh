#!/bin/sh
%{ for key, value in TERRAFORM_ENV_VARS ~}
export ${key}="${value}"
%{ endfor ~}

: > /etc/fck-nat.conf
echo "eni_id=${TERRAFORM_ENI_ID}" >> /etc/fck-nat.conf
echo "eip_id=${TERRAFORM_EIP_ID}" >> /etc/fck-nat.conf
echo "cwagent_enabled=${TERRAFORM_CWAGENT_ENABLED}" >> /etc/fck-nat.conf
echo "cwagent_cfg_param_name=${TERRAFORM_CWAGENT_CFG_PARAM_NAME}" >> /etc/fck-nat.conf
%{ for key, value in TERRAFORM_ADDITIONAL_CONFIG ~}
echo "${key}=${value}" >> /etc/fck-nat.conf
%{ endfor ~}

service fck-nat restart
