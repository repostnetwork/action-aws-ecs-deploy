#!/bin/bash

(
cd /usr/src
make aws-apply TERRAFORM_FLAGS=-auto-approve
)