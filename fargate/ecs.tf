//resource "aws_ecs_service" "fargate" {
//  name            = "${var.prefix}-${var.name}"
//  cluster         = var.ecs_cluster_name
//  launch_type     = "FARGATE"
//  task_definition = aws_ecs_task_definition.fargate.arn
//  desired_count   = 0
//
//  network_configuration {
//    security_groups = var.security_group_ids
//    subnets         = var.private_subnet_ids
//  }
//
//  //  lifecycle {
//  //    ignore_changes = ["desired_count"]
//  //  }
//}

resource "aws_ecs_task_definition" "fargate" {
  family                   = "${var.prefix}-${var.name}"
  task_role_arn            = aws_iam_role.docker.arn
  execution_role_arn       = aws_iam_role.docker-execution.arn
  requires_compatibilities = [
    "FARGATE"]

  cpu                   = var.cpu
  memory                = var.memory
  network_mode          = "awsvpc"
  container_definitions = <<DEFINITION
[
  {
    "name": "${var.prefix}-${var.name}",
    "image": "${var.image}",
    "essential":true,
    "cpu":${var.cpu},
    "memory":${var.memory},
    "environment":[${join(",", data.null_data_source.environment.*.outputs.environment)}],
    "portMappings":[],
    "mountPoints":[],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group" : "/ecs/${var.prefix}-${var.name}",
        "awslogs-region": "${local.aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "networkMode": "awsvpc",
    "networkConfiguration":{
      "awsvpcConfiguration":{
        "securityGroups":${jsonencode(var.security_group_ids)},
        "subnets":${jsonencode(var.private_subnet_ids)},
        "assignPublicIp": "DISABLED"
      }
    }
  }
]
DEFINITION

  /*tags = merge(
  local.tags,
  {
    Name = local.name
  }
  )*/
}

resource "aws_cloudwatch_log_group" "docker" {
  name = "/ecs/${var.prefix}-${var.name}"
}


resource "aws_iam_role" "docker" {
  name               = "${var.prefix}-${var.name}-docker-role"
  assume_role_policy = <<ROLE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
ROLE
}

resource "aws_iam_role" "docker-execution" {
  name               = "${var.prefix}-${var.name}-docker-execution-role"
  assume_role_policy = <<ROLE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
ROLE
}

resource "aws_iam_role_policy_attachment" "main-docker-execution-AmazonECSTaskExecutionRolePolicy" {
  role       = aws_iam_role.docker-execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
