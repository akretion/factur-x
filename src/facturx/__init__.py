import logging

__version__ = "7.0"
from .facturx import (
    facturx_schematron_get_codedb_xml_file,
    generate_from_binary,
    generate_from_file,
    get_facturx_level,
    get_facturx_xml_from_pdf,
    get_flavor,
    get_level,
    get_orderx_type,
    get_orderx_xml_from_pdf,
    get_xml_from_pdf,
    get_xml_namespaces,
    xml_check_schematron,
    xml_check_xsd,
)
from .generate_xml import generate_cii_xml, generate_ubl_xml, generate_xml
from .parse_xml import parse_ubl_cii_xml, parse_ubl_cii_xml_to_json

__all__ = [
    "generate_from_binary",
    "generate_from_file",
    "get_facturx_level",
    "get_facturx_xml_from_pdf",
    "get_flavor",
    "get_level",
    "get_orderx_type",
    "get_orderx_xml_from_pdf",
    "get_xml_from_pdf",
    "get_xml_namespaces",
    "facturx_schematron_get_codedb_xml_file",
    "xml_check_schematron",
    "xml_check_xsd",
    "generate_xml",
    "generate_cii_xml",
    "generate_ubl_xml",
    "parse_ubl_cii_xml",
    "parse_ubl_cii_xml_to_json",
]

logging.getLogger("factur-x").addHandler(logging.NullHandler())


def configure_script_logging(level=logging.INFO):
    logger = logging.getLogger("factur-x")
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    logger.addHandler(handler)
    logger.setLevel(level)
