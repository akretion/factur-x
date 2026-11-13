# Copyright 2026 Akretion (https://www.akretion.com).

import unittest
from types import SimpleNamespace
from unittest.mock import patch

from facturx import xml_check_schematron

SVRL_NS = "http://purl.oclc.org/dsdl/svrl"


class TestSchematronWarnings(unittest.TestCase):
    def _response(self, assertion):
        return SimpleNamespace(
            status_code=200,
            text=(
                f'<svrl:schematron-output xmlns:svrl="{SVRL_NS}">'
                f"{assertion}"
                "</svrl:schematron-output>"
            ),
        )

    @patch("facturx.facturx.requests.post")
    def test_warning_does_not_invalidate_xml(self, post):
        post.return_value = self._response(
            '<svrl:failed-assert flag="warning" location="/Invoice/Warning">'
            "<svrl:text>synthetic warning</svrl:text>"
            "</svrl:failed-assert>"
        )

        with self.assertLogs("factur-x", level="WARNING") as logs:
            self.assertTrue(
                xml_check_schematron("<Invoice/>", flavor="order-x", level="basic")
            )

        log_output = "\n".join(logs.output)
        self.assertIn("synthetic warning", log_output)
        self.assertIn("Warning location: /Invoice/Warning", log_output)
        post.assert_called_once()

    @patch("facturx.facturx.requests.post")
    def test_fatal_assertion_still_invalidates_xml(self, post):
        post.return_value = self._response(
            '<svrl:failed-assert flag="fatal">'
            "<svrl:text>synthetic fatal error</svrl:text>"
            "</svrl:failed-assert>"
        )

        with self.assertRaisesRegex(Exception, "synthetic fatal error"):
            xml_check_schematron("<Invoice/>", flavor="order-x", level="basic")
        post.assert_called_once()
