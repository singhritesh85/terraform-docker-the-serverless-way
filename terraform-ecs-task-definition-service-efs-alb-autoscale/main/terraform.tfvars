#################Provide Parameters for VPC########################

region = "us-east-2"

prefix = "ecs"

vpc_cidr = "10.10.0.0/16"
private_subnet_cidr = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
public_subnet_cidr = ["10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24"]
igw_name = "test-IGW"
natgateway_name = "ECS-NatGateway"
vpc_name = "test-vpc"

kms_key_id = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"   ### Provide the ARN of Key to encrypt EFS.

env = [ "dev", "stage", "prod" ]
cidr_blocks = ["0.0.0.0/0"]

################################Parameters to create ALB############################

application_loadbalancer_name = "ecs-alb"
internal = false
load_balancer_type = "application"
#subnets = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX"]
#security_groups = ["sg-05XXXXXXXXXXXXXXc"]  ## Security groups are not supported for network load balancer
enable_deletion_protection = false
s3_bucket_exists = false   ### Select between true and false. It true is selected then it will not create the s3 bucket. 
access_log_bucket = "s3bucketcapturealblogecs" ### S3 Bucket into which the Access Log will be captured
prefix_s3 = "application_loadbalancer_log_folder"
idle_timeout = 60
enabled = true
target_group_name = "ecs-tg"
container_port = 8080
instance_protocol = "HTTP"          #####Don't use protocol when target type is lambda
target_type_alb = ["instance", "ip", "lambda"]
#vpc_id = "vpc-XXXXXXXXXXXXXXXXX"
#ec2_instance_id = ""
load_balancing_algorithm_type = ["round_robin", "least_outstanding_requests"]
healthy_threshold = 2
unhealthy_threshold = 2
timeout = 3
interval = 30
healthcheck_path = "/login"
ssl_policy = ["ELBSecurityPolicy-2016-08", "ELBSecurityPolicy-TLS-1-2-2017-01", "ELBSecurityPolicy-TLS-1-1-2017-01", "ELBSecurityPolicy-TLS-1-2-Ext-2018-06", "ELBSecurityPolicy-FS-2018-06", "ELBSecurityPolicy-2015-05"]
certificate_arn = "arn:aws:acm:us-east-2:02XXXXXXXXX6:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
type = ["forward", "redirect", "fixed-response"]

#################################Parameter to create TAG_NUMBER######################

REPO_NAME = "027330342406.dkr.ecr.us-east-2.amazonaws.com/bankapp"
TAG_NUMBER = "1.01"
