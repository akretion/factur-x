# Copyright 2026 Akretion (https://www.akretion.com).
# @author Sébastien BEAU <sebastien.beau@akretion.com>

import os
import unittest

from facturx import get_flavor, get_level, get_xml_from_pdf
from lxml import etree

current_dir = os.path.dirname(os.path.abspath(__file__))


class TestAPI(unittest.TestCase):
    def test_extraction(self):
        path_file = os.path.join(current_dir, "fixtures/pdf/invoice_EN16931.pdf")
        with open(path_file, "rb") as pdf_file:
            get_xml_from_pdf(pdf_file, check_xsd=True, check_schematron=True)

    def test_get_flavor_and_level(self):
        files2flavor_level = {
            "factur-x-minimum.xml": ("factur-x", "minimum"),
            "factur-x-basicwl.xml": ("factur-x", "basicwl"),
            "factur-x-basic.xml": ("factur-x", "basic"),
            "factur-x-en16931.xml": ("factur-x", "en16931"),
            "factur-x-extended.xml": ("factur-x", "extended"),
            "zugferd-basic.xml": ("zugferd", "basic"),
            "zugferd-comfort.xml": ("zugferd", "comfort"),
            "zugferd-extended.xml": ("zugferd", "extended"),
            "order-x-basic.xml": ("order-x", "basic"),
            "order-x-comfort.xml": ("order-x", "comfort"),
            "ubl-21-en16931.xml": ("ubl-2.1", "en16931"),
            "ubl-21-extended-ctc-fr.xml": ("ubl-2.1", "extended-ctc-fr"),
        }
        for filename, (flavor, level) in files2flavor_level.items():
            test_file_path = os.path.join(current_dir, f"fixtures/xml/{filename}")
            with open(test_file_path, "rb") as xml_file:
                xml_bytes = xml_file.read()
                xml_root = etree.fromstring(xml_bytes)
                flavor_detected = get_flavor(xml_root)
                self.assertEqual(flavor, flavor_detected)
                level_detected = get_level(xml_root, flavor=flavor)
                self.assertEqual(level, level_detected)
