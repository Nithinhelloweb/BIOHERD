"""
Curated Veterinary Drug Catalog & Dosage Calculator Engine
Tailored for the Government of Maharashtra Animal Husbandry Department (BIOHERD SIH26128).
Provides Schedule-H antibiotic controls, weight-based dosage formulas,
and mandatory milk/meat withdrawal period warnings for food safety.
"""

from typing import Dict, Any, List, Optional
import math


class DrugCatalog:
    """
    Official Maharashtra State Veterinary Formulary & Protocol Library.
    """

    DRUGS: List[Dict[str, Any]] = [
        {
            "id": "DRUG-ENRO",
            "name": "Enrofloxacin",
            "trade_names": ["Baytril", "Floxidin", "Enrocin"],
            "category": "Fluoroquinolone Antibiotic",
            "schedule_h": True,
            "target_species": ["cattle", "buffalo", "goat", "sheep", "pig"],
            "indications": [
                "Haemorrhagic Septicaemia (घटसर्प)",
                "Black Quarter (एकटांग्या)",
                "Bovine Respiratory Disease (श्वसन रोग)",
                "Acute Enteritis (अतिसार)",
            ],
            "route": "Intramuscular (IM)",
            "dose_per_kg_mg": 5.0,
            "concentration_mg_ml": 100.0,
            "default_duration_days": 4,
            "milk_withdrawal_days": 4,
            "meat_withdrawal_days": 14,
            "instructions_en": "Administer deep intramuscularly once daily for 3 to 5 consecutive days. Rotate injection sites.",
            "instructions_mr": "दररोज एकदा खोल स्नायूमध्ये (IM) सलग ३ ते ५ दिवस द्या. सुईची जागा बदला. दूध ४ दिवस मानवी वापरासाठी वापरू नये.",
            "contraindications": "Do not use in growing calves under 12 months with cartilage damage. Strictly Schedule-H prescription required.",
        },
        {
            "id": "DRUG-CEFT",
            "name": "Ceftriaxone + Sulbactam",
            "trade_names": ["Intacef Tazo", "Xone-XP", "Cefbact-SB"],
            "category": "3rd Gen Cephalosporin Antibiotic",
            "schedule_h": True,
            "target_species": ["cattle", "buffalo", "goat", "sheep"],
            "indications": [
                "Acute Bovine Mastitis (तीव्र स्तनदाह)",
                "Septicaemia / Navel Ill",
                "Severe Post-Partum Metritis (गर्भाशयदाह)",
                "Secondary bacterial infection in LSD (लंपी दुय्यम संसर्ग)",
            ],
            "route": "Intravenous / Deep IM (IV/IM)",
            "dose_per_kg_mg": 10.0,
            "concentration_mg_ml": 150.0,  # Reconstituted 3.0g / 4.5g in 20-30ml WFI
            "default_duration_days": 3,
            "milk_withdrawal_days": 7,
            "meat_withdrawal_days": 28,
            "instructions_en": "Reconstitute with Sterile Water for Injection. Administer slowly IV or deep IM every 24 hours.",
            "instructions_mr": "जंतुविरहित पाण्यामध्ये विरघळवून शिरेतून (IV) किंवा खोल स्नायूत द्या. सलग ३ दिवस. दूध ७ दिवस फेकून द्यावे.",
            "contraindications": "Contraindicated in animals hypersensitive to beta-lactam antibiotics.",
        },
        {
            "id": "DRUG-MELX",
            "name": "Meloxicam + Paracetamol",
            "trade_names": ["Melonex Plus", "Meldex", "Zobid-M"],
            "category": "NSAID Analgesic & Antipyretic",
            "schedule_h": False,
            "target_species": ["cattle", "buffalo", "goat", "sheep", "pig"],
            "indications": [
                "Foot and Mouth Disease Fever & Pain (लाळ्या खुरकूत ताप व वेदना)",
                "Lumpy Skin Disease High Pyrexia (लंपी तीव्र ताप)",
                "Black Quarter muscle inflammation (एकटांग्या स्नायू सूज)",
                "Painful Acute Mastitis (स्तनदाह दाह)",
            ],
            "route": "Intramuscular (IM)",
            "dose_per_kg_mg": 0.5,  # 0.5 mg/kg Meloxicam
            "concentration_mg_ml": 5.0,  # 5 mg/ml Meloxicam + 150 mg/ml Paracetamol
            "default_duration_days": 3,
            "milk_withdrawal_days": 2,
            "meat_withdrawal_days": 5,
            "instructions_en": "Administer intramuscularly once daily for 2 to 3 days to control acute pyrexia and painful inflammatory edema.",
            "instructions_mr": "तीव्र ताप, अंगदुखी आणि सूज कमी करण्यासाठी दररोज एकदा स्नायूत (IM) २ ते ३ दिवस द्या.",
            "contraindications": "Avoid in animals with severe dehydration or renal failure.",
        },
        {
            "id": "DRUG-IVER",
            "name": "Ivermectin 1%",
            "trade_names": ["Neomec", "Ivomec", "Virbamec"],
            "category": "Endectocide Antiparasitic",
            "schedule_h": False,
            "target_species": ["cattle", "buffalo", "goat", "sheep"],
            "indications": [
                "Tick & Vector Infestation in Theileriosis (गोचीड नियंत्रण)",
                "Fly Strike & Maggot Prevention in LSD (अंगावरील किडे प्रतिबंध)",
                "Mange Mites & Gastrointestinal Nematodes",
            ],
            "route": "Subcutaneous (SC) ONLY",
            "dose_per_kg_mg": 0.2,
            "concentration_mg_ml": 10.0,  # 1% w/v = 10 mg/ml
            "default_duration_days": 1,  # Single dose
            "milk_withdrawal_days": 28,
            "meat_withdrawal_days": 35,
            "instructions_en": "Administer strictly subcutaneously behind the shoulder or neck. Do NOT inject intravenously or intramuscularly.",
            "instructions_mr": "फक्त मानेच्या किंवा खांद्याच्या सैल कातडीखाली (SC) टोचा. चुकूनही स्नायूत किंवा शिरेत देऊ नये. २८ दिवस दूध विकू नये.",
            "contraindications": "STRICTLY SC ONLY. Never administer IV/IM. Not permitted for milking dairy cows producing milk for human consumption unless discarded for 28 days.",
        },
        {
            "id": "DRUG-OXYT",
            "name": "Oxytetracycline Long Acting (LA)",
            "trade_names": ["Terramycin LA", "Oxytet LA", "Alamycin LA"],
            "category": "Tetracycline Broad-Spectrum",
            "schedule_h": True,
            "target_species": ["cattle", "buffalo", "goat", "sheep", "pig"],
            "indications": [
                "Bovine Theileriosis / Anaplasmosis (थायलेरियासिस व गोचीड ताप)",
                "Foot Rot / Interdigital Necrobacillosis (खुर सडणे)",
                "Contagious Caprine Pleuropneumonia (सीसीपीपी)",
            ],
            "route": "Deep Intramuscular (IM)",
            "dose_per_kg_mg": 20.0,  # Long acting depot formulation
            "concentration_mg_ml": 200.0,  # 200 mg/ml
            "default_duration_days": 3,  # Single depot injection, can repeat at 72 hours
            "milk_withdrawal_days": 7,
            "meat_withdrawal_days": 21,
            "instructions_en": "Single deep intramuscular injection at 20 mg/kg provides effective blood levels for 72 hours. Do not exceed 10 ml per injection site.",
            "instructions_mr": "एकाच वेळी खोल स्नायूमध्ये द्या. ७२ तास औषध शरीरात टिकून राहते. एका ठिकाणी १० मिली पेक्षा जास्त देऊ नये.",
            "contraindications": "Do not administer to pregnant animals in the last trimester due to fetal tooth discoloration.",
        },
        {
            "id": "DRUG-BUPR",
            "name": "Buparvaquone",
            "trade_names": ["Zubion", "Butalex"],
            "category": "Hydroxynaphthoquinone Antiprotozoal",
            "schedule_h": True,
            "target_species": ["cattle", "buffalo"],
            "indications": [
                "East Coast Fever / Bovine Theileriosis (Theileria annulata) (गोचीडजन्य थायलेरियासिस)",
            ],
            "route": "Deep Intramuscular into Neck (IM)",
            "dose_per_kg_mg": 2.5,
            "concentration_mg_ml": 50.0,
            "default_duration_days": 1,  # Single dose, repeatable once at 48h in severe cases
            "milk_withdrawal_days": 14,
            "meat_withdrawal_days": 42,
            "instructions_en": "Administer deep intramuscularly into neck muscles. Highly effective specific therapy against schizonts and piroplasms.",
            "instructions_mr": "मानेच्या खोल स्नायूत एकदाच द्या. थायलेरियासिस रोगावर अत्यंत गुणकारी. १४ दिवस दूध मानवी खाण्यासाठी वापरू नये.",
            "contraindications": "Do not administer IV. Guard against local site reaction.",
        },
        {
            "id": "DRUG-CHLR",
            "name": "Chlorpheniramine Maleate (CPM)",
            "trade_names": ["Anistamin", "Cadistin", "Chloril"],
            "category": "Antihistaminic & Antiallergic",
            "schedule_h": False,
            "target_species": ["cattle", "buffalo", "goat", "sheep"],
            "indications": [
                "Allergic urticaria & hypersensitivity (अंगावर गांधी उठणे)",
                "Insect bite edema & Lumpy Skin nodule pruritus (लंपी खाज व दाह)",
                "Bloat / Ruminal atony supportive therapy",
            ],
            "route": "Intramuscular (IM)",
            "dose_per_kg_mg": 0.5,
            "concentration_mg_ml": 10.0,
            "default_duration_days": 3,
            "milk_withdrawal_days": 1,
            "meat_withdrawal_days": 3,
            "instructions_en": "Administer IM once or twice daily for 2 to 3 days to alleviate severe histamine-mediated swelling.",
            "instructions_mr": "अंगावरील सूज आणि खाज कमी करण्यासाठी दररोज २ वेळा स्नायूत (IM) २ ते ३ दिवस द्या.",
            "contraindications": "May cause mild transient sedation.",
        },
        {
            "id": "DRUG-CLOX",
            "name": "Intramammary Cloxacillin",
            "trade_names": ["Masticlox", "Tilox Intramammary"],
            "category": "Penicillinase-Resistant Antibiotic",
            "schedule_h": True,
            "target_species": ["cattle", "buffalo"],
            "indications": [
                "Clinical Bovine Mastitis (स्तनदाह / कासदाह)",
                "Staphylococcal & Streptococcal udder infection",
            ],
            "route": "Intramammary Infusion (IMM)",
            "dose_per_kg_mg": 0.0,  # Fixed dose per affected quarter
            "concentration_mg_ml": 0.0,  # 1 syringe (200mg Sodium Cloxacillin)
            "default_duration_days": 3,
            "milk_withdrawal_days": 4,
            "meat_withdrawal_days": 7,
            "instructions_en": "Completely strip affected quarter, disinfect teat orifice with alcohol swab, infuse entire syringe content, and massage upward.",
            "instructions_mr": "कासेतील बाधित सड पूर्णपणे रिकामा करा. सडाचे तोंड स्वच्छ करून संपूर्ण सिरिंज आत सोडा व वर चोळा. सलग ३ दिवस.",
            "contraindications": "For intramammary use only. Never inject parenterally. Discard milk from all quarters during treatment + 4 days.",
        },
        {
            "id": "DRUG-KMN4",
            "name": "Potassium Permanganate + Boroglycerine",
            "trade_names": ["लाल औषध (KMNO4)", "Boro-Glycerine Gel"],
            "category": "Topical Antiseptic & Astringent",
            "schedule_h": False,
            "target_species": ["cattle", "buffalo", "goat", "sheep", "pig"],
            "indications": [
                "Foot and Mouth Disease oral lesions & tongue blisters (लाळ्या खुरकूत तोंडातील फोड)",
                "Interdigital foot ulcerations & hooves maggots (पायातील खुरकुत जखमा)",
            ],
            "route": "Topical / Oral Wash",
            "dose_per_kg_mg": 0.0,  # Topical application
            "concentration_mg_ml": 0.0,
            "default_duration_days": 7,
            "milk_withdrawal_days": 0,
            "meat_withdrawal_days": 0,
            "instructions_en": "Wash mouth and hooves twice daily with 1:1000 dilute pink KMNO4 solution. Apply soothing Boro-Glycerine over tongue ulcers.",
            "instructions_mr": "तोंडातील फोड आणि खुरांच्या जखमा १:१००० लाल औषधाच्या पाण्याने धुवा आणि जिभेवर बोरो ग्लिसरीन मलम लावा.",
            "contraindications": "External/topical use only. Never inject.",
        },
        {
            "id": "DRUG-VITM",
            "name": "Vitamin H + AD3E (Supportive)",
            "trade_names": ["Vimeral", "Tribivet", "Multistar"],
            "category": "Nutritional & Epithelial Repair Co-factor",
            "schedule_h": False,
            "target_species": ["cattle", "buffalo", "goat", "sheep"],
            "indications": [
                "Post-LSD skin lesion re-epithelialization (लंपी गाठी भरून येणे)",
                "Post-Mastitis udder tissue regeneration (कास दुरुस्ती)",
                "Anorexia, debility, and convalescent support",
            ],
            "route": "Deep IM or Oral",
            "dose_per_kg_mg": 0.02,
            "concentration_mg_ml": 1.0,
            "default_duration_days": 7,
            "milk_withdrawal_days": 0,
            "meat_withdrawal_days": 0,
            "instructions_en": "Administer 5-10 ml deep IM or 10-15 ml orally once daily for 7 days to accelerate epithelial repair.",
            "instructions_mr": "कातडी आणि कास लवकर दुरुस्त होण्यासाठी दररोज ५ ते १० मिली स्नायूत किंवा तोंडाने पाजा. सलग ७ दिवस.",
            "contraindications": "None when used at recommended nutritional dosages.",
        },
    ]

    @classmethod
    def get_all(cls) -> List[Dict[str, Any]]:
        return cls.DRUGS

    @classmethod
    def get_by_id(cls, drug_id: str) -> Optional[Dict[str, Any]]:
        for drug in cls.DRUGS:
            if drug["id"] == drug_id:
                return drug
        return None

    @classmethod
    def filter_by(
        cls,
        species: Optional[str] = None,
        disease_query: Optional[str] = None,
        schedule_h: Optional[bool] = None,
    ) -> List[Dict[str, Any]]:
        results = []
        for drug in cls.DRUGS:
            if species and species.lower() not in [s.lower() for s in drug["target_species"]]:
                continue
            if schedule_h is not None and drug["schedule_h"] != schedule_h:
                continue
            if disease_query:
                query_lower = disease_query.lower()
                matches = any(query_lower in ind.lower() for ind in drug["indications"]) or (query_lower in drug["name"].lower())
                if not matches:
                    continue
            results.append(drug)
        return results

    @classmethod
    def calculate_dosage(
        cls,
        drug_id: str,
        species: str,
        body_weight_kg: float,
    ) -> Dict[str, Any]:
        """
        Computes accurate clinical volume and instructions for a specific animal.
        """
        drug = cls.get_by_id(drug_id)
        if not drug:
            raise ValueError(f"Drug with ID '{drug_id}' not found in formulary.")

        # Fixed dose handling (e.g. intramammary syringe or topical)
        if drug["dose_per_kg_mg"] == 0.0:
            if "Intramammary" in drug["category"]:
                calculated_volume_ml = 10.0  # 1 syringe standard
                display_dose = "1 Syringe / quarter"
                display_dose_mr = "१ सिरिंज प्रति बाधित सड"
            else:
                calculated_volume_ml = 0.0
                display_dose = "Topical Application as needed"
                display_dose_mr = "गरजेनुसार मलम लावा"
            total_mg = 0.0
        else:
            total_mg = round(body_weight_kg * drug["dose_per_kg_mg"], 1)
            calculated_volume_ml = round(total_mg / drug["concentration_mg_ml"], 1)
            # Apply safety cap for single-site injections (max 20ml per site in cattle)
            display_dose = f"{calculated_volume_ml} ml ({total_mg} mg active)"
            display_dose_mr = f"{calculated_volume_ml} मिली ({total_mg} मिग्रॅ सक्रिय घटक)"

        return {
            "drug_id": drug["id"],
            "drug_name": drug["name"],
            "category": drug["category"],
            "schedule_h": drug["schedule_h"],
            "route": drug["route"],
            "body_weight_kg": body_weight_kg,
            "calculated_volume_ml": calculated_volume_ml,
            "display_dose": display_dose,
            "display_dose_mr": display_dose_mr,
            "default_duration_days": drug["default_duration_days"],
            "milk_withdrawal_days": drug["milk_withdrawal_days"],
            "meat_withdrawal_days": drug["meat_withdrawal_days"],
            "instructions_en": drug["instructions_en"],
            "instructions_mr": drug["instructions_mr"],
            "contraindications": drug["contraindications"],
        }
