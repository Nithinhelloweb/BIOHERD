import io
import socket
from datetime import timedelta
from typing import Optional, Tuple
from PIL import Image, ImageOps
from minio import Minio
from minio.error import S3Error
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger("minio_service")

def is_endpoint_reachable(endpoint: str, timeout: float = 0.15) -> bool:
    """Quick non-blocking socket check if endpoint port is open."""
    try:
        parts = endpoint.split(":")
        host = parts[0]
        port = int(parts[1]) if len(parts) > 1 else 80
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except (socket.timeout, ConnectionRefusedError, OSError, ValueError):
        return False

class MinioService:
    """MinIO Object Store client for photos, voice notes, and documents with EXIF stripping."""

    def __init__(self) -> None:
        self.endpoint = settings.MINIO_ENDPOINT
        self.access_key = settings.MINIO_ACCESS_KEY
        self.secret_key = settings.MINIO_SECRET_KEY
        self.secure = settings.MINIO_SECURE
        self.bucket_name = settings.MINIO_BUCKET_NAME

        self._client: Optional[Minio] = None
        self._in_memory_files: dict[str, tuple[bytes, str]] = {} # path -> (bytes, content_type)
        self._is_connected: bool = False

    def get_client(self) -> Minio:
        if self._client is None:
            self._client = Minio(
                endpoint=self.endpoint,
                access_key=self.access_key,
                secret_key=self.secret_key,
                secure=self.secure,
            )
        return self._client

    def ping(self) -> bool:
        """Verify MinIO service reachability and ensure bucket exists."""
        if not is_endpoint_reachable(self.endpoint):
            self._is_connected = False
            return False

        try:
            client = self.get_client()
            if not client.bucket_exists(self.bucket_name):
                client.make_bucket(self.bucket_name)
                logger.info("minio_bucket_created", bucket=self.bucket_name)
            self._is_connected = True
            return True
        except Exception as e:
            logger.warning("minio_ping_failed_using_memory_fallback", error=str(e))
            self._is_connected = False
            return False

    def strip_exif(self, image_bytes: bytes) -> bytes:
        """Strip sensitive EXIF metadata (GPS, phone details) while preserving visual data."""
        try:
            with Image.open(io.BytesIO(image_bytes)) as img:
                # Transpose image to honor orientation before stripping EXIF
                img = ImageOps.exif_transpose(img)
                # Create clean copy without EXIF tags
                clean_img = Image.new(img.mode, img.size)
                clean_img.paste(img)
                
                output = io.BytesIO()
                # Save as JPEG or PNG preserving original format
                fmt = img.format if img.format in ["JPEG", "PNG", "WEBP"] else "JPEG"
                clean_img.save(output, format=fmt, quality=90)
                return output.getvalue()
        except Exception as e:
            logger.warning("exif_stripping_fallback", error=str(e))
            return image_bytes

    def upload_bytes(
        self,
        object_name: str,
        data: bytes,
        content_type: str = "application/octet-stream",
        strip_image_exif: bool = True,
    ) -> str:
        """Upload byte buffer to MinIO bucket with automatic EXIF sanitization."""
        if strip_image_exif and content_type.startswith("image/"):
            data = self.strip_exif(data)

        if self.ping():
            try:
                client = self.get_client()
                client.put_object(
                    bucket_name=self.bucket_name,
                    object_name=object_name,
                    data=io.BytesIO(data),
                    length=len(data),
                    content_type=content_type,
                )
                logger.info("minio_upload_success", object_name=object_name, size=len(data))
                return f"{self.endpoint}/{self.bucket_name}/{object_name}"
            except Exception as e:
                logger.error("minio_upload_error", object_name=object_name, error=str(e))

        # Memory store fallback for test/dev
        self._in_memory_files[object_name] = (data, content_type)
        return f"memory://{self.bucket_name}/{object_name}"

    def get_presigned_url(self, object_name: str, expires_minutes: int = 60) -> str:
        """Generate presigned GET URL for secure asset retrieval."""
        if self.ping():
            try:
                client = self.get_client()
                return client.get_presigned_url(
                    method="GET",
                    bucket_name=self.bucket_name,
                    object_name=object_name,
                    expires=timedelta(minutes=expires_minutes),
                )
            except Exception as e:
                logger.error("minio_presigned_url_error", object_name=object_name, error=str(e))

        return f"/api/v1/assets/{object_name}"

    def get_object_bytes(self, object_name: str) -> Optional[Tuple[bytes, str]]:
        """Retrieve stored object data and content type."""
        if self.ping():
            try:
                client = self.get_client()
                response = client.get_object(self.bucket_name, object_name)
                data = response.read()
                content_type = response.headers.get("content-type", "application/octet-stream")
                response.close()
                response.release_conn()
                return data, content_type
            except Exception as e:
                logger.error("minio_get_object_error", object_name=object_name, error=str(e))

        return self._in_memory_files.get(object_name)

minio_service = MinioService()
