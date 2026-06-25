# Copyright 2026 Akretion France (https://www.akretion.com).
# @author: Alexis de Lattre <alexis.delattre@akretion.com>

import unittest
from datetime import datetime

from facturx import generate_cii_xml, generate_ubl_xml


class TestGenerateXML(unittest.TestCase):
    def _prepare_data_dict(self):
        date_fmt = "%Y-%m-%d"
        data_dict = {
            "BT-1": "F124212",
            "BT-2": datetime.strptime("2026-06-17", date_fmt),
            "BT-3": "380",
            "BT-5": "EUR",
            #            'BT-6': "EUR",
            # for BT-8, as the values are different in UBL and CII
            # we use a codification: 'invoice', 'delivery' or 'payment'
            "BT-8": "invoice",
            "BT-9": datetime.strptime("2026-07-16", date_fmt),
            "BT-10": "120943",
            "BT-11": "Projet_Zorro",
            "BT-11-0": "Super Projet",
            "BT-12": "Contrat_du_siècle",
            "BT-13": "PO1242",
            "BT-14": "DEVIS2093",
            "BT-15": "BR-2026/06/42",
            "BT-16": "BL-2026/05/12",
            "BT-19": "401HOF",
            "BT-20": "30 jours net",
            "BT-23": "S1",
            # START Seller
            "BT-27": "Au bon moulin",
            "BT-28": "L'huile d'olive en folie",
            "BT-29": {
                # key = schemeID, value = GlobalID value
                # if not key: value = ID
                #                None: 'REF_SELLER',
                "0009": "99999999800019",
                "0224": "Code_ROUTAGE_seller",
            },
            "BT-30": "999999998",
            "BT-30-1": "0002",
            "BT-31": "FR11999999998",
            "BT-32": "DGFIP_ref_1242",
            "BT-34": "999999998_042",
            "BT-34-1": "0225",
            "BT-35": "1242 chemin de l'olive",
            "BT-36": "Lieu dit des senteurs",
            "BT-162": "ZAC du Mont Ventoux",
            "BT-37": "Malaucène",
            "BT-38": "84340",
            "BT-39": "Vaucluse",
            "BT-40": "FR",
            "BT-41": "M. Rémi Dupont",
            "BT-42": "+33 6 12 42 12 42",
            "BT-43": "commercial@aubonmoulin.com",
            # START Buyer
            "BT-44": "Ma jolie boutique SARL",
            "BT-45": "Ma jolie Trading Brand",
            "BT-46": {
                # for buyer: either ID (key None) or GlobalID, not both
                #                None: "REF_BUYER",
                "0009": "78787878400018",
                # TODO FX schematron doesn't allow multiple schemes for buyer
                # but it allows that for seller... I don't understand this !
                #                "0224": 'code_routage_buyer',
            },
            "BT-47": "787878784",
            "BT-47-1": "0002",
            "BT-48": "FR19787878784",
            "BT-49": "787878784",
            "BT-49-1": "0225",
            "BT-50": "35 rue de la République",
            "BT-51": "La presqu'île",
            "BT-52": "Lyon",
            "BT-53": "69001",
            "BT-54": "Rhône",
            "BT-55": "FR",
            # either personName (BT-56) OR DepartmentName (BT-56-0), not both
            "BT-56": "Mme Laëtitia Durand",
            "BT-57": "+33 7 42 12 42 12",
            "BT-58": "laetita.durand@jolieboutique.com",
            # End Buyer
            "BT-X-335": "M. Rémi Agent",
            # Start Tax Representative
            "BT-62": "Société écran",
            "BT-69": "FR",
            "BT-63": "FR15123456789",
            "BT-73": datetime.strptime("2026-06-01", date_fmt),
            "BT-74": datetime.strptime("2026-06-30", date_fmt),
            # Start Ship to
            "BT-70": "Plateforme logistique FastIT",
            "BT-71": {
                "0009": "63636363200010",
            },
            "BT-80": "FR",
            "BT-77": "Carpentras",
            "BT-78": "84200",
            "BT-75": "5 avenue Georges Clémenceau",
            "BT-72": datetime.strptime("2026-06-14", date_fmt),
            "BT-83": datetime.strptime("2026-06-17", date_fmt),
            "BT-81": "30",
            "BT-82": "Libellé du moyen de paiement",
            #            "BT-87": "567890",
            #            "BT-88": "Alexis de Lattre",
            "BT-84": "FR2012421242124212421242124",
            "BT-85": "Au bon moulin SARL",
            "BT-86": "QNTOFRP1XXX",
            "BT-90": "Au bon moulin SARL",
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
                    "BT-117-1": "EUR",  # TODO
                    "BT-116": "138.00",
                    "BT-116-1": "EUR",  # TODO
                    "BT-118": "S",
                    "BT-119": "20.00",
                },
                {
                    "BT-117": "7.43",
                    "BT-117-1": "EUR",  # TODO
                    "BT-116": "135.00",
                    "BT-116-1": "EUR",  # TODO
                    "BT-118": "S",
                    "BT-119": "5.50",
                },
            ],
            "BT-106": "273.00",
            "BT-107": "5.50",
            "BT-108": "5.50",
            "BT-109": "273.00",
            "BT-111": "35.03",
            "BT-111-1": "EUR",
            "BT-112": "308.03",
            "BT-113": "100.00",
            "BT-115": "208.03",
            "BG-3": [
                {
                    "BT-25": "F124211",
                    "BT-26": datetime.strptime("2025-12-30", date_fmt),
                },
                {
                    "BT-25": "F124210",
                    #     'BT-26': datetime.strptime("2025-09-01", date_fmt),
                },
            ],
            "BT-17": "LOT12",
            "BT-18-00": {  # key = BT-18-1: value = BT-18
                "AHK": "EMPL042",
                "AHO": "Chamber0823",
            },
            "BG-24": [
                {
                    "BT-122": "JUSTIF42",
                    "BT-123": "DOCUMENT_ANNEXE",  # allowed codes in BR-FR-17
                    "BT-124": "https://www.share.com/justif42.pdf",
                },
                {
                    "BT-122": "JUSTIF43",
                    "BT-123": "BON_LIVRAISON",
                    "BT-124": "https://www.share.com/justif43.pdf",
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
                    "BT-99": "5.50",
                    "BT-100": "138.00",
                    "BT-104": "Surtaxe carburant",
                    "BT-102": "S",
                    "BT-103": "20.00",
                }
            ],
            "BG-25": [  # Invoice lines
                {
                    "BT-126": "1",
                    "BT-127": "Olives récoltées exclusivement dans le Vaucluse (FR)",
                    "BT-155": "JOIO50CL",
                    "BT-153": "Huile d'olive Joio 50cl",
                    "BT-157": "3518370900150",
                    "BT-157-1": "0160",
                    "BT-159": "FR",
                    "BT-146": "13.50",
                    "BT-147": "1.50",
                    "BT-148": "15.00",
                    "BT-129": "10",
                    "BT-130": "C62",
                    "BT-133": "623400",
                    "BT-151": "S",
                    "BT-152": "5.50",
                    "BT-131": "135.00",  # Total HT
                    "BT-134": datetime.strptime("2026-06-14", date_fmt),
                    "BT-135": datetime.strptime("2026-06-15", date_fmt),
                    "BG-32": {  # key = BT-160: value = BT-161
                        "Couleur": "Vert",
                        "Taille": "L",
                    },
                    "BT-158-00": {  # key = (BT-158-1, BT-158-2): value = BT-158
                        ("BB", None): "LOT1242",
                        ("HS", "NC8"): "15092000",
                    },
                    "BG-27": [
                        {
                            "BT-136": "1.50",
                            "BT-139": "test",
                        },
                    ],
                    "BG-28": [
                        {
                            "BT-141": "1.50",
                            "BT-144": "test inverse",
                        },
                    ],
                },
                {
                    "BT-126": "2",
                    "BT-127": "Nougat préparé par les moines et les "
                    "moniales du Barroux (FR)",
                    "BT-155": "NOUGATCUBES",
                    "BT-153": "Nougats en cubes",
                    "BT-157": "3518370400049",
                    "BT-157-1": "0160",
                    "BT-159": "FR",
                    "BT-146": "6.90",
                    "BT-147": "1.05",
                    "BT-148": "7.95",
                    "BT-128-00": {  # key = BT-128-1: value = BT-128
                        "MWB": "AWB129871",
                    },
                    "BT-129": "20",
                    "BT-130": "C62",
                    "BT-133": "623400",
                    "BT-151": "S",
                    "BT-152": "20.00",
                    "BT-131": "138.00",  # Total HT
                },
            ],
        }
        return data_dict

    def test_generate_cii_xml(self):
        # I need to re-generate data_dict before every call to generate_cii_xml()
        # because generate_cii_xml modifies data_dict
        data_dict = self._prepare_data_dict()
        # bug in specific extended sch ?
        data_dict["BT-18-00"].pop("AHO")
        _xml_bytes = generate_cii_xml(
            data_dict, level="extended", check_schematron="fr-ctc"
        )
        data_dict = self._prepare_data_dict()
        _xml_bytes = generate_cii_xml(
            data_dict, level="en16931", check_schematron="fr-ctc"
        )
        data_dict = self._prepare_data_dict()
        _xml_bytes = generate_cii_xml(
            data_dict, level="basicwl", check_schematron="fr-ctc"
        )
        data_dict = self._prepare_data_dict()
        data_dict["BT-18-00"].pop("AHO")  # bug in schematron ?
        _xml_bytes = generate_cii_xml(
            data_dict, level="extended-ctc-fr", check_schematron="fr-ctc"
        )

    def test_generate_ubl(self):
        data_dict = self._prepare_data_dict()
        data_dict["BT-18-00"].pop("AHO")
        # To avoid schematron bug https://github.com/fnfempe/France_RFE/issues/1
        data_dict.pop("BG-24")
        _xml_bytes = generate_ubl_xml(
            data_dict, level="en16931", check_schematron="fr-ctc"
        )
        data_dict = self._prepare_data_dict()
        data_dict["BT-18-00"].pop("AHO")
        # To avoid schematron bug https://github.com/fnfempe/France_RFE/issues/1
        data_dict.pop("BG-24")
        _xml_bytes = generate_ubl_xml(
            data_dict, level="extended-ctc-fr", check_schematron="fr-ctc"
        )
