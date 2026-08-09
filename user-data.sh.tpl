#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

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
chmod 600 /etc/altinitycloud/cloud-connect.pem

%{ if ca_crt != "" }
echo "${ca_crt}" > /etc/altinitycloud/ca.pem
%{ endif }

docker run -d --name=altinitycloud-connect --restart=always -v /etc/altinitycloud:/etc/altinitycloud:rw --network=host \
  %{ for host, alias in host_aliases } --add-host="${host}:${alias}" %{ endfor } "${image}" \
  --url=${url} -i /etc/altinitycloud/cloud-connect.pem %{ if ca_crt != "" } --ca-crt=/etc/altinitycloud/ca.pem %{ endif } \
  --capability aws

# Wait for container to be running
for i in $(seq 1 10); do
  if docker inspect --format='{{.State.Running}}' altinitycloud-connect 2>/dev/null | grep -q true; then
    break
  fi
  if [ "$i" -eq 10 ]; then
    echo "ERROR: cloud-connect container failed to start"
    exit 1
  fi
  sleep 3
done

aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id "$instance" \
  --lifecycle-hook-name ${asg_hook_name} --auto-scaling-group-name ${asg_name}
