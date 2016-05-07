variable "region" {}

variable "subnet_ids" {}
variable "autoscaler_name" {}

variable "public_security_group" {}

variable "record_name" {}
variable "dns_zone" {}

variable "instance_http_port" {
  default = 8080
}

variable "instance_https_port" {
  default = 6443
}

variable "idle_timeout" {
  default = 1200
}

resource "aws_elb" "deis-router-internal" {
  name = "deis-router-internal"
  subnets = ["${split(",", var.subnet_ids)}"]

  listener {
    instance_port = "${var.instance_http_port}"
    instance_protocol = "tcp"
    lb_port = "80"
    lb_protocol = "tcp"
  }

  listener {
    instance_port = "${var.instance_https_port}"
    instance_protocol = "tcp"
    lb_port = "443"
    lb_protocol = "tcp"
  }

  listener {
    instance_port = "2222"
    instance_protocol = "tcp"
    lb_port = "2222"
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:9090/healthz"
    interval = 10
  }

  idle_timeout = "${var.idle_timeout}"
  connection_draining = true
  internal = true

  provisioner "local-exec" {
    command = "aws autoscaling attach-load-balancers --region ${var.region} --auto-scaling-group-name ${var.autoscaler_name} --load-balancer-names ${aws_elb.deis-router-internal.name}"
  }
}

resource "aws_proxy_protocol_policy" "proxy_protocol-internal" {
  load_balancer = "${aws_elb.deis-router-internal.name}"
  instance_ports = ["${var.instance_http_port}", "${var.instance_https_port}"]
}



resource "aws_elb" "deis-router" {
  name = "deis-router"
  subnets = ["${split(",", var.subnet_ids)}"]
  security_groups = ["${var.public_security_group}"]

  listener {
    instance_port = "${var.instance_http_port}"
    instance_protocol = "tcp"
    lb_port = "80"
    lb_protocol = "tcp"
  }

  listener {
    instance_port = "${var.instance_https_port}"
    instance_protocol = "tcp"
    lb_port = "443"
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:9090/healthz"
    interval = 10
  }

  idle_timeout = "${var.idle_timeout}"
  connection_draining = true
  internal = false

  provisioner "local-exec" {
    command = "aws autoscaling attach-load-balancers --region ${var.region} --auto-scaling-group-name ${var.autoscaler_name} --load-balancer-names ${aws_elb.deis-router.name}"
  }
}

resource "aws_proxy_protocol_policy" "proxy_protocol" {
  load_balancer = "${aws_elb.deis-router.name}"
  instance_ports = ["${var.instance_http_port}", "${var.instance_https_port}"]
}

resource "aws_route53_record" "dns" {
  zone_id = "${var.dns_zone}"
  name = "${var.record_name}"
  type = "CNAME"
  ttl = "5"
  records = ["${aws_elb.deis-router-internal.dns_name}"]
}

output "elb_public" {
  value = "${aws_elb.deis-router.name}"
}

output "elb_internal" {
  value = "${aws_elb.deis-router-internal.name}"
}
