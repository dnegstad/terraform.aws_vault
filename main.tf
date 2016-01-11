module "scripts" {
  source = "github.com/pk4media/terraform.scripts"
}

resource "aws_security_group" "server" {
  name = "${var.name}-server"
  description = "Vault server permissions."

  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name}-server"
    Environment = "${var.environment}"
    Service = "vault"
  }

  ingress {
    from_port = 8200
    to_port   = 8200
    protocol  = "tcp"
    security_groups = ["${aws_security_group.client.id}"]
  }

  // Outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "client" {
  name = "${var.name}-client"
  description = "Vault client permissions."

  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name}-client"
    Environment = "${var.environment}"
    Service = "vault"
  }
}

module "consul_acl" {
  source = "github.com/pk4media/terraform.consul_acl"

  name   = "${var.name}"
  id     = "${var.consul_acl_token}"
  type   = "client"
  rules  = "${file(concat(path.module, "/vault_acl.hcl"))}"

  token  = "${var.consul_acl_register_token}"

  host   = "${var.consul_host}"
  user   = "${var.consul_user}"
  private_key = "${var.consul_private_key}"

  basion_host = "${var.bastion_host}"
  bastion_user = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
}

resource "template_file" "consul_tls" {
  template = "${file(module.scripts.ubuntu_consul_tls_setup)}"

  vars {
    ca   = "${var.consul_ca}"
    cert = "${var.consul_tls_cert}"
    key  = "${var.consul_tls_key}"
  }
}

resource "template_file" "consul_service" {
  template = "${file(concat(path.module, "/vault_service.sh.tpl"))}"

  vars {
    name = "${var.name}"
  }
}

resource "template_file" "consul" {
  template = "${file(module.scripts.ubuntu_consul_setup)}"

  vars {
    region                  = "${var.region}"
    atlas_token             = "${var.atlas_token}"
    atlas_username          = "${var.atlas_username}"
    atlas_environment       = "${var.atlas_environment}"
    encryption              = "${var.encryption}"
    acl_datacenter          = "${var.acl_datacenter}"
    acl_token               = "${var.consul_acl_token}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "template_file" "vault" {
  template = "${file(module.scripts.ubuntu_vault_tls_setup)}"

  vars {
    cert = "${var.tls_cert}"
    key  = "${var.tls_key}"
  }
}

resource "template_file" "vault" {
  template = "${file(module.scripts.ubuntu_vault_setup)}"

  count = "${length(split(",", var.private_subnets))}"

  vars {
    private_ip = "${element(split(",", var.private_ips), count.index)}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "atlas_artifact" "vault" {
  name = "${var.atlas_username}/vault"
  type = "amazon.image"
}

resource "aws_instance" "vault" {
  count         = "${length(split(",", var.private_subnets))}"

  ami           = "${lookup(atlas_artifact.vault.metadata_full, concat("region-", var.region))}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.ec2_key_name}"
  subnet_id     = "${element(split(",", var.subnet_ids), count.index)}"
  private_ip    = "${element(split(",", var.private_ips), count.index)}"

  instance_type = "${var.instance_type}"

  vpc_security_group_ids = [
    "${var.bastion_security_group_id}",
    "${aws_security_group.server.id}",
    "${var.consul_agent_security_group_id}"
  ]

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
    Service     = "vault"
  }

  connection {
    user         = "${var.user}"
    host         = "${self.private_ip}"
    private_key  = "${var.private_key}"
    bastion_host = "${var.bastion_host}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${var.bastion_private_key}"
  }

  # Copy Consul certificates
  provisioner "remote-exec" {
    inline = [
    "${template_file.consul_tls.rendered}"
    ]
  }

  provisioner "remote-exec" {
    inline = [
    "${template_file.consul_service.rendered}"
    ]
  }

  # Provision the Consul server
  provisioner "remote-exec" {
    inline = [
    "{template_file.consul.rendered}"
    ]
  }

  # Wait for consul to connect
  provisioner "remote-exec" {
    script = "${path.module}/wait_join.sh"
  }

  provisioner "remote-exec" {
    inline = [
    "${template_file.vault_tls.rendered}"
    ]
  }

  # Provision the Vault server
  provisioner "remote-exec" {
    inline = [
    "${element(template_file.vault.*.rendered, count.index)}"
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "user" {
  value = "${var.user}"
}
output "private_ips" {
  value = "${join(",", aws_instance.consul.*.private_ip)}"
}
output "client_security_group_id" {
  value = "${aws_security_group.client.id}"
}

output "consul_datacenter" {
  value = "${var.region}"
}
