data "aws_ami" "main" {
  count       = length(var.images)
  most_recent = true

  filter {
    name = "name"

    values = [
      var.images[count.index],
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm",
    ]
  }

  owners = [
    local.account_id
  ]
}

resource "aws_ami_launch_permission" "main" {
  count      = length(local.pairs)
  image_id   = split("|", local.pairs[count.index])[1]
  account_id = split("|", local.pairs[count.index])[0]
}