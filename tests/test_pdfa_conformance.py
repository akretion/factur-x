import os
import zlib
import unittest
from pypdf import PdfReader
from io import BytesIO
from facturx import generate_from_binary
from lxml import etree

PDFA_NS = {
    "pdfaid": "http://www.aiim.org/pdfa/ns/id/",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
}

FIXTURES_DIR = os.path.join(os.path.dirname(__file__), "fixtures")
PDF_FIXTURES_DIR = os.path.join(FIXTURES_DIR, "pdf")
XML_FIXTURES_DIR = os.path.join(FIXTURES_DIR, "xml")

MINIMUM_XML_PATH = os.path.join(XML_FIXTURES_DIR, "factur-x-minimum.xml")
# PDF/A-3a source
# Source: reflowPDF
# https://reflowpdf.com/samples/report-pdfa3a.pdf
PDFA3A_SOURCE_PATH = os.path.join(PDF_FIXTURES_DIR, "pdfa3a.pdf")
PDFA3B_SOURCE_PATH = os.path.join(PDF_FIXTURES_DIR, "invoice_EN16931.pdf")
# Plain PDF with no PDF/A metadata
# Based on the veraPDF PDF/A-3b test corpus
# https://github.com/veraPDF/veraPDF-corpus/tree/staging/PDF_A-3b/
PLAIN_PDF_NO_PDFA_PATH = os.path.join(PDF_FIXTURES_DIR, "plain.pdf")


def _read_bytes(path):
    with open(path, "rb") as f:
        return f.read()


def _get_xmp_conformance(pdf_bytes):
    """A small test utility: reads the XMP data from the output PDF via pypdf 
    and returns (share, compliance)"""
    reader = PdfReader(BytesIO(pdf_bytes))
    metadata_obj = reader.trailer["/Root"]["/Metadata"].get_object()
    xmp_bytes = metadata_obj.get_data()
    root = etree.fromstring(xmp_bytes)
    part = root.xpath("//pdfaid:part", namespaces=PDFA_NS)[0].text
    conformance = root.xpath("//pdfaid:conformance", namespaces=PDFA_NS)[0].text
    return part, conformance


def _patch_xmp_conformance_letter(data, old, new):
    start = data.find(b"stream\n", data.find(b"/Metadata"))
    end = data.find(b"endstream", start)
    if start == -1 or end == -1:
        raise AssertionError("Could not find the XMP stream")
    compressed_xmp = data[start + len(b"stream\n"):end]
    xmp = zlib.decompress(compressed_xmp)
    old_tag = f"<pdfaid:conformance>{old}</pdfaid:conformance>".encode()
    new_tag = f"<pdfaid:conformance>{new}</pdfaid:conformance>".encode()
    if old_tag not in xmp:
        raise AssertionError(
            f"Fixture PDF does not contain the expected "
            f"pdfaid:conformance={old} tag in its raw bytes: "
            f"is this really an uncompressed-XMP PDF/A-3{old.lower()} file?"
        )
    patched_xmp = xmp.replace(old_tag, new_tag, 1)
    compressed_patched_xmp = zlib.compress(patched_xmp)
    return (
        data[:start] 
        + compressed_patched_xmp 
        + data[end:]
    )


class PdfaConformancePreserveTestCase(unittest.TestCase):
    """Nominal scenario: preserving a conformance level that is genuinely
    verified as opposed to blindly trusted"""

    @classmethod
    def setUpClass(cls):
        cls.minimum_xml_bytes = _read_bytes(MINIMUM_XML_PATH)

    def test_preserve_from_genuinely_tagged_pdfa3a_source(self):
        """
        Full nominal case (your WeasyPrint reproduction): a source PDF
        that is GENUINELY tagged (non-empty StructTreeRoot,
        MarkInfo/Marked=true, declared Lang, fonts with /ToUnicode) and
        whose XMP honestly declares conformance=A.
 
        The structural verification must confirm level A here, not
        reject it — this is the counterpart to the anti-spoofing tests
        below: a legitimate claim should never be downgraded
        """
        source_bytes = _read_bytes(PDFA3A_SOURCE_PATH)
        result = generate_from_binary(source_bytes, self.minimum_xml_bytes)
        part, conformance = _get_xmp_conformance(result)
        self.assertEqual(part, "3")
        self.assertEqual(conformance, "A")


    def test_default_fallback_to_b_without_pdf_metadata(self):
        """If there is no PDF/A metadata in the source: behaviour remains the same as before
        (no regression)."""
        source_bytes = _read_bytes(PLAIN_PDF_NO_PDFA_PATH)
        result = generate_from_binary(source_bytes, self.minimum_xml_bytes)
        _, conformance = _get_xmp_conformance(result)
        self.assertEqual(conformance, "B")


class PdfaConformanceAntiSpoofingTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.minimum_xml_bytes = _read_bytes(MINIMUM_XML_PATH)
        cls.pdfa3b_source_bytes = _read_bytes(PDFA3B_SOURCE_PATH)

    def test_rejects_forged_declared_a_on_untagged_pdfa3b_source(self):
        """
        Key scenario reported by the user: a source PDF that is
        ACTUALLY PDF/A-3b (untagged, no StructTreeRoot) but whose
        XMP has been manually edited to DECLARE pdfaid:conformance=A without
        the document structure matching this.

        factur-x must NOT blindly copy this declaration: the
        structural validation must detect the absence of /StructTreeRoot
        / /MarkInfo / /Lang and return "B", not "A"
        """
        forged_bytes = _patch_xmp_conformance_letter(
            self.pdfa3b_source_bytes, old="B", new="A"
        )
        result = generate_from_binary(forged_bytes, self.minimum_xml_bytes)
        _, conformance = _get_xmp_conformance(result)
        self.assertEqual(
            conformance,
            "B",
            "The falsified declaration “A” was not detected: the "
            "output document claims to be accessible when in fact it is not."
        )

    def test_explicit_override_intentionally_skips_verification(self):
        """
        An explicit pdfa_conformance (“A”) is NOT structurally validated
        this is a deliberate and documented choice by the caller, not the
        “preserve” value. This test documents this intentional limitation: forcing
        “A” on an untagged PDF does indeed produce “A” as output (at the
        caller own risk), unlike “preserve”, which would have rejected it
        """
        result = generate_from_binary(
            self.pdfa3b_source_bytes,
            self.minimum_xml_bytes,
            pdfa_conformance="A"
        )
        _, conformance = _get_xmp_conformance(result)
        self.assertEqual(conformance, "A")


class PdfaConformanceValidatorHookTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.minimum_xml_bytes = _read_bytes(MINIMUM_XML_PATH)
        cls.pdfa3a_tagged_source_bytes = _read_bytes(PDFA3A_SOURCE_PATH)

    def test_pdfa_validator_hook_takes_priority_over_heuristic(self):
        """
        When an external pdfa_validator is provided (e.g the veraPDF wrapper), its
        response takes precedence over the internal heuristic but may
        never exceed the level specified in the source
        """
        calls=[]
        def fake_validator(pdf_writer):
            calls.append(pdf_writer)
            return "B"
        result = generate_from_binary(
            self.pdfa3a_tagged_source_bytes,
            self.minimum_xml_bytes,
            pdfa_validator=fake_validator,
        )
        _, conformance = _get_xmp_conformance(result)
        self.assertEqual(conformance, "B")
        self.assertEqual(len(calls), 1)


class PdfaConformanceArgumentValidationTestCase(unittest.TestCase):
    """Public argument validation, fail fast behaviour"""

    @classmethod
    def setUpClass(cls):
        cls.minimum_xml_bytes = _read_bytes(MINIMUM_XML_PATH)
        cls.plain_pdf_bytes = _read_bytes(PLAIN_PDF_NO_PDFA_PATH)

    def test_invalid_pdfa_conformance_value_raises(self):
        """An unrecognized pdfa_conformance value must raise a ValueError
        instead of silently falling back to a default"""
        with self.assertRaises(ValueError):
            generate_from_binary(
                self.plain_pdf_bytes,
                self.minimum_xml_bytes,
                pdfa_conformance="Z",
            )

    def test_non_callable_pdfa_validator_raises(self):
        """A non-callable pdfa_validator must raise a ValueError right
        away, instead of failing later with a confusing TypeError once
        factur-x actually tries to call it"""
        with self.assertRaises(ValueError):
            generate_from_binary(
                self.plain_pdf_bytes,
                self.minimum_xml_bytes,
                pdfa_validator="not_a_callable",
            )


if __name__ == "__main__":
    unittest.main()
