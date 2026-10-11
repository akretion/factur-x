import os
from datetime import datetime, timedelta, timezone
from io import BytesIO
from pathlib import Path

import pytest
from lxml import etree
from pypdf import PdfReader, PdfWriter

from facturx import facturx


@pytest.mark.parametrize(
    ("date", "expected"),
    [
        (
            datetime(
                2026,
                1,
                1,
                0,
                15,
                tzinfo=timezone(timedelta(hours=5, minutes=45)),
            ),
            "D:20251231183000+00'00'",
        ),
        (
            datetime(
                2026,
                12,
                31,
                23,
                15,
                tzinfo=timezone(timedelta(hours=-3, minutes=-30)),
            ),
            "D:20270101024500+00'00'",
        ),
        (
            datetime(2026, 6, 17, 14, 1, 22, tzinfo=timezone(timedelta(hours=2))),
            "D:20260617120122+00'00'",
        ),
        (
            datetime(2026, 6, 17, 14, 1, 22, tzinfo=timezone.utc),
            "D:20260617140122+00'00'",
        ),
    ],
)
def test_pdf_timestamp_preserves_instant(date, expected):
    timestamp = facturx._get_pdf_timestamp(date)

    assert timestamp == expected
    parsed = datetime.strptime(timestamp, "D:%Y%m%d%H%M%S+00'00'")
    assert parsed.replace(tzinfo=timezone.utc) == date


def test_naive_pdf_timestamp_retains_utc_assumption():
    date = datetime(2026, 6, 17, 14, 1, 22)

    assert facturx._get_pdf_timestamp(date) == "D:20260617140122+00'00'"


@pytest.fixture
def non_utc_clock(monkeypatch):
    instant = datetime(2026, 12, 31, 23, 30, 12, tzinfo=timezone.utc)
    local_zone = timezone(timedelta(hours=2))

    class FrozenDatetime(datetime):
        @classmethod
        def now(cls, tz=None):
            if tz is None:
                return instant.astimezone(local_zone).replace(tzinfo=None)
            return instant.astimezone(tz)

        @classmethod
        def fromtimestamp(cls, timestamp, tz=None):
            if tz is None:
                return super().fromtimestamp(timestamp, local_zone).replace(tzinfo=None)
            return super().fromtimestamp(timestamp, tz)

    monkeypatch.setattr(facturx, "datetime", FrozenDatetime)
    return instant


def test_default_pdf_timestamp_uses_utc(non_utc_clock):
    assert facturx._get_pdf_timestamp() == "D:20261231233012+00'00'"


def test_xmp_timestamp_uses_utc(non_utc_clock):
    timestamp = facturx._get_metadata_timestamp()

    assert timestamp == "2026-12-31T23:30:12+00:00"
    assert datetime.fromisoformat(timestamp) == non_utc_clock


def test_pdf_and_xmp_metadata_represent_same_instant(non_utc_clock):
    info = facturx._prepare_pdf_metadata_txt({})
    xmp = etree.fromstring(
        facturx._prepare_pdf_metadata_xml("factur-x", "basic", None, {})
    )
    namespaces = {"xmp": "http://ns.adobe.com/xap/1.0/"}

    assert info["/CreationDate"] == "D:20261231233012+00'00'"
    assert info["/ModDate"] == info["/CreationDate"]
    for field in ("CreateDate", "ModifyDate"):
        timestamp = xmp.find(f".//xmp:{field}", namespaces).text
        assert datetime.fromisoformat(timestamp) == non_utc_clock


def test_attachment_timestamps_preserve_instants():
    created = datetime(
        2026, 1, 1, 0, 15, tzinfo=timezone(timedelta(hours=5, minutes=45))
    )
    modified = datetime(
        2026, 12, 31, 23, 15, tzinfo=timezone(timedelta(hours=-3, minutes=-30))
    )
    attachments = {}
    facturx._filespec_additional_attachments(
        PdfWriter(),
        attachments,
        {
            "filedata": b"receipt",
            "creation_datetime": created,
            "modification_datetime": modified,
        },
        "receipt.txt",
    )
    file_spec = attachments["receipt.txt"].get_object()
    params = file_spec["/EF"]["/F"]["/Params"]

    assert params["/CreationDate"] == "D:20251231183000+00'00'"
    assert params["/ModDate"] == "D:20270101024500+00'00'"


def test_file_attachment_modification_time_uses_utc(tmp_path, non_utc_clock):
    receipt = tmp_path / "receipt.txt"
    receipt.write_bytes(b"receipt")
    os.utime(receipt, (non_utc_clock.timestamp(), non_utc_clock.timestamp()))
    pdf = BytesIO()
    writer = PdfWriter()
    writer.add_blank_page(width=100, height=100)
    writer.write(pdf)
    xml = Path(__file__).parent / "fixtures/xml/factur-x-minimum.xml"

    facturx.generate_from_file(
        pdf,
        str(xml),
        flavor="factur-x",
        level="minimum",
        check_xsd=False,
        check_schematron=False,
        pdf_metadata={},
        attachments={"receipt.txt": {"filepath": str(receipt)}},
    )
    reader = PdfReader(pdf)
    names = reader.trailer["/Root"]["/Names"]["/EmbeddedFiles"]["/Names"]
    file_spec = names[names.index("receipt.txt") + 1].get_object()
    params = file_spec["/EF"]["/F"]["/Params"]

    assert params["/ModDate"] == "D:20261231233012+00'00'"
