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
  network_mode          = "awsvpc"           // ${join(",", data.null_data_source.environment.*.outputs.environment)}
  #cpu_architecture      = upper(var.architecture)
  // TODO add --local-mode to xray CMD to quite `[Error] Get instance id metadata failed: RequestError: send request failed`
  # https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon-ecs.html
  # Setting `--local-mode` quites the error message `[Error] Get instance id metadata failed: RequestError: send request failed`
  container_definitions = <<DEFINITION
[
  {
    "name": "xray-daemon"  ,
    "image": "public.ecr.aws/xray/aws-xray-daemon:3.x",
    "commnad": "--local-mode",
    "cpu": 32,
    "memory": 128,
    "environment": [
      {
        "name": "AWS_REGION",
        "value": "${local.aws_region}"
      }
    ],
    "readonlyRootFilesystem":true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group" : "/aws/xray/${var.prefix}-${var.name}",
        "awslogs-region": "${local.aws_region}",
        "awslogs-stream-prefix": "xray"
      }
    },
    "portMappings": [
      {
        "protocol": "udp",
        "containerPort": 2000
      }
    ]
  },
  {
    "name": "${var.prefix}-${var.name}",
    "image": "${var.image}",
    "essential":true,
    "cpu":${parseint(var.cpu, 10) - 32},
    "memory":${parseint(var.memory, 10) - 128},
    "environment":${local.ecs_environment},
    "portMappings":[],
    "mountPoints":${local.ecs_mount_points},
    "readonlyRootFilesystem":${var.readonly},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group" : "/aws/ecs/${var.prefix}-${var.name}",
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
  # Add in sidecar x-ray container

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value["name"]
      efs_volume_configuration {
        file_system_id = volume.value["file_system_id"]
        root_directory = try(volume.value["root_directory"], "/")
        transit_encryption = "ENABLED"
        dynamic "authorization_config" {
          for_each = try(volume.value["access_point_id"], "") != "" ? [1] : []
          content {
            access_point_id = volume.value["access_point_id"]
            iam             = "DISABLED" #volume.value["iam"] != "ENABLED" ? "DISABLED" : "ENABLED"
          }
        }
      }
    }
  }

  tags = {}
}

resource "aws_cloudwatch_log_group" "xray" {
  name = "/aws/xray/${var.prefix}-${var.name}"
  retention_in_days = var.retention_in_days
  kms_key_id = var.kms_key_arn
}

resource "aws_cloudwatch_log_group" "docker" {
  name = "/aws/ecs/${var.prefix}-${var.name}"
  retention_in_days = var.retention_in_days
  kms_key_id = var.kms_key_arn
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

resource "aws_iam_role_policy_attachment" "main-docker-AWSXRayDaemonWriteAccess" {
  role       = aws_iam_role.docker.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
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
