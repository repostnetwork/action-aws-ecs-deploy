FROM repostnetwork/ecs-deploy:latest

LABEL "com.github.actions.name"="AWS Fargate"
LABEL "com.github.actions.description"="Deploy to AWS Fargate on push to the master branch"
LABEL "com.github.actions.icon"="cloud"
LABEL "com.github.actions.color"="red"

ARG ENV

ENV ENV $ENV
ENV TERRAFORM_BUCKET "repost-terraform-$ENV"
ENV AWS_REGION "us-east-1"
ENV PORT "8080"
ENV CONTAINER_COUNT "1"
ENV CPU "256"
ENV MEMORY "512"

COPY terraform /usr/src/terraform
COPY Makefile /usr/src
COPY deploy.sh /usr/local/bin/deploy

WORKDIR /usr/src

ENTRYPOINT [ "deploy" ]