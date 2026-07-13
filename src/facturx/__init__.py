import logging

__version__ = "6.3"
from .facturx import (
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
    "xml_check_schematron",
    "xml_check_xsd",
    "generate_xml",
    "generate_cii_xml",
    "generate_ubl_xml",
]

logging.getLogger("factur-x").addHandler(logging.NullHandler())


def configure_script_logging(level=logging.INFO):
    logger = logging.getLogger("factur-x")
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    logger.addHandler(handler)
    logger.setLevel(level)
