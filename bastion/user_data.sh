echo "***** Instance ENV *****"
INSTANCE_ID=$(curl -s -m 60 http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(echo $AVAILABILITY_ZONE | sed 's/.$//')

yum update -y
pip install --upgrade awscli

echo "***** Setup SSH via IAM *****"
cat << EOF > /etc/aws-ec2-ssh.conf
IAM_AUTHORIZED_GROUPS="${IAM_AUTHORIZED_GROUPS}"
SUDOERS_GROUPS="${SUDOERS_GROUPS}"
ASSUMEROLE="${ASSUMEROLE}"
EOF

/usr/bin/import_users.sh
