import random
import re
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.logging import get_logger
from app.db.models import Animal, AnimalSpecies, District, MortalityReport, SeverityLevelEnum, SymptomReport, User
from app.db.session import get_db
from app.schemas.ivr_sms import (
    InboundSMSRequest,
    InboundSMSResponse,
    IVRCallInitiateRequest,
    IVRInputStepRequest,
    IVRStepResponse,
)
from app.services.triage_engine import TriageRuleEngine

logger = get_logger("ivr_sms_endpoint")
router = APIRouter(prefix="/telecom", tags=["IVR Voice Call & SMS Reporting Gateway"])


@router.post(
    "/ivr/call",
    response_model=IVRStepResponse,
    summary="Simulate incoming toll-free IVR voice call (1800-BIO-HERD)",
)
async def initiate_ivr_call(req: IVRCallInitiateRequest):
    session_id = f"ivr-{uuid.uuid4().hex[:8]}"

    # Welcome voice prompt with trilingual greeting
    greeting_text = (
        "नमस्कार! बायोहर्ड महाराष्ट्र पशुसंवर्धन विभाग टोल-फ्री हेल्पलाईन मध्ये आपले स्वागत आहे. "
        "मराठीसाठी १ दाबा. हिंदी के लिए २ दबाएं. For English press 3."
    )

    return IVRStepResponse(
        call_session_id=session_id,
        step_id="language_select",
        voice_prompt_text=greeting_text,
        allowed_digits=["1", "2", "3"],
        is_terminal=False,
    )


