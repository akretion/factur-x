# Copyright 2026 Akretion France (https://www.akretion.com).
# @author: Alexis de Lattre <alexis.delattre@akretion.com>

import datetime
import json
import unittest

from facturx import (
    data_dict_to_json,
    generate_xml,
    is_credit_note,
    parse_ubl_cii_xml,
)

# from pprint import pprint
# from deepdiff import DeepDiff

FLAVOR2LEVELS = {
    "factur-x": ["extended", "en16931", "basicwl", "extended-ctc-fr"],
    "ubl-2.1": ["en16931", "extended-ctc-fr"],
}


class TestGenerateXML(unittest.TestCase):
    def _prepare_data_dict(self):
        data_dict = {
            "BT-1": "F124212",
            "BT-2": datetime.date(2026, 6, 17),
            "BT-3": "380",
            "BT-5": "USD",
            "BT-6": "EUR",
            # for BT-8, as the values are different in UBL and CII
            # we use a codification: 'invoice', 'delivery' or 'payment'
            "BT-8": "invoice",
            "BT-9": datetime.date(2026, 7, 16),
            "BT-10": "120943",
            "BT-11": "Projet_Zorro",
            "BT-11-0": "Zorro super projet",
            "BT-12": "Contrat_du_siècle",
            "BT-13": "PO1242",
            "BT-14": "DEVIS2093",
            "BT-15": "BR-2026/06/42",
            "BT-16": "BL-2026/05/12",
            "BT-19": "401HOF",
            "BT-20": "30 jours net",
            "BT-23": "S1",
            "BG-4": {  # Seller
                "name": "Au bon moulin",
                "biz_name": "L'huile d'olive en folie",
                "identifiers": {
                    # key = schemeID, value = GlobalID value
                    # if not key: value = ID
                    # None: 'REF_SELLER',  # not allowed by UBL schematron
                    "0009": "99999999800019",
                    "0224": "Code_ROUTAGE_seller",
                },
                "legal_identifier": "999999998",
                "legal_identifier_schemeid": "0002",
                "legal_info": "SARL au capital de 42 000 € - APE 6201Z",
                "vat_identifier": "FR11999999998",
                "tax_identifier": "DGFIP_ref_1242",
                "einvoicing_addr": "999999998_042",
                "einvoicing_addr_schemeid": "0225",
                "addr_l1": "1242 chemin de l'olive",
                "addr_l2": "Lieu dit des senteurs",
                "addr_l3": "ZAC du Mont Ventoux",
                "city": "Malaucène",
                "postcode": "84340",
                "country_subdivision": "Vaucluse",
                "country_code": "FR",
                "contacts": [
                    {
                        "name": "M. Rémi Dupont",
                        "phone": "+33 6 12 42 12 42",
                        "email": "commercial@aubonmoulin.com",
                    }
                ],
            },
            "BG-7": {  # Buyer
                "name": "Ma jolie boutique SARL",
                "biz_name": "Ma jolie Trading Brand",
                "identifiers": {
                    # for buyer: either ID (key None) or GlobalID, not both
                    #                None: "REF_BUYER",
                    "0009": "78787878400018",
                    # FX schematron doesn't allow multiple schemes for buyer
                    # but it allows that for seller... I don't understand this !
                    #                "0224": 'code_routage_buyer',
                },
                "legal_identifier": "787878784",
                "legal_identifier_schemeid": "0002",
                "vat_identifier": "FR19787878784",
                "einvoicing_addr": "787878784",
                "einvoicing_addr_schemeid": "0225",
                "addr_l1": "35 rue de la République",
                "addr_l2": "La presqu'île",
                "city": "Lyon",
                "postcode": "69001",
                "country_subdivision": "Rhône",
                "country_code": "FR",
                # either personName (BT-56) OR DepartmentName (BT-56-0), not both
                "contacts": [
                    {
                        "name": "Mme Laëtitia Durand",
                        "phone": "+33 7 42 12 42 12",
                        "email": "laetita.durand@jolieboutique.com",
                    }
                ],
            },
            "EXT-FR-FE-BG-03": {  # Seller Agent
                "name": "M. Rémi Agent",
                "contacts": [
                    {
                        "name": "Rémi Agent",
                        "phone": "+33 7 87 32 34 54",
                        "email": "remi@superagent.com",
                    }
                ],
            },
            "EXT-FR-FE-BG-01": {  # Buyer Agent
                "name": "M. Négociateur CHEF",
                "contacts": [
                    {
                        "name": "Charlotte Dupont",
                        "phone": "+33 7 88 55 33 22",
                        "email": "charlotte@supernegociatrice.eu",
                    }
                ],
            },
            "EXT-FR-FE-BG-05": {  # Invoicer
                "name": "Facturier SARL",
                "country_code": "FR",
                "postcode": "97400",
                "city": "St Denis",
                "addr_l1": "12 rue Sainte Marie",
                "legal_identifier": "704721240",
                "legal_identifier_schemeid": "0002",
            },
            "EXT-FR-FE-BG-04": {  # Invoicee
                "name": "Receipee EURL",
                "country_code": "FR",
                "postcode": "69001",
                "city": "Lyon",
                "addr_l1": "42 boulevard de la Croix Rousse",
                "legal_identifier": "528010523",
                "legal_identifier_schemeid": "0002",
            },
            "BG-10": {  # Tax Representative
                "name": "Facto BNP",
                "legal_identifier": "123321123",
                "legal_identifier_schemeid": "0002",
            },
            "BG-11": {  # Tax Representative
                "name": "Société écran",
                "country_code": "FR",
                "vat_identifier": "FR15123456789",
                "postcode": "74210",
                "city": "Seythenex",
                "addr_l1": "1242 route des Caillets",
            },
            "BT-73": datetime.date(2026, 6, 1),
            "BT-74": datetime.date(2026, 6, 30),
            # Incoterms EXT-FR-FE-BG-14
            "EXT-FR-FE-185": "EXW",
            "EXT-FR-FE-186": "Lunel-Viel",
            # Start Ship to
            "BG-13": {
                "name": "Plateforme logistique FastIT",
                "identifiers": {
                    "0009": "63636363200010",
                },
                "country_code": "FR",
                "city": "Carpentras",
                "postcode": "84200",
                "addr_l1": "5 avenue Georges Clémenceau",
                "addr_l2": "ZAC du lac vert",
            },
            "BT-72": datetime.date(2026, 6, 14),
            "BT-81": "30",
            "BT-82": "Virement",
            "BT-83": "Avis de paiement",
            #            "BT-87": "567890",
            #            "BT-88": "Alexis de Lattre",
            "BT-84": "FR2012421242124212421242124",
            "BT-85": "Au bon moulin SARL",
            "BT-86": "QNTOFRP1XXX",
            "BT-89": "RUM_9083209",
            # Payeur EXT-FR-FE-BG-02
            "EXT-FR-FE-BG-02": {
                "name": "Société payeur",
                "country_code": "FR",
                "postcode": "05100",
                "city": "Névache",
                "addr_l1": "Vallée étroite",
                "einvoicing_addr": "754760932",
                "einvoicing_addr_schemeid": "0225",
                "legal_identifier": "754760932",
                "legal_identifier_schemeid": "0002",
            },
            "BT-91": "FR7312345678901275089715A98",
            "BT-90": "FR09ZZZ124299",
            "BG-1": [
                {
                    "BT-21": "AAI",
                    "BT-22": "Ceci est une information générale",
                },
                {
                    "BT-21": "ADN",
                    "BT-22": "B2G",
                },
                {"BT-22": "note sans sujet !"},
                {
                    "BT-21": "PMT",
                    "BT-22": "Indemnité forfaitaire pour frais de recouvrement "
                    "en cas de retard de paiement : 40 €.",
                },
                {
                    "BT-21": "PMD",
                    "BT-22": "Tout retard de paiement engendre une pénalité "
                    "exigible à compter de la date d'échéance, "
                    "calculée sur la base de trois fois le taux d'intérêt légal.",
                },
                {
                    "BT-21": "AAB",
                    "BT-22": "Les réglements reçus avant la date d'échéance "
                    "ne donneront pas lieu à escompte.",
                },
            ],
            "BG-23": [
                {
                    "BT-117": "27.6",
                    "BT-116": "138.00",
                    "BT-118": "S",
                    "BT-119": "20.00",
                },
                {
                    "BT-117": "7.43",
                    "BT-116": "135.00",
                    "BT-118": "S",
                    "BT-119": "5.50",
                },
            ],
            "BT-106": "273.00",
            "BT-107": "5.50",
            "BT-108": "5.50",
            "BT-109": "273.00",
            "BT-110": "35.03",
            #            "BT-110-1": "USD",
            "BT-111": "30.46",
            #            "BT-111-1": "EUR",
            "BT-112": "308.03",
            "BT-113": "100.00",
            "BT-115": "208.03",
            "BG-3": [
                {
                    "BT-25": "F124211",
                    "EXT-FR-FE-02": "386",
                    "BT-26": datetime.date(2025, 12, 30),
                },
                {
                    "BT-25": "F124210",
                    #     'BT-26': datetime.date(2025, 9, 1),
                },
            ],
            "BT-17": ["LOT12", "LOT13"],
            "BT-18": {  # key = BT-18-1: value = BT-18
                "AHK": "EMPL042",
                "AAG": "PROPAL_8890",
            },
            "BG-24": [
                # Only one BT-123 is allowed per BG-24 block
                {
                    "BT-122": "JUSTIF42",
                    # "BT-123": "DOCUMENT_ANNEXE",  # allowed codes in BR-FR-17
                    "BT-124": "https://www.share.com/justif42.pdf",
                },
                {
                    "BT-122": "JUSTIF43",
                    "BT-123": "BON_LIVRAISON",
                    "BT-125": b"code;date;product;qty;uom",
                    "BT-125-1": "text/csv",
                    "BT-125-2": "BL1242.csv",
                },
            ],
            "BG-20": [
                {
                    "BT-92": "3.00",
                    "BT-93": "138.00",
                    "BT-97": "Consigne",
                    "BT-95": "S",
                    "BT-96": "20.00",
                },
                {
                    "BT-92": "2.50",
                    "BT-93": "138.00",
                    "BT-97": "Réduc fidélité",
                    "BT-95": "S",
                    "BT-96": "20.00",
                },
            ],
            "BG-21": [
                {
                    "BT-99": "2.50",
                    "BT-100": "138.00",
                    "BT-104": "Surtaxe carburant",
                    "BT-102": "S",
                    "BT-103": "20.00",
                },
                {
                    "BT-99": "1.00",
                    "BT-102": "S",
                    "BT-103": "20.00",
                    "BT-104": "test BT177",
                    "BT-105": "ADJ",
                },
                {
                    "BT-99": "2.00",
                    "BT-102": "S",
                    "BT-103": "20.00",
                    "BT-104": "test BT177 non VAT Tax",
                    "BT-177": "OTH",
                },
            ],
            "BG-25": [  # Invoice lines
                {
                    "BT-126": "1",
                    "BT-127-00": [
                        {
                            "EXT-FR-FE-183": "AAA",
                            "BT-127": "Olives récoltées exclusivement dans le "
                            "Vaucluse (FR) et pressées au moulin des moines.",
                        },
                        {"EXT-FR-FE-183": "BAO", "BT-127": "Test d'acidité : 7,5."},
                    ],
                    "BT-155": "JOIO50CL",
                    "BT-153": "Huile d'olive Joio 50cl",
                    "BT-157": "3518370900150",
                    "BT-157-1": "0160",
                    "BT-159": "FR",
                    "BT-146": "13.50",
                    "BT-147-00": [
                        {
                            "BT-147": "1.50",
                            "EXT-FR-FE-195": "Négocié spécialement pour cette commande",
                            "EXT-FR-FE-196": "103",
                        }
                    ],
                    "BT-148": "15.00",
                    "BT-149": "1",
                    "BT-150": "C62",
                    "BT-129": "10",
                    "BT-128": {  # key = BT-128-1: value = BT-128
                        "MWB": "XYZ78932",
                    },
                    "BT-130": "C62",
                    "BT-133": "623400",
                    "BT-151": "S",
                    "BT-152": "5.50",
                    "BT-131": "135.00",  # Total HT
                    "BT-132": "PO1242-L1",
                    "BT-134": datetime.date(2026, 6, 14),
                    "BT-135": datetime.date(2026, 6, 15),
                    "EXT-FR-FE-144": "Order-678",
                    "EXT-FR-FE-145": "OrderLine-490",
                    "EXT-FR-FE-135": "PX9021",
                    "BG-32": [  # key = BT-160: value = BT-161
                        {
                            "BT-160": "Couleur",
                            "BT-161": "Vert",
                        },
                        {
                            "BT-160": "Taille",
                            "BT-161": "L",
                        },
                    ],
                    "BT-158": {  # key = BT-158-1, value = {BT-158-2: BT-158}
                        "BB": {
                            "1.0": "LOT1242",
                            "1.1": "LOTAZER",
                            None: "LOTnoVERSION",
                        },
                        "HS": {"2.0": "150920"},
                        "TSP": {None: "15092090"},  # NC8
                    },
                    # TODO see if we switch to generic field names
                    "BG-27": [
                        {
                            "BT-136": "1.50",
                            "BT-139": "test",
                            "BT-140": "95",
                        },
                    ],
                    "BG-28": [
                        {
                            "BT-141": "1.50",
                            "BT-144": "test inverse",
                            "BT-145": "ABL",
                        },
                    ],
                },
                {
                    "BT-126": "2",
                    "BT-127-00": [
                        {
                            "EXT-FR-FE-183": "AAA",
                            "BT-127": "Nougat préparé par les moines et les "
                            "moniales du Barroux (FR)",
                        }
                    ],
                    "BT-155": "NOUGATCUBES",
                    "BT-156": "KUB_NOUGAT",
                    "BT-153": "Nougats en cubes",
                    "BT-154": "Nougat de Provence découpés en petits cubes de la "
                    "taille d'un bonbon",
                    "BT-157": "3518370400049",
                    "BT-157-1": "0160",
                    "BT-159": "FR",
                    "BT-146": "6.90",
                    "BT-147-00": [
                        {
                            "BT-147": "1.05",
                            "EXT-FR-FE-195": "Comme indiqué dans le contrat",
                            "EXT-FR-FE-196": "104",
                        }
                    ],
                    "BT-148": "7.95",
                    "BT-149": "1",
                    "BT-150": "C62",
                    "BT-128": {  # key = BT-128-1: value = BT-128
                        "MWB": "AWB129871",
                    },
                    "BT-129": "20",
                    "BT-130": "C62",
                    "BT-133": "623400",
                    "BT-151": "S",
                    "BT-152": "20.00",
                    "BT-131": "138.00",  # Total HT
                    "BT-132": "PO1242-L2",
                    "EXT-FR-FE-135": "PO982749",
                    "EXT-FR-FE-140": "BL0982432",
                    "EXT-FR-FE-141": "AVIS9074398",
                    "EXT-FR-FE-BG-10": {
                        "name": "Alpes du Sud Logistique",
                        "postcode": "05600",
                        "addr_l1": "12 rue de Vanban",
                        "city": "Eygliers",
                        "country_code": "FR",
                    },
                    # ref to previous invoice
                    "EXT-FR-FE-136": "F824739",
                    "EXT-FR-FE-139": "12",
                    "EXT-FR-FE-137": "380",
                    "EXT-FR-FE-138": datetime.date(2025, 12, 24),
                },
            ],
        }
        return data_dict

    def _check_data_in_xml(self, data_dict, xml_str, flavor="factur-x"):
        if isinstance(data_dict, dict):
            for key, value in data_dict.items():
                if isinstance(value, str):
                    if (
                        isinstance(key, str)
                        and not key.endswith("-0")
                        and key != "BT-8"
                    ):
                        self.assertIn(value, xml_str)
                elif isinstance(value, datetime.date):
                    if flavor == "factur-x":
                        value_str = value.strftime("%Y%m%d")
                    elif flavor == "ubl-2.1":
                        value_str = value.strftime("%Y-%m-%d")
                    self.assertIn(value_str, xml_str)
                else:
                    self._check_data_in_xml(data_dict[key], xml_str, flavor=flavor)
        elif isinstance(data_dict, list):
            for item in data_dict:
                self._check_data_in_xml(item, xml_str, flavor=flavor)

    def test_generate_and_parse_xml(self):
        # I need to re-generate data_dict before every call to generate_cii_xml()
        # because generate_xml modifies data_dict
        for flavor in ("factur-x", "ubl-2.1"):
            for level in FLAVOR2LEVELS[flavor]:
                for bt3 in ("380", "381"):
                    data_dict = self._prepare_data_dict()
                    data_dict["BT-3"] = bt3
                    xml_bytes = generate_xml(
                        data_dict,
                        flavor=flavor,
                        level=level,
                        check_schematron="fr-ctc",
                        prefixed_namespaces=True,
                    )
                    xml_str = xml_bytes.decode("utf-8")
                    # pprint(data_dict)
                    # pprint(xml_str)
                    self._check_data_in_xml(data_dict, xml_str, flavor=flavor)
                    parsed_data_dict = parse_ubl_cii_xml(xml_bytes, check_xsd=False)
                    # pprint(parsed_data_dict)
                    if parsed_data_dict != data_dict:
                        # diff = DeepDiff(data_dict, parsed_data_dict)
                        # pprint(diff)
                        self.assertFalse(
                            "Parsed parsed_data_dict is different than data_dict"
                        )

    def test_generate_and_parse_xml_json(self):
        # I need to re-generate data_dict before every call to generate_cii_xml()
        # because generate_xml modifies data_dict
        for flavor in ("factur-x", "ubl-2.1"):
            for level in FLAVOR2LEVELS[flavor]:
                for bt3 in ("380", "381"):
                    data_dict = self._prepare_data_dict()
                    data_dict["BT-3"] = bt3
                    if bt3 == "381":
                        self.assertTrue(is_credit_note(data_dict))
                    else:
                        self.assertFalse(is_credit_note(data_dict))
                    json_str = data_dict_to_json(data_dict)
                    data_dict_from_json = json.loads(json_str)
                    xml_bytes = generate_xml(
                        data_dict_from_json,
                        flavor=flavor,
                        level=level,
                        check_schematron="fr-ctc",
                        prefixed_namespaces=True,
                    )
                    # xml_str = xml_bytes.decode("utf-8")
                    # pprint(xml_str)
                    parsed_data_dict = parse_ubl_cii_xml(
                        xml_bytes,
                        check_xsd=False,
                        float_as="string",
                    )
                    # pprint(parsed_data_dict)
                    if data_dict_from_json != parsed_data_dict:
                        # diff = DeepDiff(data_dict_from_json, parsed_data_dict)
                        # pprint(diff)
                        self.assertFalse(
                            "Parsed parsed_json_str is different than json_str"
                        )
                    parsed_json_str = data_dict_to_json(parsed_data_dict)
                    self.assertTrue(isinstance(parsed_json_str, str))

    def test_generate_xml_level_autodetect(self):
        # test common formats
        for bt24 in (
            "urn:cen.eu:en16931:2017",
            "urn:cen.eu:en16931:2017#conformant#urn.cpro.gouv.fr:1p0:extended-ctc-fr",
        ):
            for flavor in ("factur-x", "ubl-2.1"):
                data_dict = self._prepare_data_dict()
                data_dict["BT-24"] = bt24
                generate_xml(data_dict, flavor=flavor)  # autodetect
        with self.assertRaises(ValueError):
            data_dict = self._prepare_data_dict()
            data_dict["BT-24"] = "urn:factur-x.eu:1p0:basicwl"
            generate_xml(data_dict, flavor="ubl-2.1")
