output "user" {
  value = "${var.user}"
}
output "instance_ids" {
  value = "${join(",", aws_instance.vault.*.id)}"
}
output "private_ips" {
  value = "${join(",", aws_instance.vault.*.private_ip)}"
}

output "consul_datacenter" {
  value = "${var.region}"
}
