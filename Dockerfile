FROM repostnetwork/deploy-utils:latest

LABEL "com.github.actions.name"="AWS ECS Deploy"
LABEL "com.github.actions.description"="Deploy to ECS"
LABEL "com.github.actions.icon"="cloud"
LABEL "com.github.actions.color"="red"

ENV AWS_REGION "us-east-1"
ENV PORT "8080"
ENV CONTAINER_COUNT "1"
ENV AUTOSCALING_MIN_CAPACITY "1"
ENV AUTOSCALING_MAX_CAPACITY "8"
ENV AUTOSCALING_ALARM_THRESHOLD_LOW "20"
ENV AUTOSCALING_ALARM_THRESHOLD_HIGH "60"
ENV AUTOSCALING_ALARM_PERIOD_LOW "60"
ENV AUTOSCALING_ALARM_PERIOD_HIGH "60"
ENV AUTOSCALING_ALARM_NETWORK_THRESHOLD_LOW "20"
ENV AUTOSCALING_ALARM_NETWORK_THRESHOLD_HIGH "100"
ENV AUTOSCALING_RESOURCE_TYPE "cpu"
ENV AUTOSCALING_QUEUE_NAME ""
ENV AUTOSCALING_KDS_STREAM_NAME ""
ENV AUTOSCALING_ADJUSTMENT "1"
ENV CPU "256"
ENV MEMORY "512"
ENV IDLE_TIMEOUT "60"
ENV HEALTH_CHECK_ENDPOINT "/actuator/health"
ENV HEALTH_CHECK_GRACE_PERIOD "120"
ENV WAF_ARN ""
ENV SERVICE_DISCOVERY_NAMESPACE_ID ""
ENV USE_EFS "false"
ENV EFS_NAME ""
ENV EFS_FILE_SYSTEM_ID "foo"
ENV EFS_ACCESS_POINT_ID ""
ENV EFS_PATH ""

COPY terraform /usr/src/terraform
COPY Makefile /usr/src
COPY deploy.sh /usr/local/bin/deploy

WORKDIR /usr/src

ENTRYPOINT [ "deploy" ]
