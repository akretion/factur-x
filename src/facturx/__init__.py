import logging

__version__ = "7.5"
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
from .generate_xml import (
    generate_cii_xml,
    generate_ubl_xml,
    generate_xml,
    get_data_dict_copy_for_logs,
    is_credit_note,
    preprocess_data_dict,
)
from .parse_xml import data_dict_to_json, parse_ubl_cii_xml
from .untdid import untdid_get_label

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
    "preprocess_data_dict",
    "get_data_dict_copy_for_logs",
    "is_credit_note",
    "parse_ubl_cii_xml",
    "data_dict_to_json",
    "untdid_get_label",
]

logging.getLogger("factur-x").addHandler(logging.NullHandler())


def configure_script_logging(level=logging.INFO):
    logger = logging.getLogger("factur-x")
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    logger.addHandler(handler)
    logger.setLevel(level)
