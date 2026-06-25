# Copyright 2026 Akretion (https://www.akretion.com).
# @author Sébastien BEAU <sebastien.beau@akretion.com>

import os
import unittest

from facturx import get_xml_from_pdf

current_dir = os.path.dirname(os.path.abspath(__file__))


class TestAPI(unittest.TestCase):
    def test_extraction(self):
        path_file = os.path.join(current_dir, "fixtures/pdf/invoice_EN16931.pdf")
        with open(path_file, "rb") as pdf_file:
            get_xml_from_pdf(pdf_file, check_xsd=True, check_schematron=True)
