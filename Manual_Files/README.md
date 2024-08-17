## Manual steps we need to do for first time run:

1. Clone this github repository




2. Create aws OIDC for github actions in AWS account:  
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1





3. Apply Policy & Role for github terraform repo (See related files in the same folder) with AWS CLI




4. Put the following secrets in the terraform github repository:  
    * AWS role for github actions - AWS_ROLE_TO_ASSUME (Role name can be found in related file in the same folder)
    * AWS region - AWS_REGION




5. Create s3 bucket for terraform backend with AWS CLI




6. Create tf secrets for github provider in terraform repository (For GH action to be able to create github repo automatically)
    * TF_VAR_github_token
    * TF_VAR_github_owner




> You are now ready to execute github action on terraform repo and deploy the infrastructure!