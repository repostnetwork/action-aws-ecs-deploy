#!/bin/bash

(
cd /usr/src
make aws-plan TERRAFORM_FLAGS=-auto-approve
)