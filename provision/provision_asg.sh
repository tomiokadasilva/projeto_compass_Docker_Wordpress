#!/bin/bash

# Required Environment Variables:
#   WP_WP_SG_ID
#   WP_BASTION_KEY_NAME
#   WP_SSM_INSTANCE_PROFILE_NAME
#   WP_PRIV_SUBNET_1
#   WP_PRIV_SUBNET_2
#   WP_TG_ARN

set -e

export AWS_REGION=us-east-1
export AWS_DEFAULT_OUTPUT="text"
export TAGS='{"Key":"Task","Value":"Docker-WordPress"},{"Key":"Project","Value":"PB UNIVESP URI"},{"Key":"CostCenter","Value":"C092000004"}'

WP_LC_NAME="wordpress-task-lc"
aws autoscaling create-launch-configuration \
    --launch-configuration-name "$WP_LC_NAME" \
    --image-id ami-06a0cd9728546d178 \
    --instance-type t3.small \
    --security-groups "$WP_WP_SG_ID" \
    --key-name "$WP_BASTION_KEY_NAME" \
    --user-data "file://$(dirname "$0")/wordpress-user-data.sh" \
    --iam-instance-profile "$WP_SSM_INSTANCE_PROFILE_NAME"
echo "Launch configuration <$WP_LC_NAME> created"

WP_ASG_NAME="wordpress-task-asg"
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name "$WP_ASG_NAME" \
    --launch-configuration-name "$WP_LC_NAME" \
    --min-size 2 \
    --max-size 4 \
    --vpc-zone-identifier "$WP_PRIV_SUBNET_1,$WP_PRIV_SUBNET_2" \
    --target-group-arns "$WP_TG_ARN" \
    ----health-check-type "ELB" \
    --tags "[{\"Key\":\"Name\",\"Value\":\"$WP_ASG_NAME\"},$TAGS,\"PropagateAtLaunch\":true]"
echo "Auto Scaling Group <$WP_ASG_NAME> created"