@router.post(
    "/ivr/input",
    response_model=IVRStepResponse,
    summary="Process DTMF keypress for IVR call tree",
)
async def process_ivr_input(
    req: IVRInputStepRequest,
    session: AsyncSession = Depends(get_db),
):
    lang = req.selected_language
    digit = req.digit_pressed.strip()

    # Step 1: Language selection
    if req.step_id == "language_select":
        if digit == "1":
            lang = "mr"
            prompt = "पशु आजारी असल्याचा अहवाल नोंदवण्यासाठी १ दाबा. जनावराचा मृत्यू नोंदवण्यासाठी २ दाबा. लस माहितीसाठी ३ दाबा."
        elif digit == "2":
            lang = "hi"
            prompt = "पशु के बीमार होने की सूचना के लिए १ दबाएं। पशु मृत्यु रिपोर्ट के लिए २ दबाएं। टीकाकरण जानकारी के लिए ३ दबाएं।"
        else:
            lang = "en"
            prompt = "To report a sick animal press 1. To report an animal mortality press 2. For vaccination enquiry press 3."

        return IVRStepResponse(
            call_session_id=req.call_session_id,
            step_id="menu_select",
            voice_prompt_text=prompt,
            allowed_digits=["1", "2", "3"],
            is_terminal=False,
        )

    # Step 2: Main menu choice
    if req.step_id == "menu_select":
        if digit == "1":  # Sick animal
            prompt = {
                "mr": "प्राण्याचा प्रकार निवडा: गायीसाठी १, म्हशीसाठी २, शेळी/मेंढीसाठी ३, इतर प्राण्यांसाठी ४ दाबा.",
                "hi": "पशु का प्रकार चुनें: गाय के लिए १, भैंस के लिए २, बकरी/भेड़ के लिए ३, अन्य के लिए ४ दबाएं।",
                "en": "Select species: For Cow press 1, Buffalo press 2, Goat/Sheep press 3, Others press 4.",
            }.get(lang, "Select species: 1 for Cow, 2 for Buffalo, 3 for Goat, 4 for other.")

            return IVRStepResponse(
                call_session_id=req.call_session_id,
                step_id="species_select_symptom",
                voice_prompt_text=prompt,
                allowed_digits=["1", "2", "3", "4"],
                is_terminal=False,
            )

        elif digit == "2":  # Mortality
            prompt = {
                "mr": "मृत्यू पावलेल्या जनावरांची संख्या कळवा: १ जनावर असल्यास १ दाबा, २ ते ५ असल्यास २ दाबा, ५ पेक्षा जास्त असल्यास ३ दाबा.",
                "hi": "मृत पशुओं की संख्या बताएं: १ पशु के लिए १ दबाएं, २ से ५ के लिए २ दबाएं, ५ से अधिक के लिए ३ दबाएं।",
                "en": "Enter mortality count: Press 1 for single animal, 2 for 2-5 animals, 3 for more than 5 animals.",
            }.get(lang, "Enter mortality count: 1 for one, 2 for 2-5, 3 for >5.")

            return IVRStepResponse(
                call_session_id=req.call_session_id,
                step_id="mortality_count",
                voice_prompt_text=prompt,
                allowed_digits=["1", "2", "3"],
                is_terminal=False,
            )

        else:  # Vaccination enquiry
            prompt = {
                "mr": "तुमच्या गावात सध्या लाळ्या खुरकूत (FMD) व लम्पी प्रतिबंधक लसीकरण मोहीम सुरू आहे. जवळच्या पशुवैद्यकीय दवाखान्याशी संपर्क साधा. धन्यवाद!",
                "hi": "आपके क्षेत्र में FMD एवं लंपी टीकाकरण अभियान चालू है। नजदीकी पशु चिकित्सालय से संपर्क करें। धन्यवाद!",
                "en": "FMD and LSD vaccination campaigns are currently active in your district. Contact your local dispensary. Thank you!",
            }.get(lang, "Vaccination drive active. Thank you!")

            return IVRStepResponse(
                call_session_id=req.call_session_id,
                step_id="complete",
                voice_prompt_text=prompt,
                allowed_digits=[],
                is_terminal=True,
                sms_receipt_sent=True,
            )

    # Step 3: Species selected for symptom report
    if req.step_id == "species_select_symptom":
        species_map = {"1": "cattle", "2": "buffalo", "3": "goat", "4": "sheep"}
        species_code = species_map.get(digit, "cattle")

        prompt = {
            "mr": "लक्षणे निवडा: त्वचेवर गाठी व तापासाठी १ दाबा. तोंडात व पायात फोड (लाळ्या) साठी २ दाबा. कासेला सूज व दुधात रक्तासाठी ३ दाबा.",
            "hi": "लक्षण चुनें: त्वचा पर गांठ और बुखार के लिए १ दबाएं। मुंह और खुर में छालों के लिए २ दबाएं। थन में सूजन के लिए ३ दबाएं।",
            "en": "Select main symptom: Press 1 for Skin nodules and fever, 2 for Mouth and foot blisters, 3 for Swollen udder and milk drop.",
        }.get(lang, "Select symptoms: 1 for nodules, 2 for blisters, 3 for mastitis.")

        return IVRStepResponse(
            call_session_id=req.call_session_id,
            step_id=f"symptom_select_{species_code}",
            voice_prompt_text=prompt,
            allowed_digits=["1", "2", "3"],
            is_terminal=False,
        )

    # Step 4: Symptom finalized -> Save Report in Database!
    if req.step_id.startswith("symptom_select_"):
        species_code = req.step_id.replace("symptom_select_", "")

        # Find or create anonymous/IVR farmer user
        user_res = await session.execute(select(User).where(User.phone == req.caller_phone))
        user = user_res.scalar_one_or_none()
        if not user:
            # Fallback to demo farmer
            user_res = await session.execute(select(User).where(User.role == "farmer"))
            user = user_res.scalars().first()

        # Find an animal of this species or first available
        an_res = await session.execute(select(Animal).limit(1))
        animal = an_res.scalar_one_or_none()

        symptoms = {
            "1": ["nodular_skin_lesions", "high_fever"],
            "2": ["mouth_tongue_blisters", "frothy_salivation", "severe_lameness"],
            "3": ["swollen_hot_painful_udder", "clots_flakes_watery_milk"],
        }.get(digit, ["general_weakness", "fever"])

        report_id = str(uuid.uuid4())
        if animal and user:
            report = SymptomReport(
                id=report_id,
                animal_id=animal.id,
                reported_by=user.id,
                symptoms_json={"vitality": symptoms},
                severity=SeverityLevelEnum.HIGH if digit in ("1", "2") else SeverityLevelEnum.MEDIUM,
                status="submitted",
                reporting_channel="ivr",
            )
            session.add(report)
            await session.commit()

        prompt = {
            "mr": "तुमचा आजार अहवाल यशस्वीरीत्या नोंदवला गेला आहे. तिकीट क्रमांक तुमच्या मोबाईलवर SMS द्वारे पाठवला आहे. पशुवैद्य लवकरच संपर्क करतील. धन्यवाद!",
            "hi": "आपकी रिपोर्ट दर्ज कर ली गई है। टिकट नंबर SMS द्वारा भेजा गया है। पशु चिकित्सक जल्द संपर्क करेंगे। धन्यवाद!",
            "en": "Your symptom report has been registered. Reference ticket sent via SMS. A veterinarian will contact you shortly. Thank you!",
        }.get(lang, "Report registered. Thank you!")

        return IVRStepResponse(
            call_session_id=req.call_session_id,
            step_id="complete",
            voice_prompt_text=prompt,
            allowed_digits=[],
            is_terminal=True,
            report_created_id=report_id,
            sms_receipt_sent=True,
        )

    # Step 5: Mortality count finalized -> Save Mortality Report in Database!
    if req.step_id == "mortality_count":
        count = 1 if digit == "1" else (3 if digit == "2" else 8)

        # Get default district
        dist_res = await session.execute(select(District).limit(1))
        dist = dist_res.scalar_one_or_none()
        user_res = await session.execute(select(User).limit(1))
        user = user_res.scalar_one_or_none()

        report_id = str(uuid.uuid4())
        if dist and user:
            mortality = MortalityReport(
                id=report_id,
                reported_by=user.id,
                district_id=dist.id,
                species=AnimalSpecies.CATTLE,
                animal_count=count,
                probable_cause="Reported via IVR Voice Helpline",
                symptoms=["sudden_death"],
                status="submitted",
            )
            session.add(mortality)
            await session.commit()

        prompt = {
            "mr": f"{count} जनावरांचा मृत्यू अहवाल नोंदवला आहे. जिल्हा पशुवैद्यकीय पथकाला त्वरित अलर्ट पाठवला आहे. मृतदेहाला उघड्या हाताने स्पर्श करू नका. धन्यवाद!",
            "hi": f"{count} पशुओं की मृत्यु रिपोर्ट दर्ज कर ली गई है। पशु चिकित्सा दल को अलर्ट भेजा गया है। धन्यवाद!",
            "en": f"Mortality report for {count} animals registered. Emergency veterinary team alerted. Thank you!",
        }.get(lang, "Mortality registered. Alert sent.")

        return IVRStepResponse(
            call_session_id=req.call_session_id,
            step_id="complete",
            voice_prompt_text=prompt,
            allowed_digits=[],
            is_terminal=True,
            report_created_id=report_id,
            sms_receipt_sent=True,
        )

    return IVRStepResponse(
        call_session_id=req.call_session_id,
        step_id="complete",
        voice_prompt_text="धन्यवाद! / Thank you!",
        allowed_digits=[],
        is_terminal=True,
    )


