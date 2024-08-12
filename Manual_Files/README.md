## Manual steps we need to do:

Create github repository for terraform code


Apply Policy & Role for github terraform repo (See related files)


Put the following secrets in the terraform github:
* AWS role for github actions - AWS_ROLE_TO_ASSUME
* AWS region - AWS_REGION




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

