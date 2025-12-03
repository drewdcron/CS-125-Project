import redis
from app.core.config import settings

try:
    redis_client = redis.Redis(
        host=settings.REDIS_HOST, port=settings.REDIS_PORT,
        username=settings.REDIS_USER, password=settings.REDIS_PASSWORD,
        decode_responses=True, socket_timeout=2
    )

    redis_client.ping()
    print("SUCCESS: Connected to Redis!")

except:
    redis_client = None