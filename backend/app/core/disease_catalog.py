"""
BIOHERD Disease Catalog
Authentic catalog of endemic livestock diseases in Maharashtra (SIH26128).
Contains clinical symptom mappings across body systems, severity baselines,
and bilingual (English & Marathi) emergency bio-security first-aid protocols.
"""

from typing import Any, Dict, List, Optional
from pydantic import BaseModel


class DiseaseDefinition(BaseModel):
    id: str
    name_en: str
    name_mr: str
    species: List[str]  # cattle, buffalo, goat, sheep, poultry, pig
    causative_agent: str
    severity_baseline: str  # low, medium, high, critical
    incubation_period: str
    cardinal_symptoms: List[str]
    symptom_system_map: Dict[str, List[str]]
    marathi_keywords: List[str]
    isolation_required: bool
    zoonotic_risk: bool
    first_aid_en: Dict[str, Any]
    first_aid_mr: Dict[str, Any]


MAHARASHTRA_DISEASES: List[DiseaseDefinition] = [
    DiseaseDefinition(
        id="dis-lsd",
        name_en="Lumpy Skin Disease (LSD)",
        name_mr="गाठींचा त्वचा रोग (लम्पी स्कीन डिसीज)",
        species=["cattle", "buffalo"],
        causative_agent="Capripoxvirus (Lumpy skin disease virus)",
        severity_baseline="critical",
        incubation_period="4 to 14 days",
        cardinal_symptoms=[
            "nodular_skin_lesions",
            "high_fever",
            "enlarged_superficial_lymph_nodes",
            "lacrimation_salivation",
            "edema_of_limbs",
        ],
        symptom_system_map={
            "vitality": ["high_fever", "severe_depression", "loss_of_appetite"],
            "skin_coat": ["nodular_skin_lesions", "hard_nodules_all_over_body", "skin_ulcers", "necrotic_plugs"],
            "eyes_nasal": ["watery_eyes", "purulent_nasal_discharge", "excessive_salivation"],
            "locomotion": ["lameness", "edema_of_limbs_dewlap"],
            "udder_milk": ["drastic_milk_reduction", "nodules_on_teats"],
        },
        marathi_keywords=[
            "लम्पी", "गाठी", "त्वचेवर गाठी", "अंगावर फोड", "ताप", "डोळ्यातून पाणी",
            "पायाला सूज", "चारा खात नाही", "दूध आटले", "गळगंड", "लंपी स्कीन"
        ],
        isolation_required=True,
        zoonotic_risk=False,
        first_aid_en={
            "immediate_action": "Strictly isolate animal in a separate, fly-proof and mosquito-netted enclosure.",
            "sanitation": "Disinfect cattle stall with 1% Formalin or 2% Sodium Hydroxide or bleaching powder solution.",
            "supportive_care": "Apply herbal paste (neem leaves + turmeric powder + coconut oil) on ruptured skin nodules. Provide clean lukewarm water with jaggery and electrolytes.",
            "vector_control": "Eliminate biting flies, ticks, and mosquitoes using neem leaf smoke or pyrethroid spray in the shed.",
            "warning": "Do NOT allow animal to graze with the community herd. Report immediately to local Gram Panchayat / Pashu Chikitsalaya.",
        },
        first_aid_mr={
            "immediate_action": "बाधित जनावराला निरोगी जनावरांपासून ताबडतोब वेगळे (विलगीकरण) डास-माशांपासून सुरक्षित गोठ्यात ठेवा.",
            "sanitation": "गोठ्याची जागा १% फॉर्मेलिन किंवा चुना/ब्लीचिंग पावडरच्या पाण्याने स्वच्छ धुवून निर्जंतुक करा.",
            "supportive_care": "फुटलेल्या गाठींवर कडुलिंबाचा पाला, हळद व खोबरेल तेल यांचा लेप लावा. जनावराला गुळ-पाणी आणि इलेक्ट्रोलाइट्स द्या.",
            "vector_control": "गोठ्यात गोचीड, डास व माश्यांचा प्रादुर्भाव रोखण्यासाठी कडुलिंबाचा धूर करा.",
            "warning": "जनावराला चराऊ कुरणावर सोडू नका. नजीकच्या पशुवैद्यकीय दवाखान्याशी त्वरित संपर्क साधा.",
        },
    ),
    DiseaseDefinition(
        id="dis-fmd",
        name_en="Foot and Mouth Disease (FMD)",
        name_mr="लाळ्या खुरकूत (एफ.एम.डी)",
        species=["cattle", "buffalo", "goat", "sheep", "pig"],
        causative_agent="Aphthovirus (Picornaviridae)",
        severity_baseline="critical",
        incubation_period="2 to 8 days",
        cardinal_symptoms=[
            "frothy_salivation",
            "mouth_tongue_blisters",
            "interdigital_hoof_lesions",
            "severe_lameness",
            "smacking_of_lips",
        ],
        symptom_system_map={
            "vitality": ["high_fever", "shivering", "complete_anorexia"],
            "oral_nasal": ["frothy_ropey_salivation", "blisters_on_tongue_gums", "smacking_of_lips"],
            "locomotion": ["severe_lameness", "kicking_feet", "ulcers_in_hoof_cleft"],
            "udder_milk": ["painful_teat_vesicles", "acute_milk_drop"],
        },
        marathi_keywords=[
            "लाळ्या", "खुरकूत", "लाळ गळणे", "तोंडाला फेस", "जीभेवर फोड", "पायाला जखमा",
            "लंगडणे", "खुरांमध्ये किडे", "चारा न खाणे", "ताप"
        ],
        isolation_required=True,
        zoonotic_risk=False,
        first_aid_en={
            "immediate_action": "Quarantine animal immediately. Highly contagious viral pathogen transmitted via droplets and milk.",
            "mouth_wash": "Gently wash mouth and tongue with mild 1% Potassium Permanganate (KMNO4) or 2% Sodium Bicarbonate (Baking Soda) solution.",
            "hoof_wash": "Wash hooves with 2% copper sulphate solution or clean water, then apply fly-repellent antiseptic ointment to prevent maggot infestation.",
            "diet": "Provide soft, easily digestible gruel (cooked broken wheat/daliya, rice porridge, jaggery water). Avoid dry coarse fodder.",
            "warning": "Never move animal outside farm boundary. Do NOT transport raw unpasteurized milk.",
        },
        first_aid_mr={
            "immediate_action": "बाधित जनावराला तात्काळ वेगळे बांधा. हा अतिशय वेगाने पसरणारा संसर्गजन्य विषाणूजन्य रोग आहे.",
            "mouth_wash": "तोंडातील फोड स्वच्छ करण्यासाठी १% पोटॅशियम परमँगनेट किंवा २% खाण्याच्या सोड्याच्या पाण्याने तोंड हलक्या हाताने धुवा.",
            "hoof_wash": "खुरांमधील जखमा २% मोरचूद (कॉपर सल्फेट) द्रावणाने धुवा आणि त्यावर माश्या बसू नये म्हणून जंतुनाशक मलम लावा.",
            "diet": "जनावराला मऊ आणि पचायला सोपा चारा, गव्हाची लापशी, भाताची पेज आणि गुळ-पाणी द्या. कोरडा चारा देऊ नका.",
            "warning": "जनावराला बाजारात किंवा इतर शेतात नेऊ नका. दूध चांगले उकळूनच वापरा.",
        },
    ),
    DiseaseDefinition(
        id="dis-bq",
        name_en="Black Quarter (BQ)",
        name_mr="एकटांग्या / फऱ्या (ब्लॅक क्वॉर्टर)",
        species=["cattle", "buffalo", "sheep"],
        causative_agent="Clostridium chauvoei (Bacterial spore)",
        severity_baseline="critical",
        incubation_period="1 to 5 days",
        cardinal_symptoms=[
            "crepitant_swelling_thigh_shoulder",
            "acute_lameness",
            "high_fever",
            "crackling_sound_on_pressing_muscle",
            "dark_bloody_frothy_exudate",
        ],
        symptom_system_map={
            "vitality": ["sudden_high_fever", "severe_prostration", "accelerated_pulse"],
            "skin_coat": ["hot_painful_swelling_turning_cold", "crackling_subcutaneous_gas", "dark_discoloration"],
            "locomotion": ["acute_severe_lameness", "dragging_one_leg", "inability_to_stand"],
            "digestive": ["ruminal_stasis", "severe_colic"],
        },
        marathi_keywords=[
            "एकटांग्या", "फऱ्या", "एका पायाने लंगडणे", "मांडीला सूज", "खांद्याला सूज",
            "हवा भरल्यासारखा आवाज", "चरचर आवाज", "तीव्र ताप", "अचानक मरणे"
        ],
        isolation_required=True,
        zoonotic_risk=False,
        first_aid_en={
            "immediate_action": "EMERGENCY: High mortality within 12-36 hours. Contact veterinarian immediately for parenteral high-dose penicillin/oxytetracycline therapy.",
            "handling": "Keep animal quiet in dry bedded stall. Do NOT incise or cut open the swelling (releases soil-contaminating spores).",
            "herd_protection": "Ring vaccinate all remaining healthy cattle aged 6 months to 3 years with BQ vaccine.",
            "carcass_warning": "If death occurs, do NOT open carcass. Deep burial with quicklime is legally mandatory.",
        },
        first_aid_mr={
            "immediate_action": "तातडीची वैद्यकीय मदत आवश्यक: हा रोग १२ ते ३६ तासांत जीवघेणा ठरू शकतो. ताबडतोब पशुवैद्यांना पाचारण करा.",
            "handling": "जनावराला शांत व कोरड्या जागी ठेवा. सुजलेल्या भागावर कोणतीही चिरफाड करू नका, यामुळे जिवाणू जमिनीत पसरतात.",
            "herd_protection": "कळपातील इतर ६ महिने ते ३ वर्षे वयाच्या सर्व निरोगी जनावरांचे तातडीने एकटांग्या प्रतिबंधक लसीकरण करा.",
            "carcass_warning": "मृत जनावर उघड्यावर टाकू नका. जनावराला न कापता खोल खड्ड्यात चुना टाकून पुरा.",
        },
    ),
    DiseaseDefinition(
        id="dis-hs",
        name_en="Haemorrhagic Septicaemia (HS)",
        name_mr="घटसर्प (एच.एस / गळसूज)",
        species=["buffalo", "cattle"],
        causative_agent="Pasteurella multocida",
        severity_baseline="critical",
        incubation_period="1 to 3 days",
        cardinal_symptoms=[
            "submandibular_throat_swelling",
            "grunting_respiration",
            "severe_dyspnea",
            "high_fever",
            "protrusion_of_tongue",
        ],
        symptom_system_map={
            "vitality": ["sudden_high_fever_106f", "shivering", "rapid_pulse"],
            "respiratory": ["throat_neck_brisket_swelling", "grunting_labored_breathing", "extended_neck_gasping"],
            "oral_nasal": ["protruded_cyanotic_tongue", "profuse_salivation", "nasal_discharge"],
        },
        marathi_keywords=[
            "घटसर्प", "गळसूज", "घशाखाली सूज", "श्वास घेताना घोरणे", "जीभ बाहेर येणे",
            "तीव्र ताप", "लाळ गळणे", "घुरघुर आवाज"
        ],
        isolation_required=True,
        zoonotic_risk=False,
        first_aid_en={
            "immediate_action": "CRITICAL EMERGENCY: Severe throat swelling suffocates animal. Call emergency veterinary team instantly for IV antibiotics.",
            "posture": "Keep head elevated to ease breathing. Remove tight ropes and halters.",
            "cooling": "Apply cold water pack on head and throat area while waiting for vet.",
            "herd_prevention": "Administer emergency HS adjuvant vaccine to all cattle and buffaloes in the village.",
        },
        first_aid_mr={
            "immediate_action": "अतितातडीची बाब: घसा सुजून श्वास कोंडल्याने जनावर दगावू शकते. ताबडतोब पशुवैद्यांकडून इंजेक्शन द्या.",
            "posture": "जनावराचे डोके थोडे वर राहील अशा स्थितीत ठेवा. गळ्यातील दोरी किंवा दावी सैल करा.",
            "cooling": "घशावर आणि कपाळावर थंड पाण्याचे फडके ठेवा जेणेकरून जनावराला श्वास घेणे थोडे सोपे होईल.",
            "herd_prevention": "गावातील व शेतातील इतर सर्व गायी-म्हशींना तात्काळ घटसर्प प्रतिबंधक लस टोचा.",
        },
    ),
    DiseaseDefinition(
        id="dis-mastitis",
        name_en="Mastitis (Clinical / Subclinical)",
        name_mr="स्तनदाह / मस्टायटिस (गाण)",
        species=["cattle", "buffalo", "goat"],
        causative_agent="Staphylococcus aureus / Streptococcus uberis / E. coli",
        severity_baseline="medium",
        incubation_period="1 to 4 days",
        cardinal_symptoms=[
            "swollen_hot_painful_udder",
            "clots_flakes_watery_milk",
            "blood_in_milk",
            "reluctance_to_let_milk",
            "reduced_milk_yield",
        ],
        symptom_system_map={
            "udder_milk": [
                "hard_swollen_teat_quarter",
                "hot_painful_udder",
                "curd_like_clots_in_milk",
                "watery_yellow_or_bloody_milk",
                "abrupt_drop_in_lactation",
            ],
            "vitality": ["moderate_fever_in_acute_cases", "kicking_during_milking", "dullness"],
        },
        marathi_keywords=[
            "स्तनदाह", "मस्टायटिस", "कास सुजणे", "कास गरम होणे", "दुधात गाठी", "दुधात रक्त",
            "पाणीदार दूध", "कासेला हात लावू न देणे", "दूध काढताना लाथा मारणे"
        ],
        isolation_required=False,
        zoonotic_risk=True,  # Milk contaminated
        first_aid_en={
            "immediate_action": "Frequent stripping of affected quarter every 2 hours to remove bacterial toxins.",
            "cold_hot_pack": "Apply ice pack in acute hot swelling. For chronic hard udder, apply warm compress followed by gentle massage.",
            "milking_order": "Always milk healthy cows first, and affected quarter last. Discard affected milk completely.",
            "teat_dip": "Dip all teats in 0.5% povidone iodine teat dip before and after milking. Keep floor clean and dry.",
            "warning": "Do NOT consume or sell contaminated milk. Veterinary intramammary antibiotic infusion required.",
        },
        first_aid_mr={
            "immediate_action": "बाधित सडातील खराब दूध दर दोन तासांनी काढून टाका जेणेकरून विषारी घटक बाहेर पडतील.",
            "cold_hot_pack": "कास जास्त गरम व सुजलेली असल्यास बर्फ लावावा. कास कडक असल्यास कोमट पाण्याने शेकावे.",
            "milking_order": "निरोगी गायींचे दूध प्रथम काढावे आणि आजारी गायीचे किंवा बाधित सडाचे दूध शेवटी काढावे.",
            "teat_dip": "दूध काढण्यापूर्वी व नंतर सड आयोडीनच्या द्रावणात बुडवून निर्जंतुक करावे. गोठा कोरडा ठेवावा.",
            "warning": "बाधित सडाचे दूध पिण्यासाठी किंवा डेअरीला देऊ नका. पशुवैद्यांकडून सडात सोडण्याचे औषध घ्या.",
        },
    ),
    DiseaseDefinition(
        id="dis-babesiosis",
        name_en="Bovine Babesiosis (Tick Fever / Redwater)",
        name_mr="लालबुंद ताप / टिक फिव्हर (बाबेसियोसिस)",
        species=["cattle", "buffalo"],
        causative_agent="Babesia bigemina / Babesia bovis (Protozoan via Rhipicephalus tick)",
        severity_baseline="high",
        incubation_period="7 to 14 days",
        cardinal_symptoms=[
            "dark_red_coffee_colored_urine",
            "high_fever_105f",
            "pale_yellow_jaundice_mucosa",
            "heavy_tick_infestation",
            "rapid_weight_loss",
        ],
        symptom_system_map={
            "vitality": ["sustained_high_fever", "severe_weakness", "rapid_shallow_breathing"],
            "excretory": ["hemoglobinuria_red_dark_urine", "frequent_urination"],
            "eyes_mucosa": ["pale_anemic_conjunctiva", "yellowish_jaundiced_gums"],
            "skin_coat": ["heavy_tick_load_in_groin_ears", "rough_dull_coat"],
        },
        marathi_keywords=[
            "लालबुंद", "लाल लघवी", "कॉफी रंगाची लघवी", "गोचीड ताप", "गोचीड", "तीव्र ताप",
            "डोळे पिवळे होणे", "रक्त कमी होणे", "अशक्तपणा"
        ],
        isolation_required=False,
        zoonotic_risk=False,
        first_aid_en={
            "immediate_action": "Urgent antiprotozoal injection (Diminazene aceturate / Imidocarb) required from veterinarian.",
            "supportive_care": "Provide iron tonics, liver extract, and vitamin B-complex. Keep animal in cool shaded well-ventilated shelter.",
            "tick_management": "Apply authorized acaricide spray (Flumethrin / Amitraz) on animal and shed walls to break tick vector cycle.",
            "diet": "Provide easily palatable green fodder and clean electrolyte water.",
        },
        first_aid_mr={
            "immediate_action": "तात्काळ पशुवैद्यांकडून बाबेसियोसिस प्रतिबंधक औषधाचे (डायमिनाझिन/इमिडोकार्ब) इंजेक्शन द्या.",
            "supportive_care": "जनावरातील रक्तवाढीसाठी लोहयुक्त टॉनिक, लिव्हर टॉनिक आणि बी-कॉम्प्लेक्स द्या. जनावराला थंड सावलीत ठेवा.",
            "tick_management": "गोठ्यातील व अंगावरील गोचीड नष्ट करण्यासाठी पशुवैद्यांच्या सल्ल्याने गोचीडनाशक फवारणी करा.",
            "diet": "जनावराला सकस हिरवा चारा आणि भरपूर स्वच्छ पाणी पिण्यासाठी द्या.",
        },
    ),
    DiseaseDefinition(
        id="dis-ppr",
        name_en="Peste des Petits Ruminants (Goat Plague / PPR)",
        name_mr="शेळ्या-मेंढ्यांमधील देवी / पी.पी.आर (गोट प्लेग)",
        species=["goat", "sheep"],
        causative_agent="Morbillivirus (Paramyxoviridae)",
        severity_baseline="critical",
        incubation_period="3 to 6 days",
        cardinal_symptoms=[
            "foul_smelling_watery_diarrhea",
            "crusty_nasal_ocular_discharge",
            "mouth_necrotic_erosions",
            "high_fever",
            "severe_pneumonia_coughing",
        ],
        symptom_system_map={
            "vitality": ["high_fever_104_106f", "severe_depression", "dehydration"],
            "eyes_nasal": ["crusts_around_eyes_nostrils", "mucopurulent_discharge", "matted_eyelashes"],
            "oral": ["necrotic_mouth_ulcers", "bad_odor_from_breath", "difficulty_chewing"],
            "digestive": ["profuse_watery_blackish_diarrhea", "soiled_hindquarters"],
            "respiratory": ["frequent_coughing", "fast_labored_breathing"],
        },
        marathi_keywords=[
            "पीपीआर", "शेळ्यांचा प्लेग", "शेळीला हगवण", "नाकातून शेंबूड", "डोळ्यातून घाण",
            "तोंडात अल्सर", "तोंडात घाण वास", "शेळी खोकणे", "शेळी चारा खात नाही"
        ],
        isolation_required=True,
        zoonotic_risk=False,
        first_aid_en={
            "immediate_action": "Strict quarantine of affected goats/sheep. Transmitted by contact and inhalation; spreads like wildfire in flocks.",
            "oral_care": "Clean oral lesions with 5% sodium bicarbonate solution or boroglycerin.",
            "hydration": "Administer oral rehydration solution (ORS) with zinc and electrolytes to combat deadly dehydration.",
            "respiratory": "Protect from chilling and drafts. Provide dry clean bedding.",
            "herd_prevention": "Vaccinate all healthy small ruminants in the flock with live attenuated PPR vaccine.",
        },
        first_aid_mr={
            "immediate_action": "आजारी शेळ्या-मेंढ्या तातडीने कळपातून वेगळ्या करा. हा रोग कळपात अतिशय वेगाने पसरतो.",
            "oral_care": " तोंडातील जखमा स्वच्छ कापसाने खाण्याच्या सोड्याच्या पाण्याने पुसा आणि बोरोग्लिसरीन लावा.",
            "hydration": "हगवणीमुळे शरीरातील पाणी कमी होऊ नये म्हणून जनावराला ओ.आर.एस (ORS) चे पाणी सतत पाजा.",
            "respiratory": "शेळ्यांना थंडी व वाऱ्यापासून वाचवा, गोठ्यात कोरडे गवत किंवा तूस पसरा.",
            "herd_prevention": "कळपातील इतर निरोगी शेळ्या-मेंढ्यांना पशुवैद्यकीय अधिकाऱ्यांकडून PPR ची लस टोचा.",
        },
    ),
    DiseaseDefinition(
        id="dis-anthrax",
        name_en="Anthrax (Splenic Fever)",
        name_mr="काळपुळी (अँथ्रॅक्स)",
        species=["cattle", "buffalo", "sheep", "goat"],
        causative_agent="Bacillus anthracis (Spore-forming bacterium)",
        severity_baseline="critical",
        incubation_period="1 to 7 days",
        cardinal_symptoms=[
            "sudden_death_without_warning",
            "dark_non_clotting_blood_from_orifices",
            "absence_of_rigor_mortis",
            "high_fever_and_shivering_prior_to_collapse",
            "swelling_in_neck_and_chest",
        ],
        symptom_system_map={
            "vitality": ["apoplectic_sudden_collapse", "extreme_high_fever", "tremors"],
            "excretory_orifices": ["tarry_dark_blood_from_nose_mouth_rectum_vulva", "unclotted_blood"],
            "respiratory": ["gasping_for_breath", "cyanosis"],
        },
        marathi_keywords=[
            "काळपुळी", "अँथ्रॅक्स", "अचानक मरणे", "नाकातून काळे रक्त", "गुदद्वारातून रक्त",
            "रक्त न गोठणे", "कडक न होणारे शरीर", "गळ्याजवळ सूज"
        ],
        isolation_required=True,
        zoonotic_risk=True,  # Extremely dangerous to humans
        first_aid_en={
            "immediate_action": "EXTREME DANGER (ZOONOTIC): Do NOT touch carcass or body fluids with bare hands. Wear heavy rubber gloves and mask.",
            "carcass_ban": "STRICT BAN: NEVER open, skin, or perform post-mortem on carcass. Exposure to oxygen turns bacteria into indestructible spores that persist in soil for 50 years.",
            "disposal": "Notify District Veterinary Officer immediately. Mandatory burial at least 6 feet deep covered with quicklime.",
            "disinfection": "Burn all bedding, manure, and feed remnants. Disinfect premises with 5% Lysol or 10% Caustic Soda.",
        },
        first_aid_mr={
            "immediate_action": "अतिधोकादायक (माणसांनाही होणारा रोग): मृत जनावराला किंवा रक्ताला उघड्या हाताने अजिबात स्पर्श करू नका.",
            "carcass_ban": "कडक बंदी: मृत जनावराची कातडी काढू नका किंवा शवविच्छेदन करू नका! हवेच्या संपर्काने जमिनीमध्ये ५० वर्षे जिवंत राहणारे विषाणू तयार होतात.",
            "disposal": "जिल्हा पशुवैद्यकीय अधिकाऱ्यांना तात्काळ खबर द्या. जनावराचा मृतदेह किमान ६ फूट खोल खड्ड्यात चुना टाकून पुरा.",
            "disinfection": "गोठ्यातील चारा, शेण व केर जाळून टाका आणि ५% लायसॉलने गोठा निर्जंतुक करा.",
        },
    ),
    DiseaseDefinition(
        id="dis-brucellosis",
        name_en="Brucellosis (Bang's Disease)",
        name_mr="ब्रुसेलोसिस (गर्भपाताचा रोग)",
        species=["cattle", "buffalo"],
        causative_agent="Brucella abortus",
        severity_baseline="high",
        incubation_period="2 to 4 weeks",
        cardinal_symptoms=[
            "late_term_abortion_last_trimester",
            "retention_of_fetal_membranes_placenta",
            "orchitis_in_bulls",
            "hygroma_swollen_knee_joints",
            "infertility_repeat_breeding",
        ],
        symptom_system_map={
            "reproductive": [
                "abortion_at_6_to_8_months",
                "retained_placenta_jer",
                "foul_vaginal_discharge",
                "swollen_testicles_in_breeding_bull",
            ],
            "locomotion": ["hygroma_fluid_swelling_on_knees", "stiffness_in_joints"],
            "udder_milk": ["chronic_subclinical_mastitis", "intermittent_low_yield"],
        },
        marathi_keywords=[
            "गर्भपात", "ब्रुसेलोसिस", "वार अडकणे", "शेवटच्या महिन्यात गर्भपात",
            "वार न पडणे", "गुळगुळीत सूज", "गुडघ्यावर सूज", "वारंवार उलटणे"
        ],
        isolation_required=True,
        zoonotic_risk=True,  # Causes undulant fever in humans via raw milk
        first_aid_en={
            "immediate_action": "Burn or bury aborted fetus and placenta with quicklime immediately. Wear waterproof gloves.",
            "milk_safety": "Do NOT drink raw milk under any circumstances. Pasteurize or boil milk vigorously to prevent human Brucellosis (Malta fever).",
            "sanitation": "Wash vaginal area with antiseptic solution. Disinfect calving pen with 2% sodium hypochlorite.",
            "screening": "Conduct Rose Bengal Plate Test (RBPT) blood screening on entire dairy herd.",
        },
        first_aid_mr={
            "immediate_action": "गर्भपात झालेला गर्भ व वार (प्लॅसेंटा) हातमोजे घालून खोल खड्ड्यात चुना टाकून पुरा किंवा जाळा.",
            "milk_safety": "कच्चे दूध अजिबात पिऊ नका! दूध चांगले उकळल्याशिवाय वापरू नये, अन्यथा माणसांना हा आजार (ताप) होतो.",
            "sanitation": "गाय/म्हशीचा पाठीमागचा भाग जंतुनाशक पाण्याने स्वच्छ करा. गोठा चुना किंवा ब्लीचिंगने धुवा.",
            "screening": "संपूर्ण गोठ्यातील जनावरांची पशुवैद्यांमार्फत रक्ततपासणी (RBPT) करून घ्या.",
        },
    ),
    DiseaseDefinition(
        id="dis-swine-fever",
        name_en="Classical / African Swine Fever",
        name_mr="स्वाइन फिव्हर / डुकरांचा ताप",
        species=["pig"],
        causative_agent="Pestivirus / Asfarviridae",
        severity_baseline="critical",
        incubation_period="3 to 7 days",
        cardinal_symptoms=[
            "high_fever_and_huddling",
            "cyanosis_purple_skin_discoloration_ears_belly",
            "severe_diarrhea_and_vomiting",
            "incoordination_and_ataxia",
            "high_mortality_in_all_ages",
        ],
        symptom_system_map={
            "vitality": ["fever_above_105f", "huddling_together", "prostration"],
            "skin_coat": ["purple_hemorrhagic_patches_on_ears", "snout_abdomen_cyanosis"],
            "digestive": ["vomiting", "constipation_followed_by_severe_bloody_diarrhea"],
            "locomotion": ["wobbly_gait", "hindquarter_weakness", "convulsions"],
        },
        marathi_keywords=[
            "स्वाइन फिव्हर", "डुकरांचा ताप", "कानाला जांभळे चट्टे", "पोटावर लाल चट्टे",
            "उलट्या", "हगवण", "डुकरांचा मृत्यू"
        ],
        isolation_required=True,
        zoonotic_risk=False,
        first_aid_en={
            "immediate_action": "Strict quarantine of pig farm. Completely halt all entry/exit of pigs, feed, and vehicles.",
            "biosecurity": "Footbaths with 2% caustic soda at all farm gates. Disinfect pens daily.",
            "notification": "Immediate notification to District Veterinary Polyclinic; mandatory culling zones may be established.",
        },
        first_aid_mr={
            "immediate_action": "वराह पालकांनी गोठ्याचे तात्काळ विलगीकरण करावे. कोणत्याही नवीन जनावराची ने-आण थांबवावी.",
            "biosecurity": "गोठ्याच्या प्रवेशद्वारावर २% कॉस्टिक सोड्याचे पाय धुण्याचे भांडे ठेवावे. गोठा दररोज जंतुनाशकाने धुवावा.",
            "notification": "जिल्हा पशुवैद्यकीय अधिकाऱ्यांना तात्काळ माहिती द्यावी.",
        },
    ),
]


def get_all_diseases() -> List[DiseaseDefinition]:
    return MAHARASHTRA_DISEASES


def get_disease_by_id(disease_id: str) -> Optional[DiseaseDefinition]:
    for d in MAHARASHTRA_DISEASES:
        if d.id == disease_id:
            return d
    return None


def get_diseases_for_species(species_name: str) -> List[DiseaseDefinition]:
    sp_lower = species_name.lower().strip()
    return [d for d in MAHARASHTRA_DISEASES if any(s in sp_lower for s in d.species)]
