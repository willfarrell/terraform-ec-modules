# placed inside template

echo "***** Setup SSH via IAM *****"
cat << EOF > /etc/aws-ec2-ssh.conf
IAM_AUTHORIZED_GROUPS="${IAM_AUTHORIZED_GROUPS}"
SUDOERS_GROUPS="${SUDOERS_GROUPS}"
ASSUMEROLE="${ASSUMEROLE}"
EOF

/usr/bin/import_users.sh
