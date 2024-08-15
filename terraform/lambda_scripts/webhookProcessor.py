import os
import hmac
import hashlib
import json
import boto3
import requests
from botocore.exceptions import ClientError

# S3 client
s3 = boto3.client('s3')

# Environment variables
SHARED_SECRET = os.environ['WEBHOOK_SECRET']
S3_BUCKET = os.environ['S3_BUCKET']
GITHUB_TOKEN = os.environ['GITHUB_TOKEN']

def lambda_handler(event, context):
    for record in event['Records']: # For sqs batch support

        # Extract the SQS message body (GitHub webhook payload)
        message_body = record['body']
        
        # Extract the HMAC signature from the SQS message attributes
        signature_header = record['messageAttributes'].get('X-Hub-Signature-256')['stringValue']
        
        # Validate the HMAC signature
        if validate_hmac(message_body, signature_header):
            # Parse the payload and extract relevant information
            payload = json.loads(message_body)
            
            # Fetch changed files from GitHub API
            try:
                changed_files = fetch_changed_files(payload)
            except requests.exceptions.RequestException as e:
                print(f"HTTP request failed: {e}")
                raise


            # Create the log entry
            log_entry = {
                "repository": payload['repository']['full_name'],
                "changed_files": changed_files
            }

            try:
                # Push the log entry to S3
                upload_to_s3(log_entry)
            except ClientError as e:
                raise Exception(f"Failed to upload to S3: {e}")
        else:
            print(f"Invalid HMAC signature from IP: {record.get('attributes', {}).get('ApproximateFirstReceiveTimestamp')}")
            # We can apply here alert call, because 99% of failed validations means someone 
            # got access to our API GW and is trying to temper with the system
            # therefor we should investigate and act accordingly after getting an alert of this kind
            

def validate_hmac(payload, signature_header):
    computed_signature = 'sha256=' + hmac.new(SHARED_SECRET.encode(), payload.encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(computed_signature, signature_header)

def fetch_changed_files(payload):
    # Extract necessary information from the webhook payload
    repo_name = payload['repository']['full_name']
    pull_number = payload['number']

    # GitHub API URL to fetch pull request files
    api_url = f"https://api.github.com/repos/{repo_name}/pulls/{pull_number}/files"

    # Make the API request
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }

    response = requests.get(api_url, headers=headers)
    if response.status_code != 200:
        print(f"Failed to fetch pull request files: {response.status_code} {response.text}")
        raise Exception(f"Failed to fetch pull request files: {response.status_code} {response.text}")

    files = response.json()
    
    # Initialize dictionary to store added, removed, and modified files
    changed_files = {"added": [], "removed": [], "modified": []}

    # Categorize files based on their status
    for f in files:
        if f['status'] in changed_files:
            changed_files[f['status']].append(f['filename'])

    return changed_files


def upload_to_s3(log_entry):
    # Generate a unique key for the log file (e.g., using a timestamp)
    import time
    key = f"github-webhook/{int(time.time())}.json"
    
    # Upload the log entry as a JSON file to S3
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=key,
        Body=json.dumps(log_entry),
        ContentType='application/json'
    )
    print(f"Log entry uploaded to S3 with key: {key}")
