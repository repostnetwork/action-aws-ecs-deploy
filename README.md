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