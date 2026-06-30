import boto3

'''
s3 = boto3.client(
    "s3",
    aws_access_key_id="?",
    aws_secret_access_key="?/1rcB",
    region_name="us-east-1"
)
'''

def upload_to_s3(local_file, bucket_name, s3_key):

    s3.upload_file(
        local_file,
        bucket_name,
        s3_key
    )

    print(f"✅ Uploaded {s3_key} to S3")