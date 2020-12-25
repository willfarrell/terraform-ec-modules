#!/usr/bin/env bash
# NOTE: Amazon Linux v1

cd /tmp

echo "***** Update *****"
yum update -y

#echo "***** Update awscli *****"
#curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#unzip awscliv2.zip
#bash ./aws/install
#rm -rf aws
#rm awscliv2.zip

#echo "***** Setup CloudWatch Logging *****"
#yum install awslogs -y
#
#cat << EOF > /etc/awslogs/awslogs.conf
#[general]
#state_file = /var/lib/awslogs/agent-state
#
#[messages]
#file = /var/log/messages
#log_stream_name = {instance_id}
#log_group_name = /aws/ec2/messages
#
#[cloud-init.log]
#file = /var/log/cloud-init.log
#log_stream_name = {instance_id}
#log_group_name = /aws/ec2/cloud-init.log
#
#[cloud-init-output.log]
#file = /var/log/cloud-init-output.log
#log_stream_name = {instance_id}
#log_group_name = /aws/ec2/cloud-init-output.log
#EOF
#
#cat << EOF > /etc/init.d/configure-awslogs
##!/usr/bin/env bash
#start() {
#  TOKEN=\$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
#  AVAILABILITY_ZONE=\$(curl -s -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
#  #INSTANCE_ID=\$(curl -s -m 60 -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
#  REGION=\$(echo \$AVAILABILITY_ZONE | sed 's/.\$//')
#  #sed -i "s@{instance_id}@\$INSTANCE_ID@g" /etc/awslogs/awslogs.conf
#  sed -i "s@us-east-1@\$REGION@g" /etc/awslogs/awscli.conf
#}
#
#case "\$1" in
#    start)
#       start
#       ;;
#    *)
#       echo "Usage: \$0 \$1"
#       ;;
#esac
#
#exit 0
#EOF
#chmod +x /etc/init.d/configure-awslogs
#chkconfig --add configure-awslogs
#chkconfig configure-awslogs on
# Amazon Linux v1
#service awslogs start
#chkconfig awslogs on
# Amazon Linux 2
#systemctl start awslogsd
#systemctl enable awslogsd.service

# Amazon Linux v1
#echo "***** Setup CloudWatch Agent *****"
#cat << EOF > /etc/cloudwatch-agent.conf
#{
#  "metrics": {
#    "append_dimensions": {
#      "AutoScalingGroupName": "\${aws:AutoScalingGroupName}",
#      "ImageId": "\${aws:ImageId}",
#      "InstanceId": "\${aws:InstanceId}",
#      "InstanceType": "\${aws:InstanceType}"
#    },
#    "metrics_collected": {
#      "mem": {
#        "measurement": [
#          "mem_used",
#          "mem_cached",
#          "mem_total"
#        ],
#        "metrics_collection_interval": 10
#      },
#      "swap": {
#        "measurement": [
#          "swap_used",
#          "swap_free",
#          "swap_used_percent"
#        ],
#        "metrics_collection_interval": 10
#      },
#      "disk": {
#        "resources": [
#          "/",
#          "/tmp"
#        ],
#        "measurement": [
#          "free",
#          "total",
#          "used"
#        ],
#        "ignore_file_system_types": [
#          "sysfs",
#          "devtmpfs",
#          "tmpfs"
#        ],
#        "metrics_collection_interval": 60
#      }
#    }
#  }
#}
#EOF
#
#rpm -i https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
#/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/etc/cloudwatch-agent.conf -s

# Amazon Linux v1
echo "***** Setup Inspector Agent *****"
# https://docs.aws.amazon.com/inspector/latest/userguide/inspector_installing-uninstalling-agents.html
curl -O https://inspector-agent.amazonaws.com/linux/latest/install
bash install
rm install

# Amazon Linux v1
echo "***** Setup SSM Agent *****"
# https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-manual-agent-install.html
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo start amazon-ssm-agent

#echo "***** Services *****"
#aws --version
#systemctl list-unit-files --state=enabled