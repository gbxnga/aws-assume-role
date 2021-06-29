#!/bin/bash

AWS_PROFILE="nss-new"
POLICY_FILE_DIRECTORY="example-policy.json"
ROLE_TRUST_POLICY_FILE_DIRECTORY="example-role-trust-policy.json"
AWS_REGION="eu-west-1"
AWS_NEW_USER="test-user"
ROLE_NAME="example-role"
AWS_ACCOUNT_ID="<AWS_ACCOUNT_ID>"

rm $POLICY_FILE_DIRECTORY
cat <<EOT >> $POLICY_FILE_DIRECTORY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "iam:ListRoles"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME"
        }
    ]
}
EOT

# Create the policy
POLICY_ARN=$(aws iam create-policy --policy-name example-policy --policy-document file://"$POLICY_FILE_DIRECTORY" --profile "$AWS_PROFILE" --region "$AWS_REGION" | jq -r '.Policy.Arn')

echo "Policy ARN: $POLICY_ARN"

# Attach the policy to the user
aws iam attach-user-policy --user-name "$AWS_NEW_USER" --policy-arn "$POLICY_ARN"


aws iam list-attached-user-policies --user-name "$AWS_NEW_USER"



rm $ROLE_TRUST_POLICY_FILE_DIRECTORY
cat <<EOT >> $ROLE_TRUST_POLICY_FILE_DIRECTORY
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Principal": { "AWS": "arn:aws:iam::$AWS_ACCOUNT_ID:user/$AWS_NEW_USER" },
        "Action": "sts:AssumeRole"
    }
}
EOT

# Create an example role
aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://"$ROLE_TRUST_POLICY_FILE_DIRECTORY"

# attaches the AWS Managed Policy S3FullAccess to the role
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"

aws iam list-attached-role-policies --role-name "$ROLE_NAME"

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