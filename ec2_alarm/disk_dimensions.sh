#!/bin/bash
#
# Forked from https://github.com/robin-zhao/terraform-aws-cloudwatch-metrics-for-ec2/blob/master/ec2_alarm/disk_dimensions.sh
#
# Example
# echo '{"profile":"default","region":"us-east-1","instance_id":"123","disk_path":"/"}' | bash disk_dimensions.sh


# Exit if any of the intermediate steps fail
set -e
eval "$(jq -r '@sh "export PROFILE=\(.profile) REGION=\(.region) DISK_PATH=\(.disk_path) INSTANCE_ID=\(.instance_id)"')"


#function parse_json_input() {
#    eval "$(jq -r '@sh "PROFILE=\(.profile) REGION=\(.region) DISK_PATH=\(.disk_path) INSTANCE_ID=\(.instance_id)"')"
#    if [[ "${PROFILE}" == null ]]; then exit 1; fi
#    if [[ "${REGION}" == null ]]; then exit 1; fi
#    if [[ "${DISK_PATH}" == null ]]; then exit 1; fi
#    if [[ "${INSTANCE_ID}" == null ]]; then exit 1; fi
#}
#parse_json_input


aws cloudwatch list-metrics \
    --namespace CWAgent \
    --metric-name disk_used_percent \
    --profile $PROFILE \
    --region $REGION \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    | jq -r --arg DISK_PATH "$DISK_PATH" '.Metrics[] | select(.Dimensions[].Value==$DISK_PATH)' \
    | jq -r '.Dimensions' | jq 'from_entries' | jq -c
