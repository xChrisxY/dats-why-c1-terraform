resource "aws_security_group" "main" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_security_group_rule" "ingress" {
  count             = length(var.ingress_rules)
  type              = "ingress"
  security_group_id = aws_security_group.main.id

  from_port   = var.ingress_rules[count.index].from_port
  to_port     = var.ingress_rules[count.index].to_port
  protocol    = var.ingress_rules[count.index].protocol
  cidr_blocks = lookup(var.ingress_rules[count.index], "cidr_blocks", null)
  description = lookup(var.ingress_rules[count.index], "description", null)

  source_security_group_id = lookup(var.ingress_rules[count.index], "source_security_group_id", null)
}

resource "aws_security_group_rule" "egress" {
  count             = length(var.egress_rules) > 0 ? length(var.egress_rules) : 1
  type              = "egress"
  security_group_id = aws_security_group.main.id

  from_port   = length(var.egress_rules) > 0 ? var.egress_rules[count.index].from_port : 0
  to_port     = length(var.egress_rules) > 0 ? var.egress_rules[count.index].to_port : 0
  protocol    = length(var.egress_rules) > 0 ? var.egress_rules[count.index].protocol : "-1"
  cidr_blocks = length(var.egress_rules) > 0 ? lookup(var.egress_rules[count.index], "cidr_blocks", ["0.0.0.0/0"]) : ["0.0.0.0/0"]
  description = length(var.egress_rules) > 0 ? lookup(var.egress_rules[count.index], "description", "Allow all outbound") : "Allow all outbound"
}
