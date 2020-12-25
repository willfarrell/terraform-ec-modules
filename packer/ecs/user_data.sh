#!/usr/bin/env bash

# Docs
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html
# https://aws.amazon.com/premiumsupport/knowledge-center/ecs-agent-disconnected/

# Logs
# /var/log/cloud-init-output.log
# /var/log/ecs/ecs-agent.log

echo "***** Update *****"
yum update -y

echo "***** Update awscli *****"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws
rm awscliv2.zip

echo "***** Setup CloudWatch Logging *****"
yum install awslogs -y
cat << EOF > /usr/local/bin/configure-awslogs.sh
#!/usr/bin/env bash
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INSTANCE_ID=$(curl -s -m 60 -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
sed -i "s/log_stream_name =/log_stream_name = \$INSTANCE_ID/" /etc/awslogs/awslogs.conf
EOF
chmod +x /usr/local/bin/configure-awslogs.sh
sed -i '/ExecStart=/i ExecStartPre=/usr/local/bin/configure-awslogs.sh' /usr/lib/systemd/system/awslogsd.service
systemctl enable awslogsd

echo "***** Setup CloudWatch Agent *****"
cat << EOF > /etc/cloudwatch-agent.conf
{
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "\${aws:AutoScalingGroupName}",
      "ImageId": "\${aws:ImageId}",
      "InstanceId": "\${aws:InstanceId}",
      "InstanceType": "\${aws:InstanceType}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used",
          "mem_cached",
          "mem_total"
        ],
        "metrics_collection_interval": 10
      },
      "swap": {
        "measurement": [
          "swap_used",
          "swap_free",
          "swap_used_percent"
        ],
        "metrics_collection_interval": 10
      },
      "disk": {
        "resources": [
          "/",
          "/tmp"
        ],
        "measurement": [
          "free",
          "total",
          "used"
        ],
        "ignore_file_system_types": [
          "sysfs",
          "devtmpfs",
          "tmpfs"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

rpm -i https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/etc/cloudwatch-agent.conf -s

echo "***** Setup Inspector Agent *****"
curl -O https://inspector-agent.amazonaws.com/linux/latest/install
bash install

echo "***** Setup SSM Agent *****"
# https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-manual-agent-install.html
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

echo "***** Setup the EFS mount helper *****"
yum install -y amazon-efs-utils

echo "***** Setup ECS CLI *****"
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html
sudo curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
#echo "$(curl -s https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest.md5) /usr/local/bin/ecs-cli" | md5sum -c -

echo "***** Status Check *****"
service docker status
systemctl status ecs
systemctl status amazon-ssm-agent
systemctl status awslogsd

echo "***** Update *****"
yum update -y

echo "***** Services *****"
systemctl list-unit-files --state=enabled
