#!/bin/bash
set -euo pipefail

yum update -y && yum -y install docker && systemctl enable --now docker && usermod -a -G docker ec2-user

imdsv2_token=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instance=$(curl -H "X-aws-ec2-metadata-token: $imdsv2_token" http://169.254.169.254/latest/meta-data/instance-id)

on_exit() {
  rc=$?
  # mark instance unhealthy in case of failure
  if [ $rc -ne 0 ]; then
    aws autoscaling complete-lifecycle-action --lifecycle-action-result ABANDON --instance-id "$instance" \
      --lifecycle-hook-name ${asg_hook_name} --auto-scaling-group-name ${asg_name}
  fi
  exit $rc
}

trap on_exit EXIT

mkdir -p /etc/altinitycloud
aws ssm get-parameter --name "${ssm_parameter_name}" --with-decryption --query "Parameter.Value" --output text > /etc/altinitycloud/cloud-connect.pem
docker run -d --name=altinitycloud-connect --restart=always -v /etc/altinitycloud:/etc/altinitycloud:rw --network=host "${image}" \
  --url=${url} -i /etc/altinitycloud/cloud-connect.pem --capability aws

aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id "$instance" \
  --lifecycle-hook-name ${asg_hook_name} --auto-scaling-group-name ${asg_name}
