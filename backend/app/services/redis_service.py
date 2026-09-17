import json
import socket
import time
from typing import Any, Dict, Optional, Tuple
import redis.asyncio as aioredis
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger("redis_service")

def is_port_reachable(host: str, port: int, timeout: float = 0.15) -> bool:
    """Quick non-blocking check if service port is open."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except (socket.timeout, ConnectionRefusedError, OSError):
        return False

class RedisService:
    """Production Redis 7 service with async connection pool and resilient fallback."""

    def __init__(self) -> None:
        self.redis_url = settings.REDIS_URL
        self._client: Optional[aioredis.Redis] = None
        self._in_memory_store: Dict[str, Tuple[str, Optional[float]]] = {} # key -> (val, expire_time)
        self._in_memory_rate_limits: Dict[str, list[float]] = {}
        self._is_connected: bool = False

    async def get_client(self) -> aioredis.Redis:
        if self._client is None:
            self._client = aioredis.from_url(
                self.redis_url,
                encoding="utf-8",
                decode_responses=True,
                socket_timeout=1.0,
                socket_connect_timeout=1.0,
                retry_on_timeout=False,
            )
        return self._client

    async def ping(self) -> bool:
        """Check Redis connectivity."""
        if not is_port_reachable(settings.REDIS_HOST, settings.REDIS_PORT):
            self._is_connected = False
            return False

        try:
            client = await self.get_client()
            res = await client.ping()
            self._is_connected = bool(res)
            return self._is_connected
        except Exception as e:
            logger.warning("redis_ping_failed_using_memory_fallback", error=str(e))
            self._is_connected = False
            return False

    async def get(self, key: str) -> Optional[str]:
        """Fetch string value by key."""
        if await self.ping():
            try:
                client = await self.get_client()
                return await client.get(key)
            except Exception as e:
                logger.warning("redis_get_error", key=key, error=str(e))
        
        # Fallback to local memory
        item = self._in_memory_store.get(key)
        if item:
            val, exp = item
            if exp is None or exp > time.time():
                return val
            del self._in_memory_store[key]
        return None

    async def set(self, key: str, value: str, ttl_seconds: Optional[int] = None) -> bool:
        """Set key-value pair with optional TTL."""
        if await self.ping():
            try:
                client = await self.get_client()
                if ttl_seconds:
                    await client.setex(key, ttl_seconds, value)
                else:
                    await client.set(key, value)
                return True
            except Exception as e:
                logger.warning("redis_set_error", key=key, error=str(e))

        # Memory store fallback
        expire_time = time.time() + ttl_seconds if ttl_seconds else None
        self._in_memory_store[key] = (value, expire_time)
        return True

    async def get_json(self, key: str) -> Optional[Any]:
        """Retrieve and deserialize JSON data."""
        val = await self.get(key)
        if val:
            try:
                return json.loads(val)
            except Exception:
                return None
        return None

    async def set_json(self, key: str, data: Any, ttl_seconds: Optional[int] = None) -> bool:
        """Serialize data to JSON and store in Redis."""
        try:
            serialized = json.dumps(data, default=str)
            return await self.set(key, serialized, ttl_seconds)
        except Exception as e:
            logger.error("redis_set_json_error", key=key, error=str(e))
            return False

    async def delete(self, key: str) -> bool:
        """Delete key from store."""
        if await self.ping():
            try:
                client = await self.get_client()
                await client.delete(key)
            except Exception as e:
                logger.warning("redis_delete_error", key=key, error=str(e))

        if key in self._in_memory_store:
            del self._in_memory_store[key]
        return True

    async def exists(self, key: str) -> bool:
        """Check if key exists."""
        val = await self.get(key)
        return val is not None

    async def check_rate_limit(
        self,
        identifier: str,
        max_requests: int = 60,
        window_seconds: int = 60,
    ) -> Tuple[bool, int, int]:
        """Sliding window rate limiter. Returns (allowed, current_count, retry_after_sec)."""
        key = f"rate_limit:{identifier}"
        now = time.time()

        if await self.ping():
            try:
                client = await self.get_client()
                pipe = client.pipeline()
                pipe.zremrangebyscore(key, 0, now - window_seconds)
                pipe.zadd(key, {str(now): now})
                pipe.zcard(key)
                pipe.expire(key, window_seconds)
                results = await pipe.execute()
                count = results[2]
                allowed = count <= max_requests
                retry_after = window_seconds if not allowed else 0
                return allowed, count, retry_after
            except Exception as e:
                logger.warning("redis_rate_limit_error_using_fallback", error=str(e))

        # Resilient local in-memory sliding window
        window_start = now - window_seconds
        timestamps = self._in_memory_rate_limits.setdefault(key, [])
        timestamps = [t for t in timestamps if t > window_start]
        timestamps.append(now)
        self._in_memory_rate_limits[key] = timestamps

        count = len(timestamps)
        allowed = count <= max_requests
        retry_after = window_seconds if not allowed else 0
        return allowed, count, retry_after

    async def store_refresh_token(
        self,
        jti: str,
        user_id: str,
        device_fingerprint: str,
        ttl_seconds: int = 86400 * 7,
    ) -> bool:
        """Store active refresh token record bound to user and device."""
        key = f"refresh_token:{jti}"
        payload = {
            "user_id": user_id,
            "device": device_fingerprint,
            "created_at": time.time(),
        }
        return await self.set_json(key, payload, ttl_seconds=ttl_seconds)

    async def is_refresh_token_valid(self, jti: str) -> bool:
        """Verify refresh token exists in store and has not been revoked."""
        if await self.is_token_revoked(jti):
            return False
        return await self.exists(f"refresh_token:{jti}")

    async def revoke_token(self, jti: str, ttl_seconds: int = 86400 * 7) -> bool:
        """Revoke a token by adding its JTI to the revocation blacklist."""
        revoke_key = f"revoked_token:{jti}"
        await self.set(revoke_key, "revoked", ttl_seconds=ttl_seconds)
        await self.delete(f"refresh_token:{jti}")
        return True

    async def is_token_revoked(self, jti: str) -> bool:
        """Check if token JTI is in revocation blacklist."""
        return await self.exists(f"revoked_token:{jti}")

    async def close(self) -> None:
        """Close connection pool."""
        if self._client:
            await self._client.aclose()
            self._client = None
            self._is_connected = False

redis_service = RedisService()

