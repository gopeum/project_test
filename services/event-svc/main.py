from fastapi import FastAPI
from contextlib import asynccontextmanager
import aiomysql
import redis
import os

@asynccontextmanager
async def lifespan(app: FastAPI):
    # DB 연결 (실패해도 죽지 않음)
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

    # Redis 연결 (실패해도 죽지 않음)
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


# 🔥 헬스체크 (핵심)
@app.get("/health")
def health():
    return {"status": "ok", "service": "event-svc"}


@app.get("/")
def root():
    return {"message": "event-svc running"}
