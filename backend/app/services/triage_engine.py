"""
BIOHERD Clinical Triage & Zoonotic Early Warning Engine
Feature 2:
- Deterministic clinical rule engine to flag suspected disease based on symptoms
- AI / Rule-based hybrid triage
- Zoonotic risk flagging (diseases transmissible to humans: Anthrax, Brucellosis, Rabies, Bovine TB)
- Outbreak threshold alerts
- Automated escalation triggers to next authority level (Field Vet -> DVO -> State Official)
"""

from typing import Any, Dict, List, Optional, Tuple
from app.core.disease_catalog import get_all_diseases, DiseaseDefinition
from app.db.models import SeverityLevelEnum


class ZoonoticAdvisory:
    def __init__(
        self,
        is_zoonotic: bool,
        disease_name: str,
        human_risk_level: str,  # low, medium, high, critical
        transmission_routes: List[str],
        mandatory_ppe: List[str],
        public_health_instructions_en: str,
        public_health_instructions_mr: str,
        public_health_instructions_hi: str,
    ):
        self.is_zoonotic = is_zoonotic
        self.disease_name = disease_name
        self.human_risk_level = human_risk_level
        self.transmission_routes = transmission_routes
        self.mandatory_ppe = mandatory_ppe
        self.public_health_instructions_en = public_health_instructions_en
        self.public_health_instructions_mr = public_health_instructions_mr
        self.public_health_instructions_hi = public_health_instructions_hi

    def to_dict(self) -> Dict[str, Any]:
        return {
            "is_zoonotic": self.is_zoonotic,
            "disease_name": self.disease_name,
            "human_risk_level": self.human_risk_level,
            "transmission_routes": self.transmission_routes,
            "mandatory_ppe": self.mandatory_ppe,
            "public_health_instructions": {
                "en": self.public_health_instructions_en,
                "mr": self.public_health_instructions_mr,
                "hi": self.public_health_instructions_hi,
            },
        }


