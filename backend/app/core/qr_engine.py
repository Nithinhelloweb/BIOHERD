import base64
import hashlib
import io
from datetime import datetime, timezone
import qrcode
from qrcode.image.pil import PilImage

def generate_animal_verification_hash(animal_id: str, tag_id: str, registered_at_iso: str) -> str:
    """Computes tamper-evident SHA-256 hash for animal ear tag verification."""
    salt = "BIOHERD_GOVT_MAHARASHTRA_2026"
    raw_payload = f"{salt}:{animal_id}:{tag_id}:{registered_at_iso}"
    return hashlib.sha256(raw_payload.encode("utf-8")).hexdigest()[:16].upper()

def generate_animal_qr_base64(
    animal_id: str,
    tag_id: str,
    species: str,
    breed: str,
    verification_hash: str,
) -> str:
    """
    Generates a high-contrast, scan-friendly QR code styled with BIOHERD Forest Green.
    Returns base64-encoded PNG image string.
    """
    verification_payload = (
        f"https://bioherd.gov.in/verify?tag={tag_id}&id={animal_id}&v={verification_hash}"
    )

    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=8,
        border=3,
    )
    qr.add_data(verification_payload)
    qr.make(fit=True)

    # Use BIOHERD Forest Green for the dark tiles, warm off-white for background
    img: PilImage = qr.make_image(
        fill_color="#134E3F",
        back_color="#FAFBF9",
    )

    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    b64_str = base64.b64encode(buffer.getvalue()).decode("utf-8")
    return f"data:image/png;base64,{b64_str}"
