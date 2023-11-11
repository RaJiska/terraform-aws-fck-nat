#!/bin/sh

: > /etc/fck-nat.conf
echo "eni_id=${TERRAFORM_ENI_ID}" >> /etc/fck-nat.conf
echo "eip_id=${TERRAFORM_EIP_ID}" >> /etc/fck-nat.conf
echo "cwagent_enabled=${TERRAFORM_CWAGENT_ENABLED}" >> /etc/fck-nat.conf
echo "cwagent_cfg_param_arn=${TERRAFORM_CWAGENT_CFG_PARAM_ARN} >> /etc/fck-nat.conf

service fck-nat restart