class TriageRuleEngine:
    # Deterministic Clinical Rule Matrix
    RULES = [
        {
            "disease_id": "dis-anthrax",
            "name": "Anthrax (Splenic Fever)",
            "triggers": [
                ["sudden_death", "dark_non_clotting_blood"],
                ["unclotted_blood", "nose_bleeding"],
                ["sudden_death", "absence_of_rigor_mortis"],
                ["काळपुळी", "काळे रक्त"],
            ],
            "severity": SeverityLevelEnum.CRITICAL,
            "is_zoonotic": True,
            "escalation": "state_emergency",
        },
        {
            "disease_id": "dis-brucellosis",
            "name": "Brucellosis (Bang's Disease)",
            "triggers": [
                ["abortion_last_trimester", "retained_placenta"],
                ["abortion", "retained_fetal_membranes"],
                ["गर्भपात", "वार अडकणे"],
            ],
            "severity": SeverityLevelEnum.HIGH,
            "is_zoonotic": True,
            "escalation": "dvo_alerted",
        },
        {
            "disease_id": "dis-lsd",
            "name": "Lumpy Skin Disease (LSD)",
            "triggers": [
                ["nodular_skin_lesions", "high_fever"],
                ["nodules_all_over_body", "edema_of_limbs"],
                ["लम्पी", "गाठी"],
            ],
            "severity": SeverityLevelEnum.CRITICAL,
            "is_zoonotic": False,
            "escalation": "vet_escalated",
        },
        {
            "disease_id": "dis-fmd",
            "name": "Foot and Mouth Disease (FMD)",
            "triggers": [
                ["frothy_salivation", "mouth_blisters"],
                ["hoof_lesions", "severe_lameness", "salivation"],
                ["लाळ्या", "खुरकूत"],
            ],
            "severity": SeverityLevelEnum.CRITICAL,
            "is_zoonotic": False,
            "escalation": "vet_escalated",
        },
        {
            "disease_id": "dis-bq",
            "name": "Black Quarter (BQ)",
            "triggers": [
                ["crepitant_swelling", "crackling_sound"],
                ["crackling_sound_on_pressing_muscle", "lameness"],
                ["एकटांग्या", "फऱ्या"],
            ],
            "severity": SeverityLevelEnum.CRITICAL,
            "is_zoonotic": False,
            "escalation": "vet_escalated",
        },
    ]

    @classmethod
    def evaluate_clinical_rules(
        cls,
        symptoms_checklist: Dict[str, Any],
        vernacular_text: str = "",
    ) -> List[Dict[str, Any]]:
        """Evaluates deterministic clinical rules against reported symptoms."""
        flattened_tokens = set()
        for _, val in symptoms_checklist.items():
            if isinstance(val, list):
                for s in val:
                    flattened_tokens.add(str(s).lower().strip().replace(" ", "_"))
            elif isinstance(val, str):
                flattened_tokens.add(val.lower().strip().replace(" ", "_"))

        v_lower = vernacular_text.lower()
        matched_rules = []

        for rule in cls.RULES:
            for trigger_group in rule["triggers"]:
                matched = True
                for trigger in trigger_group:
                    t_token = trigger.lower().replace(" ", "_")
                    in_tokens = any(t_token in s for s in flattened_tokens)
                    in_text = trigger.lower() in v_lower
                    if not (in_tokens or in_text):
                        matched = False
                        break
                if matched:
                    matched_rules.append({
                        "disease_id": rule["disease_id"],
                        "disease_name": rule["name"],
                        "severity": rule["severity"],
                        "is_zoonotic": rule["is_zoonotic"],
                        "escalation_level": rule["escalation"],
                        "matched_trigger": trigger_group,
                    })
                    break

        return matched_rules

    @classmethod
    def evaluate_zoonotic_risk(cls, disease_name: str) -> ZoonoticAdvisory:
        """Determines zoonotic transmission risk, PPE protocols, and public health directives."""
        d_lower = disease_name.lower()

        if "anthrax" in d_lower or "काळपुळी" in d_lower:
            return ZoonoticAdvisory(
                is_zoonotic=True,
                disease_name="Anthrax (Splenic Fever)",
                human_risk_level="critical",
                transmission_routes=[
                    "Cutaneous (handling spore-contaminated hides/carcass)",
                    "Inhalation (aerosolized spores)",
                    "Gastrointestinal (consuming infected meat)",
                ],
                mandatory_ppe=[
                    "Heavy nitrile or rubber gloves (elbow length)",
                    "N95 / FFP3 respiratory particulate mask",
                    "Protective bio-hazard coverall suit",
                    "Gum-boots with 10% formalin footbath decontamination",
                ],
                public_health_instructions_en="DO NOT touch or open carcass. High fatal bio-threat to humans. Report to District Epidemiologist and local Primary Health Centre (PHC) immediately.",
                public_health_instructions_mr="मृत जनावराला किंवा रक्ताला उघड्या हाताने अजिबात स्पर्श करू नका. माणसांना अत्यंत घातक. तात्काळ प्राथमिक आरोग्य केंद्र (PHC) आणि तालुका पशुवैद्यांना कळवा.",
                public_health_instructions_hi="मृत पशु या खून को खुले हाथों से न छुएं। यह इंसानों के लिए जानलेवा है। तुरंत प्राथमिक स्वास्थ्य केंद्र और पशु चिकित्सक को सूचित करें।",
            )
        elif "brucellosis" in d_lower or "गर्भपात" in d_lower:
            return ZoonoticAdvisory(
                is_zoonotic=True,
                disease_name="Brucellosis (Undulant Fever)",
                human_risk_level="high",
                transmission_routes=[
                    "Drinking unpasteurized raw milk or dairy products",
                    "Direct contact with aborted fetus, placenta, or vaginal discharge",
                    "Accidental self-inoculation of RBPT/Strain 19 vaccine",
                ],
                mandatory_ppe=[
                    "Waterproof gloves during calving or assisted delivery",
                    "Protective eye goggles / face shield",
                    "Plastic apron over clothes",
                ],
                public_health_instructions_en="Boil all milk vigorously before human consumption. Bury aborted fetus in 6-foot pit with quicklime. Farmers with undulating fever must get human Brucella agglutination test.",
                public_health_instructions_mr="दूध चांगले उकळूनच वापरा. गर्भपात झालेली वार चुन्याच्या खड्ड्यात पुरा. ताप येत असल्यास शेतकऱ्यांनी डॉक्टरांकडून ब्रुसेला तपासणी करून घ्यावी.",
                public_health_instructions_hi="दूध अच्छी तरह उबाल कर ही इस्तेमाल करें। गर्भपात हुए अवशेषों को चूने के गड्ढे में दबाएं। बुखार आने पर डॉक्टर से ब्रुसेला जांच करवाएं।",
            )
        elif "rabies" in d_lower or "अलर्क" in d_lower:
            return ZoonoticAdvisory(
                is_zoonotic=True,
                disease_name="Rabies (Hydrophobia)",
                human_risk_level="critical",
                transmission_routes=[
                    "Bites, scratches, or saliva contact with broken skin or mucous membranes",
                ],
                mandatory_ppe=[
                    "Bite-resistant leather gauntlets",
                    "Full face shield",
                    "Restraining loop / pole",
                ],
                public_health_instructions_en="100% fatal once symptoms appear. Wash bite wounds immediately with running water and soap for 15 minutes. Administer Post-Exposure Prophylaxis (PEP) vaccine + Immunoglobulin immediately.",
                public_health_instructions_mr="लक्षणे दिसल्यानंतर हा रोग १००% जीवघेणा आहे. चावा घेतलेली जागा वाहत्या पाण्याखाली साबणाने १५ मिनिटे धुवा आणि तात्काळ अँटी-रेबीज लस टोचा.",
                public_health_instructions_hi="काटे जाने पर घाव को बहते पानी और साबुन से तुरंत 15 मिनट धोएं और तत्काल एंटी-रेबीज वैक्सीन लगवाएं।",
            )
        elif "bovine tb" in d_lower or "tuberculosis" in d_lower or "क्षयरोग" in d_lower:
            return ZoonoticAdvisory(
                is_zoonotic=True,
                disease_name="Bovine Tuberculosis (Mycobacterium bovis)",
                human_risk_level="high",
                transmission_routes=[
                    "Consuming raw unpasteurized dairy products",
                    "Inhaling infectious droplets in unventilated cattle sheds",
                ],
                mandatory_ppe=["N95 respirator mask", "Protective work gloves"],
                public_health_instructions_en="Strict milk boiling required. Isolate coughing cattle. Screen herd via Single Intradermal Tuberculin test.",
                public_health_instructions_mr="दूध उकळूनच प्यावे. खोकणाऱ्या जनावरांना वेगळे ठेवावे. ट्युबरक्युलिन चाचणीने तपासणी करून घ्यावी.",
                public_health_instructions_hi="दूध हमेशा उबालकर पिएं। खांसने वाले मवेशियों को अलग रखें।",
            )

        return ZoonoticAdvisory(
            is_zoonotic=False,
            disease_name=disease_name,
            human_risk_level="none",
            transmission_routes=[],
            mandatory_ppe=["Standard farm hygiene gloves and boots"],
            public_health_instructions_en="No known transmission to humans. Maintain standard veterinary biosecurity.",
            public_health_instructions_mr="हा रोग मानवामध्ये पसरत नाही. गोठ्याची सामान्य स्वच्छता राखावी.",
            public_health_instructions_hi="यह रोग इंसानों में नहीं फैलता। सामान्य स्वच्छता बनाए रखें।",
        )

    @classmethod
    def compute_escalation(
        cls,
        severity: SeverityLevelEnum,
        is_zoonotic: bool,
        case_cluster_count: int = 1,
    ) -> str:
        """Determines automated escalation trigger hierarchy:
        - none -> paravet_flagged -> vet_escalated -> dvo_alerted -> state_emergency
        """
        if is_zoonotic and severity == SeverityLevelEnum.CRITICAL:
            return "state_emergency"
        if case_cluster_count >= 5 or (is_zoonotic and severity in (SeverityLevelEnum.HIGH, SeverityLevelEnum.CRITICAL)):
            return "dvo_alerted"
        if severity in (SeverityLevelEnum.HIGH, SeverityLevelEnum.CRITICAL) or case_cluster_count >= 3:
            return "vet_escalated"
        if severity == SeverityLevelEnum.MEDIUM:
            return "paravet_flagged"
        return "none"
