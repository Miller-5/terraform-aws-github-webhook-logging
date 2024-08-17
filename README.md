# Terraform for deploying Github & AWS infrastructure for webhook logging

This repository shows how we can set up an infrastructure automatically with github actions and terraform  
This was an interesting and fun task, and I will explain why I chose this architecture, challanges along the way  
and also out of scope improvments. 


## Architecture
### Lets start by a review of the architecture:

![Architecture](arch.png)

The request in the task mentioned to focus 3 key points:
* <span style="color: orange; text-align: left;">Security</span>  
* <span style="color: blue; text-align: left;">Load</span>  
* <span style="color: green; text-align: left;">Cost</span>	

According to those requirments, I've decided to go with the serverless option, which is a good choice to handle all 3 of those key points.  
The serverless option is very <span style="color: orange; text-align: left;">secured</span> because theres no host running our code therefor makes it harder to infiltrate to our system.  
It can also handle <span style="color: blue; text-align: left;">heavy load</span> if built correctly without much configuration,  
And its also very <span style="color: green; text-align: left;">cost effective</span> because we pay only for the traffic we get, storage and querys.  
This means this setup could be very cheap when theres no traffic, especially when some of the services we're using gives us free requests each month.  

## Current setup
This infrastructre can handle 10,000 (15,000 including throttling) **per second** without missing any webhook request (by our API GW) which is an overkill for our use case however its a good chance to show a robust system.  
All relevant webhook requests get sent to SQS which triggers lambdas, Maximum concurrent lambda executions is 1000 (without throttling), by using SQS we make sure that no request is getting left out even when lambdas are overwhelmed


## The flow
  
We have a github terraform repo (This one) that deploy the entire infrastructure:  

* Github repo- Including PR webhook to API GW with automatically generated secret by terraform to be shared with AWS side for validation
> **NOTE** - Github repo is public for demonstration purposes however the infrastructre is set up to use private repository which means it will work both ways, feel free to change it to private
* API GW- Including logic to filter only PR webhooks that are merged while also have basic validation for webhook
> This API GW also has **IP WHITELIST** for github webhooks IP's, the IP list gets pulled automatically by terraform and implemented to API GW
* SQS- Queue for incoming PR merged requests, I chose to use this service to be able to handle heavy load, even if for our use case this can be count as an overkill
* Lambda- Responsible for validating the webhook the standard way, filter the required parameters and send them to s3  
> This lambda uses custom KMS to encrypt its environment variables, although its wasn't required, its a good way to present parts that would be relevant with FEDRAMP env's
* S3- Stores our data and Athena query data
* Athena- Used to query data for better experience (Optional)  
AWS Athena Query example:
```sql
 SELECT 
   repository, 
   changed_files.added, 
   changed_files.removed, 
   changed_files.modified 
 FROM github_webhooks_table
 LIMIT 10;
```
 Example to use with AWS CLI-  
 Run the query:
 ```bash
 aws athena start-query-execution   --query-string "SELECT repository, changed_files.added, changed_files.removed, changed_files.modified FROM github_webhooks_table LIMIT 10;"   --query-execution-context Database=github_webhooks_db   --work-group github_webhook
 ```

 Get query results:
 ```bash
 aws athena get-query-results --query-execution-id [QUERY_EXECUTION_ID_FROM_PREVIOUS_COMMAND]
```



## How to use
To set up and use this repo on our github & aws environment, we need to follow these steps:
1. Set up manual steps - In case this is the first time you set this up, you need to execute some commands in order to set up permissions, Please go to **'Manual_Files'** folder where we can find a README.md with the required step if needed

2. Each push to our github terraform repo will trigger github action that will run terraform to deploy the entire infrastructure, including github repo and AWS resources with the right configuration

> Enjoy your new setup!

## Interesting decisions choices
* Github 'files changed' section in PR webhooks is not included, instead, the webhook shows a github API link for the repository that shows files changed.
Although this is a good idea to keep the payload lighter by not including it, it also creates the requirment to send a request to github API with github token that as for now theres no option to create automatically, which means that if we want to create repo scoped token (finegrained tokens, For better security) we need to do it manually after the terraform executed, which adds another manual step that can be avoided so I decided to use terraform github token that is also with limited permissions
there is open issue regarding this topic:
https://github.com/go-gitea/gitea/issues/18216

* I thought a lot about when to validate the payload with HMAC encryption, github webhook supports only HMAC and API GW does not support it, which is why we can use lambda function as a custom authorizer on API GW layer.  
The issue with it is that lambda authorizator has the lambda maximum concurrent executors is 1000 which can be a bottleneck if its on the API GW layer (Even though it is still overkill for our usecase) however you always want to have the authorization/validation at the earliest layer you can in order to avoid invalid requests.  
I tried to think on a creative solution and what I came up with is to use API GW to do basic validation with VTL script, and standard validation later on a lambda with alerts set up for failed validations, this way I get the most out of this infrastructure while not sacrificing important security measures to do so.

## Out of scope improvments
* We can have more logic in our github action workflow for better handling terraform, for example we can run terraform plan when we recieve a PR and terraform apply when merging this PR.
* Alerts on validation failure- 99% of validation failure means that someone is trying to temper with our system and we should investigate it, for example we can use SNS to notify the team for such case.
* We can use lifecycle for s3 to use glacier (or a similliar solution) to store old logs in a more cost efficient solution provider by amazon
* Instead of Athena & S3, we can use a database that will be more effective than the correct setup such as dynamoDB
* Hardening IAM policies - Roles are already limited and scoped, but theres always room to improve permission limitations
* Rotating secrets - It is recommended to rotate secrets, for example github secret can be rotated and implemented automatically by terraform on the services that use it
* IP WHITELIST Cronjob - each terraform run, terraform will pull the latest webhook IP list from github API and apply it to API GW, however this process happens only when terraform runs, to solve this issue we can create a crinjob that periodically checks the IP list for any changes
* WAF - WAF can be also implemented for extra layer of security behind API GW, In our case API GW handles some security measures however WAF offers advanced protection
* API GW logs - We can enable API GW logging to cloudwatch which can be very helpful.
* Monitoring - We can implement services for monitoring which can also be very helpful.
* Terraform modules - We can also implement terraform modules to have terraform better organized