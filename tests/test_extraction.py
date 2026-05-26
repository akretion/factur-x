# Copyright 2026 Akretion (https://www.akretion.com).
# @author Sébastien BEAU <sebastien.beau@akretion.com>
# License AGPL-3.0 or later (https://www.gnu.org/licenses/agpl).

import unittest

from facturx import get_xml_from_pdf


class TestAPI(unittest.TestCase):
    def test_extraction():
        with open("../fixtures/invoice_EN16931.pdf", "rb") as pdf_file:
            xml_bytes = get_xml_from_pdf(
                pdf_file, check_xsd=False, check_schematron=False
            )
        assert xml_bytes is not None
        assert isinstance(xml_bytes, bytes)
        assert len(xml_bytes) > 0
