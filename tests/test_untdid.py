# Copyright 2026 Akretion (https://www.akretion.com).
# @author Sébastien BEAU <sebastien.beau@akretion.com>

import unittest

from facturx import (
    untdid4461_to_text_code,
    untdid_get_label,
)


class TestUnitdid(unittest.TestCase):
    def test_untdid(self):
        self.assertFalse(untdid_get_label("4451", None))
        label = untdid_get_label("4451", " ZZZ ")
        self.assertEqual(label, "Mutually defined")
        label = untdid_get_label("4451", "WRONGCODE")
        self.assertEqual(label, None)
        label = untdid_get_label("5189", "30 ")
        self.assertEqual(label, "Bank charges")
        label_int = untdid_get_label("5189", 30)
        self.assertEqual(label, label_int)
        label = untdid_get_label("7161", "rac")
        self.assertEqual(label, "Repair")

    def test_untdid4461_to_text_code(self):
        self.assertEqual(untdid4461_to_text_code("58"), "credit_transfer")
        self.assertEqual(untdid4461_to_text_code(49), "direct_debit")
        self.assertFalse(untdid4461_to_text_code("1242"))
