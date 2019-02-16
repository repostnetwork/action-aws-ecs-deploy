variable "region" {
  default = "us-east-1"
}

variable "az_count" {
  description = "Number of availability zones to cover in a given AWS region"
  default     = "2"
}

variable "port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default = "8080"
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
  default = "ecr_path"
}

variable "github_repository" {
  description = "The github repository that kicked off this deploy. In the form of 'repostnetwork/service-name'. GITHUB_REPOSITORY is an enviornment variable from github actions."
}

variable "env" {
  description = "Either 'staging' or 'production'"
}

variable "health_check_endpoint" {
  default = "/actuator/health"
}

provider "aws" {
  version = ">= 1.47.0"
  profile = "default"
  region = "${var.region}"
}

terraform {
  backend "s3" {
    encrypt = true
    region = "us-east-1"
    # Path to write state to.
    key = "repost-terraform"
  }
}