# ── Inbound SMS Fallback Parser ─────────────────────────────────────────────

@router.post(
    "/sms/inbound",
    response_model=InboundSMSResponse,
    summary="Process inbound SMS fallback report (e.g. REPORT MH12AB1234 FEVER,BLISTERS)",
)
async def receive_inbound_sms(
    req: InboundSMSRequest,
    session: AsyncSession = Depends(get_db),
):
    text = req.message_text.strip().upper()
    ticket_id = f"SMS-{random.randint(10000, 99999)}"

    # Check for DEATH report format: e.g. "DEATH CATTLE 2"
    if text.startswith("DEATH"):
        parts = text.split()
        count = 1
        species = AnimalSpecies.CATTLE
        if len(parts) >= 3 and parts[2].isdigit():
            count = int(parts[2])
        if len(parts) >= 2:
            sp_raw = parts[1].lower()
            if "buf" in sp_raw:
                species = AnimalSpecies.BUFFALO
            elif "goat" in sp_raw or "sheep" in sp_raw:
                species = AnimalSpecies.GOAT

        dist_res = await session.execute(select(District).limit(1))
        dist = dist_res.scalar_one_or_none()
        user_res = await session.execute(select(User).limit(1))
        user = user_res.scalar_one_or_none()

        if dist and user:
            m_report = MortalityReport(
                reported_by=user.id,
                district_id=dist.id,
                species=species,
                animal_count=count,
                probable_cause=f"Inbound SMS: {req.message_text}",
                status="submitted",
            )
            session.add(m_report)
            await session.commit()

        reply = f"BIOHERD: Mortality report logged ({ticket_id}). {count} {species.value}. Field Vet alerted. Deep burial mandatory. Helpline: 1800-BIO-HERD."
        return InboundSMSResponse(status="success", ticket_id=ticket_id, reply_message=reply)

    # Check for REPORT format: e.g. "REPORT MH-PUN-001 FEVER,BLISTERS"
    if text.startswith("REPORT"):
        tag_match = re.search(r"REPORT\s+([A-Z0-9\-]+)\s+(.+)", text)
        tag_id = tag_match.group(1) if tag_match else "UNKNOWN"
        symptoms_str = tag_match.group(2) if tag_match else "General illness"

        # Lookup animal by tag_id
        an_res = await session.execute(select(Animal).where(Animal.tag_id.ilike(f"%{tag_id}%")))
        animal = an_res.scalar_one_or_none()

        user_res = await session.execute(select(User).limit(1))
        user = user_res.scalar_one_or_none()

        if animal and user:
            s_report = SymptomReport(
                animal_id=animal.id,
                reported_by=user.id,
                symptoms_json={"sms_reported": [s.strip() for s in symptoms_str.split(",")]},
                severity=SeverityLevelEnum.HIGH,
                status="submitted",
                reporting_channel="sms",
            )
            session.add(s_report)
            await session.commit()

        reply = f"BIOHERD: Incident logged ({ticket_id}) for Tag {tag_id}. Symptoms: {symptoms_str}. Nearest Block Vet notified. Isolate animal."
        return InboundSMSResponse(status="success", ticket_id=ticket_id, reply_message=reply)

    # USSD / Help query
    reply = "BIOHERD USSD/SMS Format: 'REPORT <TAG_ID> <SYMPTOMS>' or 'DEATH <SPECIES> <COUNT>'. Call toll-free 1800-BIO-HERD."
    return InboundSMSResponse(status="info", ticket_id=ticket_id, reply_message=reply)
