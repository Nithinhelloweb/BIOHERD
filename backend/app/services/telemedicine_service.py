"""
WebRTC Telemedicine & Low-Bandwidth Signaling Service
Enables peer-to-peer video consultations between rural farmers and licensed district veterinarians.
Includes Coturn STUN/TURN fallback and low-bandwidth audio/snapshot modes for rural 2G/3G connectivity.
"""

from typing import Dict, Any, List, Optional
from datetime import datetime, timezone
import uuid


class TelemedicineService:
    """
    Manages WebRTC tele-consultation rooms and signaling exchange.
    """

    # In-memory signaling room cache (can be backed by Redis in production)
    _rooms: Dict[str, Dict[str, Any]] = {}

    DEFAULT_ICE_SERVERS = [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun1.l.google.com:19302"},
        {"urls": "stun:stun.relay.metered.ca:80"},
    ]

    @classmethod
    def create_session(cls, case_id: str, vet_id: Optional[str] = None) -> Dict[str, Any]:
        session_id = f"telemed-{uuid.uuid4().hex[:12]}"
        room_name = f"bioherd-case-{case_id[:8]}"
        created_at = datetime.now(timezone.utc)

        session_data = {
            "session_id": session_id,
            "case_id": case_id,
            "room_name": room_name,
            "vet_id": vet_id,
            "ice_servers": cls.DEFAULT_ICE_SERVERS,
            "status": "active",
            "created_at": created_at,
            "ended_at": None,
            "signals": [],
            "participants": [],
            "low_bandwidth_mode": True,
        }

        cls._rooms[session_id] = session_data
        return session_data

    @classmethod
    def get_session(cls, session_id: str) -> Optional[Dict[str, Any]]:
        return cls._rooms.get(session_id)

    @classmethod
    def relay_signal(
        cls,
        session_id: str,
        sender_id: str,
        signal_type: str,
        data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Stores and relays SDP Offer/Answer or ICE candidates.
        """
        room = cls._rooms.get(session_id)
        if not room:
            # Create on the fly if needed
            room = cls.create_session(case_id="unknown")
            room["session_id"] = session_id

        signal_packet = {
            "id": uuid.uuid4().hex[:8],
            "sender_id": sender_id,
            "signal_type": signal_type,
            "data": data,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

        room["signals"].append(signal_packet)
        return {
            "status": "relayed",
            "signal_id": signal_packet["id"],
            "session_id": session_id,
        }

    @classmethod
    def get_pending_signals(cls, session_id: str, recipient_id: str) -> List[Dict[str, Any]]:
        room = cls._rooms.get(session_id)
        if not room:
            return []
        # Return signals sent by someone other than recipient
        return [s for s in room["signals"] if s["sender_id"] != recipient_id]

    @classmethod
    def end_session(cls, session_id: str) -> Optional[Dict[str, Any]]:
        room = cls._rooms.get(session_id)
        if not room:
            return None
        room["status"] = "ended"
        room["ended_at"] = datetime.now(timezone.utc)
        return room
