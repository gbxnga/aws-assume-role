#!/bin/bash


AWS_NEW_USER="test-user-cf"
ROLE_NAME="example-role-cf"
AWS_ACCOUNT_ID="<AWS_ACCOUNT_ID>"


ASSUME_ROLE_CREDENTIALS=$(aws sts assume-role --role-arn "arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME" --role-session-name AWSCLI-Session --profile "$AWS_NEW_USER")

echo "Credentials response: $ASSUME_ROLE_CREDENTIALS"


AWS_ACCESS_KEY_ID=$(echo "$ASSUME_ROLE_CREDENTIALS" | jq -r '.Credentials.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo "$ASSUME_ROLE_CREDENTIALS" | jq -r '.Credentials.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo "$ASSUME_ROLE_CREDENTIALS" | jq -r '.Credentials.SessionToken')

echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN


aws sts get-caller-identity 

# Will fail because arn:aws:sts::212423532071:assumed-role/example-role/AWSCLI-Session role now assumed
# only has AmazonS3ReadOnlyAccess policy attached to it. Where as the test-user has a 'list-roles'
# policy attched to them, but we are not using that particular user at this stage, but the ASSUMED ROLE
aws iam list-roles 

# This will get the buckets successfully because the assumed role has AmazonS3ReadOnlyAccess policy attched to it
aws s3 ls