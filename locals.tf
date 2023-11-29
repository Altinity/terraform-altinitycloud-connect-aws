locals {
  name = "altinitycloud-connect-${random_id.this.hex}"
  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "random_id" "this" {
  byte_length = 7
}
