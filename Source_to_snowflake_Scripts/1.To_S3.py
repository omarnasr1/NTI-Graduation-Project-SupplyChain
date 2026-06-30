import os
import boto3
from dotenv import load_dotenv

load_dotenv()

aws_access_key = os.environ.get("AWS_ACCESS_KEY_ID")
aws_secret_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
region_name = os.environ.get("AWS_REGION")
bucket_name = os.environ.get("AWS_S3_BUCKET_NAME")
local_csv_path = r"D:\NTI\Graduation_project\batch_Supply_chain\Data\DataCoSupplyChainDatasetResult.csv" 
s3_key = os.environ.get("AWS_S3_KEY")

s3 = boto3.client(
    "s3",
    aws_access_key_id=aws_access_key,
    aws_secret_access_key=aws_secret_key,
    region_name=region_name
)

try:
    if region_name == "us-east-1":
        s3.create_bucket(Bucket=bucket_name)
    else:
        s3.create_bucket(
            Bucket=bucket_name,
            CreateBucketConfiguration={"LocationConstraint": region_name}
        )
    print(f"Bucket '{bucket_name}' created.")
except Exception as e:
    print(f"Bucket creation skipped/error (may already exist): {e}")


s3.upload_file(local_csv_path, bucket_name, s3_key)
print(f"Uploaded {local_csv_path} to s3://{bucket_name}/{s3_key}")