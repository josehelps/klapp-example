provider "aws" {
  profile    = var.aws_profile
  region     = var.aws_region
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
}


# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  count                   = "${length(var.subnets)}"
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${element(values(var.subnets), count.index)}"
  map_public_ip_on_launch = true
  availability_zone       = "${element(keys(var.subnets), count.index)}"
  depends_on              = ["aws_internet_gateway.default"]
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_security_group" "default" {
  name        = "allow_whitelist"
  description = "Allow all inbound traffic from whilisted IPs in vars file of terraform attack range"
  vpc_id      = "${aws_vpc.default.id}"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.ip_whitelist
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_honeypot_ports" {
  name        = "allow_honeypot_ports"
  description = "Allow inbound traffic to honeypot, these are the ports that are exploitable for"
  vpc_id      = "${aws_vpc.default.id}"
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# standup splunk server
 resource "aws_instance" "klapp_honeypot" {
  ami           = var.ubuntu_ami
  instance_type = "t2.medium"
  key_name = var.key_name
  subnet_id = "${aws_subnet.default.1.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}", "${aws_security_group.allow_honeypot_ports.id}"]
  tags = {
    Name = "klapp_honeypot"
    Type = "ssh"
  }

 provisioner "local-exec" {
    working_dir = "ansible"
    command = "sleep 10; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ${var.private_key_path} -i '${aws_instance.klapp_honeypot.public_ip},' playbooks/klapp.yml"
  }
}

resource "aws_eip" "ip" {
  instance = aws_instance.klapp_honeypot.id
}

output "ip" {
  value = "${aws_eip.ip.public_ip}"
}

