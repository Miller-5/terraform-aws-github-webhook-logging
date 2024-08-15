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

github secret rotation

github files changed in webhook is not included, webhook sends link for API that shows files changed
although this is a good idea to keep the payload lighter, it creates the requirment to send a request to github API with github token that as for now theres no option to create automatically which makes the process to have another manual step at the middle of the architecture deployment flow
there is open issue for this:
https://github.com/go-gitea/gitea/issues/18216


finegrained tokens are more secured however require an additional manual steps after terraform deployment which includes create finegrained token with limited permissions to use API call, then push it to aws secret manager and modify lambda to have the permission to pull this token from secret manager
for simplicity I've used terraform github token which is less secure because it has more permissions than needed however this process can be done automatically