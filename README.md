# AWS Fargate Action

A GitHub action to deploy to AWS Fargate.

## Usage
#### Prerequisites

- The .aws/credentials file must be present and aws must be configured already.

```
workflow "Deploy" {
  on = "push"
  resolves = ["fargate deploy"]
}

action "fargate deploy" {
  uses = "repostnetwork/aws-fargate-action@master"
  env = {
    ENV = "staging"
    PORT = "8080"
    CONTAINER_COUNT = "2"
    CPU = "256"
    MEMORY = "512"
  }
}
```

## Additional Notes

All `.tf` files are loaded in alphabetical order and appended to one another. Order of resource / data definitions does not matter because it is declarative.

If you simply leave out AWS credentials, Terraform will automatically search for saved API credentials (for example, in ~/.aws/credentials) or IAM instance profile credentials. 

`terraform init` is used to set up environment, enabling the rest of the commands.
