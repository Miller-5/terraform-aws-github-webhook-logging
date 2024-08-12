# terraform-aws-github-webhook-logging


Manual steps:
Created github repository for terraform code

created Role for terraform repo with pull specific secrets permissions

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


created 2 secrets in secret manager 1- github limited app password 2- aws iam terraform role

