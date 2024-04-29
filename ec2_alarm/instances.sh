#!/bin/bash
# echo '{"profile":"default","region":"us-east-1"}' | bash instances.sh


# Exit if any of the intermediate steps fail
set -e
eval "$(jq -r '@sh "export PROFILE=\(.profile) REGION=\(.region)"')"

# Query list of instances in lower environments (i.e. "Environment" Tag that is NOT Production,Prod or DR)
aws ec2 describe-instances \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Reservations[*].Instances[?Tags[?Key==`Environment` && (Value!=`Production` && Value!=`DR` && Value!=`Prod`)]].[InstanceId]' \
    > nonprod_instance-ids.json

# Query list of instances in Prod and DR environments
aws ec2 describe-instances \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Reservations[*].Instances[*].[InstanceId]' \
    --filters "Name=tag:Environment,Values=DR,Production,Prod" \
    > prod_instance-ids.json

# Use previous list from lower environments to construct JSON data paired with disk dimensions.
grep i- nonprod_instance-ids.json | xargs -I {} \
aws cloudwatch list-metrics \
    --namespace CWAgent \
    --metric-name disk_used_percent \
    --profile "$PROFILE" \
    --region "$REGION" \
    --dimensions Name=InstanceId,Value={} \
    --recently-active PT3H  \
    --query 'Metrics[?contains(Dimensions[].Value, `/`) || contains(Dimensions[].Value, `/cq`) || contains(Dimensions[].Value, `/hybris`) || contains(Dimensions[].Value, `/opt`)]' \
    | jq -r '{Dimensions: [.[] | {path: .Dimensions[] | select(.Name == "path").Value, InstanceId: .Dimensions[] | select(.Name == "InstanceId").Value}]}' \
    | jq -r 'flatten' | jq -s '[.[][]]' | jq -n '.Dimensions |= inputs' | jq -c > nonprod_disk_paths.json

# Use previous list from Prod environments to construct JSON data paired with disk dimensions.
grep i- prod_instance-ids.json | xargs -I {} \
aws cloudwatch list-metrics \
    --namespace CWAgent \
    --metric-name disk_used_percent \
    --profile "$PROFILE" \
    --region "$REGION" \
    --dimensions Name=InstanceId,Value={} \
    --recently-active PT3H  \
    --query 'Metrics[?contains(Dimensions[].Value, `/`) || contains(Dimensions[].Value, `/cq`) || contains(Dimensions[].Value, `/hybris`) || contains(Dimensions[].Value, `/opt`)]' \
    | jq -r '{Dimensions: [.[] | {path: .Dimensions[] | select(.Name == "path").Value, InstanceId: .Dimensions[] | select(.Name == "InstanceId").Value}]}' \
    | jq -r 'flatten' | jq -s '[.[][]]' | jq -n '.Dimensions |= inputs' | jq -c > prod_disk_paths.json
