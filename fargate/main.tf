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
  network_mode          = "awsvpc"           # ${join(",", data.null_data_source.environment.*.outputs.environment)}
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture      = upper(var.architecture)
  }
  # TODO add --local-mode to xray CMD to quite `[Error] Get instance id metadata failed: RequestError: send request failed`
  # https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon-ecs.html
  # Setting `--local-mode` quites the error message `[Error] Get instance id metadata failed: RequestError: send request failed`
  container_definitions = jsonencode(
[
  {
    "name" : "${var.prefix}-${var.name}",
    "image" : "${var.image}",
    "essential" : true,
    "cpu" : parseint(var.cpu, 10), 
    "memory": parseint(var.memory, 10),
    "command": var.command,
    "portMappings":[],
    "readonlyRootFilesystem": var.readonly,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group" : "/aws/ecs/${var.prefix}-${var.name}",
        "awslogs-region": local.region,
        "awslogs-stream-prefix": "ecs"
      }
    },
    "networkMode": "awsvpc",
    "networkConfiguration":{
      "awsvpcConfiguration":{
        "securityGroups": var.security_group_ids,
        "subnets": var.private_subnet_ids,
        "assignPublicIp": "DISABLED"
      }
    },
    "environment": [for key in keys(local.env): 
      {
        "name":key,
        "value":local.env[key]
      }
    ],
    "secrets": [for key in keys(var.secrets): 
      {
        "name":key,
        "valueFrom":"arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.secrets[key]}"
      }
    ],
    "mountPoints": [for volume in var.volumes: 
      {
        "containerPath": volume.container_path,
        "sourceVolume":volume.name
        "readOnly": volume.readOnly
      }
    ],
    "volumesFrom": [],
  }
]
)

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value["name"]
      dynamic "efs_volume_configuration" {
        for_each = volume.value["efs"] == null ? [] : [volume.value["efs"]]
        content {
          file_system_id = efs_volume_configuration.value["file_system_id"]
          root_directory = efs_volume_configuration.value["root_directory"] # Default: "/"
          transit_encryption = efs_volume_configuration.value["transit_encryption"] ? "ENABLED" : "DISABLED"
          dynamic "authorization_config" {
            for_each = try(efs_volume_configuration.value["access_point_id"], "") != "" ? [1] : []
            content {
              access_point_id = efs_volume_configuration.value["access_point_id"]
              iam             = efs_volume_configuration.value["iam"] ? "ENABLED" : "DISABLED"
            }
          }
        }
      }
    }
  }

  tags = {}
}

/*{
  "name": "xray-daemon"  ,
  "image": "public.ecr.aws/xray/aws-xray-daemon:3.x",
  "commnad": "--local-mode",
  "cpu": 32, #${parseint(var.cpu, 10) - 32},
  "memory": 128, #${parseint(var.memory, 10) - 128},
  "environment": [
    {
      "name": "AWS_REGION",
      "value": "${local.region}"
    }
  ],
  "readonlyRootFilesystem":true,
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group" : "/aws/xray/${var.prefix}-${var.name}",
      "awslogs-region": "${local.region}",
      "awslogs-stream-prefix": "xray"
    }
  },
  "portMappings": [
    {
      "protocol": "udp",
      "containerPort": 2000
    }
  ]
},*/

/*resource "aws_cloudwatch_log_group" "xray" {
  name = "/aws/xray/${var.prefix}-${var.name}"
  retention_in_days = var.retention_in_days
  kms_key_id = var.kms_key_arn
}*/

resource "aws_cloudwatch_log_group" "docker" {
  name = "/aws/ecs/${var.prefix}-${var.name}"
  retention_in_days = var.retention_in_days == 0 ? (terraform.workspace == "production" ? 365 : 7) : var.retention_in_days
  kms_key_id = var.kms_key_arn
}


resource "aws_iam_role" "docker" {
  name               = "${var.prefix}-${var.name}-docker-role"
  assume_role_policy = jsonencode(
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
})
}

resource "aws_iam_role_policy_attachment" "main-docker-AWSXRayDaemonWriteAccess" {
  role       = aws_iam_role.docker.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role" "docker-execution" {
  name               = "${var.prefix}-${var.name}-docker-execution-role"
  assume_role_policy = jsonencode(
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
)
}

resource "aws_iam_role_policy_attachment" "main-docker-execution-AmazonECSTaskExecutionRolePolicy" {
  role       = aws_iam_role.docker-execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# secrets
resource "aws_iam_role_policy_attachment" "main-docker-ssm-env" {
  count = length(keys(var.secrets)) > 0 ? 1 : 0
  role       = aws_iam_role.docker-execution.name
  policy_arn = aws_iam_policy.main-docker-ssm-env[0].arn
}

resource "aws_iam_policy" "main-docker-ssm-env" {
  count = length(keys(var.secrets)) > 0 ? 1 : 0
  name   = "${var.name}-ssm-env-policy"
  policy = data.aws_iam_policy_document.main-docker-ssm-env[0].json
}

data "aws_iam_policy_document" "main-docker-ssm-env" {
  count = length(keys(var.secrets)) > 0 ? 1 : 0
  statement {
    sid       = "SSMEnv"
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = [
      for key in keys(var.secrets): "arn:aws:ssm:${local.region}:${local.account_id}:parameter/${var.secrets[key]}"
    ]
  }
}