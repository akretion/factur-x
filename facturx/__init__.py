import logging

from .facturx import generate_from_file, \
    generate_from_binary, \
    get_xml_namespaces, \
    get_flavor, \
    get_facturx_level, \
    get_level, \
    xml_check_xsd, \
    xml_check_schematron, \
    get_facturx_xml_from_pdf, \
    get_orderx_xml_from_pdf, \
    get_xml_from_pdf, \
    get_orderx_type

__version__ = "4.2"


logging.getLogger('factur-x').addHandler(logging.NullHandler())


def configure_script_logging(level=logging.INFO):
    logger = logging.getLogger('factur-x')
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter(
        '%(asctime)s [%(levelname)s] %(message)s'
    ))
    logger.addHandler(handler)
    logger.setLevel(level)
