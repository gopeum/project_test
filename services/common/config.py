import os
import boto3

SSM_PREFIX = os.getenv("SSM_PREFIX", "/prod/ticketing")

def get_ssm_parameter(name):
    client = boto3.client("ssm", region_name="ap-northeast-2")

    response = client.get_parameter(
        Name=name,
        WithDecryption=True
    )
    return response["Parameter"]["Value"]


def get_config(key, fallback=None):
    # 환경변수
    value = os.getenv(key)
    if value:
        return value

    # SSM
    try:
        return get_ssm_parameter(f"{SSM_PREFIX}/{key.lower().replace('_', '-')}")
    except Exception:
        return fallback