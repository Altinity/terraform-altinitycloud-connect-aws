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

%{ if ca_crt != "" }
echo "${ca_crt}" > /etc/altinitycloud/ca.pem
%{ endif }

docker run -d --name=altinitycloud-connect --restart=always -v /etc/altinitycloud:/etc/altinitycloud:rw --network=host \
  %{ for host, alias in host_aliases } --add-host="${host}:${alias}" %{ endfor } "${image}" \
  --url=${url} -i /etc/altinitycloud/cloud-connect.pem %{ if ca_crt != "" } --ca-crt=/etc/altinitycloud/ca.pem %{ endif } \
  --capability aws


# Healthcheck: mark instance unhealthy if cloud-connect container stops running
cat <<'HEALTHCHECK' > /usr/local/bin/cloud-connect-healthcheck.sh
#!/bin/bash
imdsv2_token=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $imdsv2_token" http://169.254.169.254/latest/meta-data/instance-id)
if ! docker inspect --format='{{.State.Running}}' altinitycloud-connect 2>/dev/null | grep -q true; then
  aws autoscaling set-instance-health --instance-id "$instance_id" --health-status Unhealthy
fi
HEALTHCHECK
chmod +x /usr/local/bin/cloud-connect-healthcheck.sh
echo "* * * * * root /usr/local/bin/cloud-connect-healthcheck.sh" > /etc/cron.d/cloud-connect-healthcheck

aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE --instance-id "$instance" \
  --lifecycle-hook-name ${asg_hook_name} --auto-scaling-group-name ${asg_name}
