SHELL := /bin/bash
AWS_REGION := ${AWS_REGION}
PORT := ${PORT}
CONTAINER_COUNT := ${CONTAINER_COUNT}
AUTOSCALING_MIN_CAPACITY := ${AUTOSCALING_MIN_CAPACITY}
AUTOSCALING_MAX_CAPACITY := ${AUTOSCALING_MAX_CAPACITY}
AUTOSCALING_ALARM_NETWORK_THRESHOLD_LOW := ${AUTOSCALING_ALARM_NETWORK_THRESHOLD_LOW}
AUTOSCALING_ALARM_NETWORK_THRESHOLD_HIGH := ${AUTOSCALING_ALARM_NETWORK_THRESHOLD_HIGH}
AUTOSCALING_ADJUSTMENT := ${AUTOSCALING_ADJUSTMENT}
LOGICAL_NAME := ${LOGICAL_NAME}
CPU := ${CPU}
ENV := ${ENV}
MEMORY := ${MEMORY}
TERRAFORM_BUCKET := ${TERRAFORM_BUCKET}
GITHUB_REPOSITORY := ${GITHUB_REPOSITORY}
IS_WORKER := ${IS_WORKER}
DOMAIN_NAME := ${DOMAIN_NAME}
IDLE_TIMEOUT := ${IDLE_TIMEOUT}
WAF_ARN := ${WAF_ARN}
SERVICE_DISCOVERY_NAMESPACE_ID := ${SERVICE_DISCOVERY_NAMESPACE_ID}
HEALTH_CHECK_ENDPOINT := ${HEALTH_CHECK_ENDPOINT}
HEALTH_CHECK_GRACE_PERIOD := ${HEALTH_CHECK_GRACE_PERIOD}
TAG := ${TAG}
VOLUME_SIZE := ${VOLUME_SIZE}

ifndef IS_WORKER
    IS_WORKER := false
endif
ifndef AUTOSCALING_ENABLED
    AUTOSCALING_ENABLED := true
endif
ifndef DOMAIN_NAME
    DOMAIN_NAME := default
endif
ifndef TERRAFORM_BUCKET
    TERRAFORM_BUCKET := repost-terraform-${ENV}
endif
ifndef TAG
    TAG := latest
endif
ifndef VOLUME_SIZE
    VOLUME_SIZE := 21
endif

AWS_DIR=$(CURDIR)/terraform/amazon
TERRAFORM_FLAGS :=
AWS_TERRAFORM_FLAGS = -var "region=$(AWS_REGION)" \
		-var "github_repository=$(GITHUB_REPOSITORY)" \
		-var "port=$(PORT)" \
		-var "container_count=$(CONTAINER_COUNT)" \
		-var "autoscaling_min_capacity=$(AUTOSCALING_MIN_CAPACITY)" \
		-var "autoscaling_max_capacity=$(AUTOSCALING_MAX_CAPACITY)" \
		-var "autoscaling_alarm_threshold_high=$(AUTOSCALING_ALARM_THRESHOLD_HIGH)" \
		-var "autoscaling_alarm_threshold_low=$(AUTOSCALING_ALARM_THRESHOLD_LOW)" \
        -var "autoscaling_alarm_period_low=$(AUTOSCALING_ALARM_PERIOD_LOW)" \
        -var "autoscaling_alarm_period_high=$(AUTOSCALING_ALARM_PERIOD_HIGH)" \
		-var "autoscaling_alarm_network_threshold_low=$(AUTOSCALING_ALARM_NETWORK_THRESHOLD_LOW)" \
		-var "autoscaling_alarm_network_threshold_high=$(AUTOSCALING_ALARM_NETWORK_THRESHOLD_HIGH)" \
		-var "autoscaling_resource_type=$(AUTOSCALING_RESOURCE_TYPE)" \
		-var "autoscaling_kds_stream_name=$(AUTOSCALING_KDS_STREAM_NAME)" \
		-var "autoscaling_queue_name=$(AUTOSCALING_QUEUE_NAME)" \
		-var "autoscaling_adjustment=$(AUTOSCALING_ADJUSTMENT)" \
		-var "cpu=$(CPU)" \
		-var "env=$(ENV)" \
		-var "memory=$(MEMORY)" \
		-var "logical_name=$(LOGICAL_NAME)" \
		-var "tag=$(TAG)" \
		-var "bucket=$(TERRAFORM_BUCKET)" \
		-var "is_worker=$(IS_WORKER)" \
		-var "domain_name=$(DOMAIN_NAME)" \
		-var "autoscaling_enabled=$(AUTOSCALING_ENABLED)" \
		-var "idle_timeout=$(IDLE_TIMEOUT)" \
		-var "waf_arn=$(WAF_ARN)" \
		-var "service_discovery_namespace_id=${SERVICE_DISCOVERY_NAMESPACE_ID}" \
		-var "health_check_endpoint=$(HEALTH_CHECK_ENDPOINT)" \
		-var "health_check_grace_period=$(HEALTH_CHECK_GRACE_PERIOD)" \
		-var "volume_size=$(VOLUME_SIZE)"

