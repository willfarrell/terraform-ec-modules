output "id" {
  value = aws_efs_file_system.main.id
}

output "dns_name" {
  value = aws_efs_file_system.main.dns_name
}

output "mount_target_ids" {
  value = aws_efs_mount_target.main.*.id
}

output "mount_target_dns_names" {
  value = aws_efs_mount_target.main.*.dns_name
}

output "mount_target_network_interface_ids" {
  value = aws_efs_mount_target.main.*.network_interface_id
}

output "security_group_id" {
  value = aws_security_group.external.id
}

output "iam_policy_arn" {
  value = aws_iam_policy.main.arn
}

