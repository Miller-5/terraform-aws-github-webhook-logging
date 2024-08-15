## Manual steps we need to do:

Create github repository for terraform code (This one)

Create aws OIDC for github actions:
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1


Apply Policy & Role for github terraform repo (See related files) with AWS CLI


Put the following secrets in the terraform github repository:
* AWS role for github actions - AWS_ROLE_TO_ASSUME (from related file)
* AWS region - AWS_REGION

Create s3 bucket for terraform backend with AWS CLI


Create tf secrets for github provider (To create github repo)
* TF_VAR_github_token
* TF_VAR_github_owner


<!--
aws iam create-policy --policy-name ReadOnlySpecificSecrets --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": [
                "arn:aws:secretsmanager:<region>:<account-id>:secret:<github-app-secret-id>",
                "arn:aws:secretsmanager:<region>:<account-id>:secret:<iam-key-secret-id>"
            ]
        }
    ]
}'


created 2 secrets in secret manager 1- github limited app password 2- aws iam terraform role -->

