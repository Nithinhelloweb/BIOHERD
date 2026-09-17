from typing import List, Optional
from app.db.models import AnimalSpecies
from app.schemas.animal import BreedInfo

MAHARASHTRA_INDIGENOUS_BREEDS: List[BreedInfo] = [
    # CATTLE
    BreedInfo(
        name="Khillari",
        name_mr="खिलारी",
        species=AnimalSpecies.CATTLE,
        origin_region="Western Maharashtra / Solapur Plateau",
        districts=["Solapur", "Sangli", "Kolhapur", "Satara"],
        description="Exceptional draught breed, grey-white coat with pink horns, great heat resistance and endurance.",
        description_mr="उत्कृष्ट कामाची जात, राखाडी-पांढरा रंग आणि गुलाबी शिंगे, दुष्काळी भागात काम करण्याची उच्च क्षमता.",
    ),
    BreedInfo(
        name="Dangi",
        name_mr="डांगी",
        species=AnimalSpecies.CATTLE,
        origin_region="Western Ghats / Konkan foothills",
        districts=["Nashik", "Ahmednagar", "Thane", "Palghar"],
        description="Medium-sized with black/red spots on white coat; oiled skin secretion protects against torrential monsoon rainfall.",
        description_mr="पांढऱ्यावर काळे किंवा तांबडे ठिपके; मुसळधार पावसात तग धरण्यासाठी त्वचेतून तेलकट स्त्राव पाझरतो.",
    ),
    BreedInfo(
        name="Deoni",
        name_mr="देवणी",
        species=AnimalSpecies.CATTLE,
        origin_region="Marathwada / Balaghat Range",
        districts=["Latur", "Nanded", "Dharashiv", "Parbhani"],
        description="Prized dual-purpose breed (dairy & draught), black-and-white spotted with gentle temperament.",
        description_mr="दुहेरी हेतूची (दूध आणि शेती) प्रसिद्ध जात, काळ्या-पांढऱ्या रंगाची आणि शांत स्वभावाची गोवंश जात.",
    ),
    BreedInfo(
        name="Gaolao",
        name_mr="गौळाऊ",
        species=AnimalSpecies.CATTLE,
        origin_region="Vidarbha / Wardha Valley",
        districts=["Wardha", "Nagpur", "Amravati"],
        description="Compact, fast trotting draught and dairy cattle with narrow convex head and alert disposition.",
        description_mr="विदर्भातील प्रसिद्ध जलद चालणारी जात, अरुंद व फुगीर कपाळ आणि चपळ हालचाली.",
    ),
    BreedInfo(
        name="Red Kandhari",
        name_mr="लाल कंधारी",
        species=AnimalSpecies.CATTLE,
        origin_region="Marathwada",
        districts=["Nanded", "Latur", "Hingoli"],
        description="Uniform dark red to brown coat, medium build, energetic and resilient draught animal.",
        description_mr="गडद तांबडा रंग, मध्यम चणीची आणि अतिशय काटक अशी मराठवाड्यातील पारंपरिक जात.",
    ),
    BreedInfo(
        name="Gir",
        name_mr="गीर",
        species=AnimalSpecies.CATTLE,
        origin_region="Saurashtra & Western Maharashtra Dairy Belt",
        districts=["Pune", "Kolhapur", "Sangli", "Satara"],
        description="Premier Indian A2 dairy cattle with pendulous ears, convex forehead, and high disease immunity.",
        description_mr="उत्कृष्ट A2 दुग्धोत्पादक जात, लोंबते कान आणि फुगीर कपाळ, उच्च रोगप्रतिकारक क्षमता.",
    ),

    # BUFFALO
    BreedInfo(
        name="Pandharpuri",
        name_mr="पंढरपुरी",
        species=AnimalSpecies.BUFFALO,
        origin_region="Western Maharashtra / Bhima River Basin",
        districts=["Solapur", "Kolhapur", "Sangli", "Satara"],
        description="Distinctive sword/twisted backward horns reaching up to shoulders, high lactation yield with rich butterfat.",
        description_mr="लांब तलवारीसारखी पाठीवर जाणारी वळणदार शिंगे, भरपूर दूध आणि फॅटचे उच्च प्रमाण.",
    ),
    BreedInfo(
        name="Nagpuri",
        name_mr="नागपुरी (एलिचपुरी)",
        species=AnimalSpecies.BUFFALO,
        origin_region="Eastern Vidarbha",
        districts=["Nagpur", "Wardha", "Chandrapur", "Amravati"],
        description="Draught and milk buffalo with long flat swept-back horns, well suited to semi-arid extremes.",
        description_mr="विदर्भातील उष्ण हवामानात सहज जुळवून घेणारी, दूध आणि कामासाठी उपयुक्त पारंपरिक म्हैस.",
    ),
    BreedInfo(
        name="Marathwadi",
        name_mr="मराठवाडी",
        species=AnimalSpecies.BUFFALO,
        origin_region="Marathwada",
        districts=["Beed", "Parbhani", "Jalna", "Latur"],
        description="Medium sized, flat horns, highly resistant to drought and low fodder conditions.",
        description_mr="कमी चाऱ्यावर तग धरणारी आणि दुष्काळी स्थितीतही दुग्ध टिकवणारी काटक जात.",
    ),
    BreedInfo(
        name="Murrah",
        name_mr="मुर्रा",
        species=AnimalSpecies.BUFFALO,
        origin_region="Dairy Cooperatives of Maharashtra",
        districts=["Pune", "Kolhapur", "Ahmednagar", "Nashik"],
        description="Jet black coat, tightly curled horns, highest yielding dairy buffalo in commercial dairy herds.",
        description_mr="जेट ब्लॅक रंग आणि कुरळी शिंगे, उच्च दुग्धोत्पादक म्हैस.",
    ),

    # GOAT
    BreedInfo(
        name="Osmanabadi",
        name_mr="उस्मानाबादी",
        species=AnimalSpecies.GOAT,
        origin_region="Marathwada / Dharashiv",
        districts=["Dharashiv", "Latur", "Solapur", "Ahmednagar"],
        description="Predominantly black coat, twin kidding rate (>60%), high disease resistance and drought tolerance.",
        description_mr="काळी चमकदार त्वचा, जुळे देण्याची उच्च क्षमता (६०%+), रोगप्रतिकारशक्ती आणि मांस उत्पादनात अव्वल.",
    ),
    BreedInfo(
        name="Sangamneri",
        name_mr="संगमनेरी",
        species=AnimalSpecies.GOAT,
        origin_region="Ahmednagar / Northern Maharashtra",
        districts=["Ahmednagar", "Pune", "Nashik"],
        description="White, brown, or speckled coat; dual purpose with good milk yield and prolific breeding.",
        description_mr="पांढऱ्या किंवा तपकिरी रंगाची, दूध आणि मांस दोन्हीसाठी उपयुक्त संगमनेर भागातील शेळी.",
    ),
    BreedInfo(
        name="Berari",
        name_mr="बेरारी",
        species=AnimalSpecies.GOAT,
        origin_region="Vidarbha",
        districts=["Nagpur", "Amravati", "Wardha", "Akola"],
        description="Light brown coat with black dorsal stripe, well-adapted to high summer temperatures.",
        description_mr="पाठीवर काळी रेषा आणि तपकिरी रंग, विदर्भातील कडक उन्हाळ्यात उत्तम वाढणारी जात.",
    ),
    BreedInfo(
        name="Konkan Kanyal",
        name_mr="कोकण कन्याळ",
        species=AnimalSpecies.GOAT,
        origin_region="Konkan Coastal Belt",
        districts=["Sindhudurg", "Ratnagiri", "Raigad"],
        description="Dark bronze body with distinctive white face stripes, uniquely resilient in humid high-rainfall climate.",
        description_mr="चेहऱ्यावर पांढरे पट्टे आणि कांस्य रंग, कोकणातील दमट व पावसाळी हवामानात उत्तम तग धरणारी जात.",
    ),

    # SHEEP
    BreedInfo(
        name="Deccani",
        name_mr="दख्खनी",
        species=AnimalSpecies.SHEEP,
        origin_region="Deccan Plateau",
        districts=["Pune", "Solapur", "Satara", "Ahmednagar"],
        description="Hardy coarse-wool sheep, black/grey/brown mix, well adapted to pastoral nomadic migration.",
        description_mr="दख्खनच्या पठारावरील काटक मेंढी, खडतर हवामानात आणि भटकंतीत तग धरणारी जात.",
    ),
    BreedInfo(
        name="Madgyal",
        name_mr="माडग्याळ",
        species=AnimalSpecies.SHEEP,
        origin_region="Southern Maharashtra / Sangli",
        districts=["Sangli", "Solapur", "Kolhapur"],
        description="Distinctive roman nose, white coat with brown spots around neck/ears, prized heavy meat breed.",
        description_mr="पोपटासारखे बाकदार नाक (रोमन नोज), पांढऱ्या अंगावर मानेभोवती तपकिरी डाग, वजनदार मांसल जात.",
    ),

    # POULTRY
    BreedInfo(
        name="Kadaknath",
        name_mr="कडकनाथ",
        species=AnimalSpecies.POULTRY,
        origin_region="Satpura foothills & Western Maharashtra farms",
        districts=["Nandurbar", "Dhule", "Pune", "Kolhapur"],
        description="All-black plumage, skin, bone, and meat (melanosis); high protein, low fat, medicinal qualities.",
        description_mr="काळी त्वचा, काळे मांस आणि काळे हाडे; प्रथिनयुक्त व कमी चरबी असलेले औषधी गुणधर्माचे देशी कोंबडी.",
    ),
    BreedInfo(
        name="Aseel",
        name_mr="असील",
        species=AnimalSpecies.POULTRY,
        origin_region="Rural Maharashtra backyard farms",
        districts=["Kolhapur", "Satara", "Solapur", "Nagpur"],
        description="Muscular frame, aggressive disposition, magnificent stance, high disease resistance.",
        description_mr="मजबूत चण, चपळ आणि झुंजार देशी पक्षी, निसर्गदत्त रोगप्रतिकारक शक्ती.",
    ),
]

def get_indigenous_breeds(species: Optional[AnimalSpecies] = None) -> List[BreedInfo]:
    if species:
        return [b for b in MAHARASHTRA_INDIGENOUS_BREEDS if b.species == species]
    return MAHARASHTRA_INDIGENOUS_BREEDS
