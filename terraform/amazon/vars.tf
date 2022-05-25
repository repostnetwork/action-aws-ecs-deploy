variable "region" {
  default = "us-east-1"
}

variable "logical_name" {
  description = "The base name to use for all aws resources."
}

variable "port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = "8080"
}

variable "container_count" {
  description = "Number of docker containers to run"
  default     = "1"
}

variable "cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "bucket" {
  description = "The s3 bucket to be used for terraform state"
}

variable "cluster_name" {
  default = "repost"
}

variable "ecs_task_container_role" {
  default = "ECSTaskAccess"
}

variable "ecs_task_execution_role" {
  default = "ecsTaskExecutionRole"
}

variable "ecr_path" {
  description = "Path of ECR containing all images"
  default     = "ecr_path"
}

variable "github_repository" {
  description = "The github repository that kicked off this deploy. In the form of 'repostnetwork/service-name'. GITHUB_REPOSITORY is an enviornment variable from github actions."
}

variable "env" {
  description = "Either 'staging' or 'production'"
}

variable "domain_name" {
  description = "Default is repostnetworktesting.com for staging and repostnetwork.com for prod"
}

variable "health_check_endpoint" {
  default = "/actuator/health"
}

variable "is_worker" {
  description = "Boolean: True if this ecs task is a worker. False otherwise."
  default     = false
}

variable "autoscaling_enabled" {
  default = true
}

variable "max_healthy_percent" {
  default = 600
}

variable "autoscaling_min_capacity" {
  default = 1
}

variable "autoscaling_max_capacity" {
  default = 8
}

variable "autoscaling_alarm_evaluation_periods" {
  default = 3
}

variable "autoscaling_datapoints_to_alarm" {
  default = 2
}

variable "autoscaling_alarm_period" {
  default = 60
}

variable "autoscaling_alarm_statistic" {
  default = "Average"
}

variable "autoscaling_alarm_threshold_high" {
  default = 60
}

variable "autoscaling_alarm_network_threshold_high" {
  default = 100
}

variable "autoscaling_alarm_network_threshold_low" {
  default = 20
}

variable "autoscaling_alarm_threshold_low" {
  default = 20
}

variable "autoscaling_resource_type" {
  default = "cpu" // or queue
}

variable "autoscaling_queue_name" {
  default = ""
}

variable "autoscaling_adjustment" {
  default = 1
}

variable "idle_timeout" {
  description = "The number of seconds to wait before an idle connection is closed."
  default     = 60
}

variable "health_check_grace_period" {
  description = "The number of seconds before starting healthchecks",
  default = 60
}

variable "waf_arn" {
  description = "ARN Reference for WAF"
}

variable "service_discovery_namespace_id" {
  description = "Namespace ID of Service Discovery"
}

provider "aws" {
  version = ">= 1.47.0"
  profile = "default"
  region  = var.region
}

terraform {
  backend "s3" {
    encrypt = true
    region  = "us-east-1"
  }
}

