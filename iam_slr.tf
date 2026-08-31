resource "aws_iam_service_linked_role" "this" {
  for_each = var.service_linked_roles

  aws_service_name = each.value
}
