output "role" {
  value = aws_iam_role.docker
}

output "role_execution" {
  value = aws_iam_role.docker-execution
}

output "task_definition" {
  value = "aws_ecs_task_definition.fargate"
}


output "role_arn" {
  value = aws_iam_role.docker.arn
}

output "role_name" {
  value = aws_iam_role.docker.name
}

output "role_execution_arn" {
  value = aws_iam_role.docker-execution.arn
}

output "task_definition_id" {
  value = aws_ecs_task_definition.fargate.id
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.fargate.arn
}

output "steps" {
  value = jsonencode({
    "Type" : "Task",
    "Resource" : "arn:aws:states:::ecs:runTask.sync",
    "Parameters" : {
      "LaunchType" : "FARGATE",
      "Cluster" : "${var.ecs_cluster_name}",
      "TaskDefinition" : "${aws_ecs_task_definition.fargate.id}",
      "Overrides" : {
        "ContainerOverrides" : [
          {
            "Environment" : [

            ]
          }
        ]
      }
    },
    "Next" : "${var.next}"
  })
}

