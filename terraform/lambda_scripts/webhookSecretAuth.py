import os
import hmac
import hashlib

def lambda_handler(event, context):
    # Extract the token from the authorization header
    token = event.get('authorizationToken')
    if not token:
        raise Exception("Unauthorized!")

    # Get the secret from environment variables
    secret = os.environ['WEBHOOK_SECRET']
    
    # Example of a precomputed expected signature
    expected_signature = "sha256=<your_expected_signature_here>"

    # Compare the incoming token with the expected signature
    if hmac.compare_digest(token, expected_signature):
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
        raise Exception("Unauthorized!")