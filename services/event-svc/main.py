from fastapi import FastAPI
from contextlib import asynccontextmanager
import aiomysql
import redis
import os
import boto3

# SSM 설정
SSM_PREFIX = os.getenv("SSM_PREFIX", "/prod/ticketing")

def get_ssm_parameter(name):
    client = boto3.client("ssm", region_name="ap-northeast-2")
    response = client.get_parameter(Name=name, WithDecryption=True)
    return response["Parameter"]["Value"]

def get_config(key):
    value = os.getenv(key)
    if value:
        return value

    try:
        ssm_key = f"{SSM_PREFIX}/{key.lower().replace('_', '-')}"
        return get_ssm_parameter(ssm_key)
    except Exception as e:
        print(f"SSM fallback 실패: {e}")
        return None


@asynccontextmanager
async def lifespan(app: FastAPI):
    # DB 연결
    try:
        app.state.db_pool = await aiomysql.create_pool(
            host=get_config("DB_WRITER_HOST"),
            user=os.getenv("DB_USER"),
            password=get_config("DB_PASSWORD"),
            db="ticketing",
            autocommit=True
        )
        print("✅ DB 연결 성공")
    except Exception as e:
        print("❌ DB 연결 실패 (무시):", e)
        app.state.db_pool = None

    # Redis 연결
    try:
        app.state.redis = redis.Redis(
            host=get_config("REDIS_HOST"),
            port=6379,
            decode_responses=True
        )
        app.state.redis.ping()
        print("✅ Redis 연결 성공")
    except Exception as e:
        print("❌ Redis 연결 실패 (무시):", e)
        app.state.redis = None

    yield


app = FastAPI(lifespan=lifespan)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "event-svc"}


@app.get("/")
def root():
    return {"message": "event-svc running"}