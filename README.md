# terraform-aws-github-webhook-logging

todo
lambda python: validate, export info, push to s3


extra ideas for next time:

create tf modules
use github action instead of aws
implemet github webhook HMAC signature validation with lambda validating it

places we can do better:

webhook validation happen at lambda step which is the last step before s3, we should find a way to validate it at the start of the flow