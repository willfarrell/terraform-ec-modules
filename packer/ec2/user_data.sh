#!/usr/bin/env bash

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

echo "***** Setup X-Ray Service"
curl https://s3.dualstack.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.rpm -o /home/ec2-user/xray.rpm
yum install -y /home/ec2-user/xray.rpm
systemctl enable xray

echo "***** Setup Inspector Agent *****"
wget https://inspector-agent.amazonaws.com/linux/latest/install
bash install

echo "***** Setup SSM Agent *****"
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

echo "***** Setup the EFS mount helper *****"
yum install -y amazon-efs-utils

# TODO apply other CIS changes
# or swap out base image for https://aws.amazon.com/marketplace/pp/B078TPXMH2?qid=1530714745994&sr=0-1&ref_=srh_res_product_title

# TODO setup av
# https://www.centosblog.com/how-to-install-clamav-and-configure-daily-scanning-on-centos/

echo "***** Update *****"
yum update -y

echo "***** Services *****"
systemctl list-unit-files --state=enabled
