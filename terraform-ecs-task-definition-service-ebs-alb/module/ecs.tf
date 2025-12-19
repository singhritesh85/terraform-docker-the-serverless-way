################################# Security Group of MySQL Container #################################

resource "aws_security_group" "mysql_container_access" {
 name        = "mysql-container-access-${var.env}"
 description = "MySQL Port 3306 Access"
 vpc_id      = aws_vpc.test_vpc.id

ingress {
   description = "Allow Port 3306"
   from_port   = 3306
   to_port     = 3306
   protocol    = "tcp"
   cidr_blocks = ["10.10.0.0/16"]
 }

egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

################################# Security Group of BankApp Container #################################

resource "aws_security_group" "bankapp_container_access" {
 name        = "bankapp-container-access-${var.env}"
 description = "BankApp Port 8080 Access"
 vpc_id      = aws_vpc.test_vpc.id

ingress {
   description = "Allow Port 8080"
   from_port   = 8080
   to_port     = 8080
   protocol    = "tcp"
   security_groups = [aws_security_group.ecs_alb.id]
 }

egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

####################################### IAM Role for ECS ############################################

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ssm_access" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel" 
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm_access_policy" {
  name        = "SSM-Access-Policy-for-ECS"
  description = "SSM Access Policy for ECS"
  policy      = data.aws_iam_policy_document.ssm_access.json
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole-dexter"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment_ssm" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_access_policy.arn
}

data "aws_iam_policy_document" "ecs_ebs_infrastructure_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:DescribeSnapshots",
      "ec2:DescribeAvailabilityZones",
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_ebs_infrastructure_policy" {
  name        = "CustomAmazonECSInfrastructureRolePolicyForVolumes"
  description = "Allows ECS tasks to manage EBS volumes"
  policy      = data.aws_iam_policy_document.ecs_ebs_infrastructure_policy.json
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_volumes_role" {
  name               = "ecs-volumes-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
  description        = "IAM role for ECS infrastructure with volumes policy"
}

resource "aws_iam_role_policy_attachment" "ecs_volumes_attachment" {
  role       = aws_iam_role.ecs_volumes_role.name
  policy_arn = aws_iam_policy.ecs_ebs_infrastructure_policy.arn
}

####################################### CloudWatch LogGroup #########################################

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "${var.prefix}-log-group"
}

resource "aws_cloudwatch_log_group" "ecs_log_group_mysql" {
  name = "${var.prefix}-log-group-mysql"
}

####################################### CloudMap Namespace ##########################################

resource "aws_service_discovery_http_namespace" "cloudmap_namespace" {
  name        = "${var.prefix}-ecs-cluster"
  description = "CloudMap Namespace to be used in service connect"
}

####################################### ECS Cluster #################################################

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.prefix}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
#      kms_key_id = var.kms_key_id
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = false   ###true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_log_group.name
      }
    }
    
#    managed_storage_configuration {
#      fargate_ephemeral_storage_kms_key_id = ""    ###var.kms_key_id
#      kms_key_id = var.kms_key_id
#    }
  }
}

########################################### ECS Task Definition MySQL #####################################

resource "aws_ecs_task_definition" "ecs_task_definition_mysql" {
  family = "${var.prefix}-task-definition-mysql"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  task_role_arn = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
  {
    name = "mysql"
    image = "public.ecr.aws/docker/library/mysql:8.0.44-bookworm"
    mountPoints = [{
      sourceVolume  = "mysql-storage"
      containerPath = "/var/lib/mysql"
      readOnly      = false
    }],
    environment = [
      {
        name  = "MYSQL_DATABASE" 
        value = "bankappdb"
      },
      {
        name  = "MYSQL_ROOT_PASSWORD"
        value = "Dexter@123"
      }
    ],
    essential = true
    portMappings = [
      {
        name     = "mysql"
        containerPort = 3306
        hostPort = 3306
        protocol = "tcp"
      }
    ],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group_mysql.name
        "awslogs-region"        = data.aws_region.reg.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }
]) 
   
  volume {
    name      = "mysql-storage"
    configure_at_launch = true
  }
}

##################################################### ECS Service MySQL ########################################################

resource "aws_ecs_service" "ecs_service_mysql" {
  name            = "${var.prefix}-service-mysql2"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition_mysql.arn
  desired_count   = 1
  availability_zone_rebalancing = "ENABLED"
  launch_type = "FARGATE"
  platform_version = "LATEST"
  scheduling_strategy = "REPLICA"
  enable_execute_command = true  ### Allow or not to login into your container 
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent       = 200

  deployment_configuration {
    strategy = "ROLLING"
  }  

  deployment_circuit_breaker {
    enable = true
    rollback = true
  }

  network_configuration {
    assign_public_ip = false
    security_groups = [aws_security_group.mysql_container_access.id]
    subnets = aws_subnet.private_subnet.*.id 
  }  

  volume_configuration {
    name = "mysql-storage"
    managed_ebs_volume {
      encrypted = true
      role_arn = aws_iam_role.ecs_volumes_role.arn
      file_system_type = "xfs"
      kms_key_id = var.kms_key_id
      size_in_gb = 1
      volume_type = "gp3"
    }  
  }  

  service_connect_configuration {
    enabled = true
    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group_mysql.name
        "awslogs-region"        = data.aws_region.reg.region
        "awslogs-stream-prefix" = "service-connect-access-logs-mysql"
      }
    } 
    namespace = aws_service_discovery_http_namespace.cloudmap_namespace.name 
    service {
      client_alias {
        dns_name = "mysql-service.mysql"
        port     = 3306
      }
      port_name = "mysql"
    }  
  }  
  depends_on = [aws_iam_role_policy_attachment.ecs_volumes_attachment, aws_iam_policy.ecs_ebs_infrastructure_policy]
}

########################################### ECS Task Definition BankApp #####################################

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = "${var.prefix}-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  task_role_arn = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions    = jsonencode([
  {
    name = "bankapp"
    image = "${var.REPO_NAME}:${var.TAG_NUMBER}"
    environment = [
      {
        name  = "JDBC_URL"
        value = "jdbc:mysql://mysql-service.mysql:3306/bankappdb?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC"
      },
      {
        name  = "JDBC_PASS" 
        value = "Dexter@123"
      },
      {
        name  = "JDBC_USER"
        value = "root"
      }
    ],
    essential = true
    portMappings = [
      {
        name     = "bankapp"
        containerPort = 8080
        hostPort = 8080
        protocol = "tcp"
      }
    ],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
        "awslogs-region"        = data.aws_region.reg.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }
])
}

##################################################### ECS Service BankApp ########################################################

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.prefix}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 1
  availability_zone_rebalancing = "ENABLED"
  launch_type = "FARGATE"
  platform_version = "LATEST"
  scheduling_strategy = "REPLICA"
  enable_execute_command = true    ### Allow or not to login into your container
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent       = 200

  deployment_configuration {
    strategy = "ROLLING"
  }

  deployment_circuit_breaker {
    enable = true
    rollback = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "bankapp"
    container_port   = var.container_port
  }

  network_configuration {
    assign_public_ip = false
    security_groups = [aws_security_group.bankapp_container_access.id]
    subnets = aws_subnet.private_subnet.*.id 
  }

  service_connect_configuration {
    enabled = true
    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
        "awslogs-region"        = data.aws_region.reg.region
        "awslogs-stream-prefix" = "service-connect-access-logs"
      }
    }
    namespace = aws_service_discovery_http_namespace.cloudmap_namespace.name
  }

  depends_on = [aws_ecs_service.ecs_service_mysql]
}

