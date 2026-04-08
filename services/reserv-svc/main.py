from fastapi import FastAPI
from contextlib import asynccontextmanager
import aiomysql
import redis
import os

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        app.state.db_pool = await aiomysql.create_pool(
            host=os.getenv("DB_WRITER_HOST"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            db="ticketing",
            autocommit=True
        )
        print("✅ DB 연결 성공")
    except Exception as e:
        print("❌ DB 연결 실패 (무시):", e)
        app.state.db_pool = None

    try:
        app.state.redis = redis.Redis(
            host=os.getenv("REDIS_HOST"),
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
def health():
    return {"status": "ok", "service": "reserv-svc"}


@app.get("/")
def root():
    return {"message": "reserv-svc running"}
