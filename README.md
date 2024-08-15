# terraform-aws-github-webhook-logging

todo
lambda python: validate, export info, push to s3


extra ideas for next time:

create tf modules
use github action instead of aws

places we can do better:

webhook validation happen at lambda step which is the last step before s3, we should find a way to validate it at the start of the flow
implemet github webhook HMAC signature validation with lambda after sqs - load handle is *1000%* better however webhook validation happens only late in the flow which can result in invalid requests sent by an attacker being processed, best practice is to validate as soon as we can, thats why I decided to give the priority to security instead of load handle 

why i decided to go with api vtl, how hmac and api gw auth works