.PHONY: aws-init
aws-init:
	@:$(call check_defined, AWS_REGION, Amazon Region)
	@:$(call check_defined, LOGICAL_NAME, Name for all aws resources)
	@:$(call check_defined, PORT, Container port)
	@:$(call check_defined, ENV, Environment (staging or production))
	@:$(call check_defined, TERRAFORM_BUCKET, s3 bucket name to store the terraform state)
	@cd $(AWS_DIR) && terraform init \
		-backend-config "bucket=$(TERRAFORM_BUCKET)" \
		-backend-config "key=$(LOGICAL_NAME)" \
		-backend-config "region=$(AWS_REGION)" \
		$(AWS_TERRAFORM_FLAGS)

.PHONY: terraform-validate
terraform-validate: ## Validate terraform scripts.
	@cd $(AWS_DIR) && echo "$$(docker run --rm -it --entrypoint bash -w '/mnt' -v $$(pwd):/mnt hashicorp/terraform -c 'terraform validate -check-variables=false . && echo [OK] terraform')"

.PHONY: aws-plan
aws-plan: aws-init ## Run terraform plan for Amazon.
	@cd $(AWS_DIR) && terraform plan \
		$(AWS_TERRAFORM_FLAGS)

.PHONY: aws-apply
aws-apply: aws-init ## Run terraform apply for Amazon.
	@cd $(AWS_DIR) && terraform apply \
		$(AWS_TERRAFORM_FLAGS) \
		$(TERRAFORM_FLAGS)

check_defined = \
				$(strip $(foreach 1,$1, \
				$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
				  $(if $(value $1),, \
				  $(error Undefined $1$(if $2, ($2))$(if $(value @), \
				  required by target `$@')))

.PHONY: update
update: update-terraform ## Update terraform binary locally.

TERRAFORM_BINARY:=$(shell which terraform || echo "/usr/local/bin/terraform")
TMP_TERRAFORM_BINARY:=/tmp/terraform
.PHONY: update-terraform
update-terraform: ## Update terraform binary locally from the docker container.
	@echo "Updating terraform binary..."
	$(shell docker run --rm --entrypoint bash hashicorp/terraform -c "cd \$\$$(dirname \$\$$(which terraform)) && tar -Pc terraform" | tar -xvC $(dir $(TMP_TERRAFORM_BINARY)) > /dev/null)
	sudo mv $(TMP_TERRAFORM_BINARY) $(TERRAFORM_BINARY)
	sudo chmod +x $(TERRAFORM_BINARY)
	@echo "Update terraform binary: $(TERRAFORM_BINARY)"
	@terraform version

# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
	DOCKER_FLAGS += -t
endif

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
