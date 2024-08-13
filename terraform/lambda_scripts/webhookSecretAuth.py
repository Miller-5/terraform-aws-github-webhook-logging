import hashlib
import hmac
import os

def lambda_handler(event, context):
    token = event['authorizationToken']
    secret = os.environ['WEBHOOK_SECRET']
    signature = 'sha256=' + hmac.new(secret.encode(), event['body'].encode(), hashlib.sha256).hexdigest()
    
    if hmac.compare_digest(token, signature):
        return {
            "principalId": "user",
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": "execute-api:Invoke",
                        "Effect": "Allow",
                        "Resource": event['methodArn']
                    }
                ]
            }
        }
    else:
        return {
            "principalId": "user",
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": "execute-api:Invoke",
                        "Effect": "Deny",
                        "Resource": event['methodArn']
                    }
                ]
            }
        }
