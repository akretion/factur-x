# Copyright 2016-2023, Alexis de Lattre <alexis.delattre@akretion.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * The name of the authors may not be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# TODO list:
# - add automated tests (currently, we only have tests at odoo module level)
# - keep original metadata by copy of pdf_tailer[/Info] ?

import importlib.resources as importlib_resources
from datetime import datetime
from io import BytesIO, IOBase
from tempfile import NamedTemporaryFile

import requests
from lxml import etree
from pypdf import PdfReader, PdfWriter
from pypdf.generic import (
    ArrayObject,
    ByteStringObject,
    DecodedStreamObject,
    DictionaryObject,
    NameObject,
    NumberObject,
    TextStringObject,
)

try:
    _ = importlib_resources.files  # added in py3.9
except AttributeError:
    import importlib_resources  # py3.8 compat: pip install importlib-resources
import hashlib
import importlib.metadata
import logging
import mimetypes
import os.path

logger = logging.getLogger("factur-x")

VERSION = importlib.metadata.version("factur-x")
FACTURX_FILENAME = "factur-x.xml"
ZUGFERD_FILENAMES = ["zugferd-invoice.xml", "ZUGFeRD-invoice.xml"]
ORDERX_FILENAME = "order-x.xml"
ALL_FILENAMES = [FACTURX_FILENAME] + ZUGFERD_FILENAMES + [ORDERX_FILENAME]
# XSD files
FACTURX_LEVEL2xsd = {
    "minimum": "facturx-minimum/Factur-X_MINIMUM.xsd",
    "basicwl": "facturx-basicwl/Factur-X_BASICWL.xsd",
    "basic": "facturx-basic/Factur-X_BASIC.xsd",
    "en16931": "facturx-en16931/Factur-X_EN16931.xsd",
    "extended": "facturx-extended/Factur-X_EXTENDED.xsd",
    # CII only
    "extended-ctc-fr": "cii-extended-ctc-fr/CrossIndustryInvoice_100pD22B.xsd",
}
ZUGFERD_xsd = "zugferd/ZUGFeRD1p0.xsd"  # ZUGFeRD 1.x
ORDERX_LEVEL2xsd = {
    "basic": "orderx-basic/SCRDMCCBDACIOMessageStructure_100pD20B.xsd",
    "comfort": "orderx-comfort/SCRDMCCBDACIOMessageStructure_100pD20B.xsd",
    "extended": "orderx-extended/SCRDMCCBDACIOMessageStructure_100pD20B.xsd",
}
UBL_21_xsd = {
    "ubl-2.1-invoice": "ubl-2.1/maindoc/UBL-Invoice-2.1.xsd",
    "ubl-2.1-creditnote": "ubl-2.1/maindoc/UBL-CreditNote-2.1.xsd",
}
# SCHEMATON "BASE" files
FACTURX_LEVEL2schematron = {
    "minimum": "facturx-minimum/Factur-X_1.09_MINIMUM.xsl",
    "basicwl": "facturx-basicwl/Factur-X_1.09_BASICWL.xsl",
    "basic": "facturx-basic/Factur-X_1.09_BASIC.xsl",
    "en16931": "facturx-en16931/Factur-X_1.09_EN16931.xsl",
    "extended": "facturx-extended/Factur-X_1.09_EXTENDED.xsl",
    # CII only
    "extended-ctc-fr": "cii-extended-ctc-fr/EXTENDED-CTC-FR-CII.xslt",
}
ORDERX_LEVEL2schematron = {
    "basic": "orderx-basic/SCRDMCCBDACIOMessageStructure_100pD20B-compiled.xsl",
    "comfort": "orderx-comfort/SCRDMCCBDACIOMessageStructure_100pD20B-compiled.xsl",
    "extended": "orderx-extended/SCRDMCCBDACIOMessageStructure_100pD20B-compiled.xsl",
}
UBL_21_LEVEL2schematron = {
    "en16931": "ubl-2.1/EN16931-UBL-validation.xslt",
    "extended-ctc-fr": "ubl-2.1/EXTENDED-CTC-FR-UBL.xslt",
}
# SCHEMATRON "fr-ctc" files
UBL_21_FR_CTC_schematron = "ubl-2.1/BR-FR-Flux2-Schematron-UBL.xslt"
CII_FR_CTC_schematron = "cii-schematron-fr-ctc/BR-FR-Flux2-Schematron-CII.xslt"

FACTURX_LEVEL2xmp = {
    "minimum": "MINIMUM",
    "basicwl": "BASIC WL",
    "basic": "BASIC",
    "en16931": "EN 16931",
    "extended": "EXTENDED",
}
ORDERX_TYPES = ("order", "order_change", "order_response")
ORDERX_code2type = {
    "220": "order",
    "230": "order_change",
    "231": "order_response",
}
XML_AFRelationship = ("data", "source", "alternative")
ATTACHMENTS_AFRelationship = ("supplement", "unspecified")
XML_NAMESPACES = {
    "factur-x": {
        "qdt": "urn:un:unece:uncefact:data:standard:QualifiedDataType:100",
        "ram": (
            "urn:un:unece:uncefact:data:standard:"
            "ReusableAggregateBusinessInformationEntity:100"
        ),
        "rsm": "urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100",
        "udt": "urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
    },
    "order-x": {
        "qdt": "urn:un:unece:uncefact:data:standard:QualifiedDataType:128",
        "ram": (
            "urn:un:unece:uncefact:data:standard:"
            "ReusableAggregateBusinessInformationEntity:128"
        ),
        "rsm": "urn:un:unece:uncefact:data:SCRDMCCBDACIOMessageStructure:100",
        "udt": "urn:un:unece:uncefact:data:standard:UnqualifiedDataType:128",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
    },
    "zugferd": {
        "ram": (
            "urn:un:unece:uncefact:data:standard:"
            "ReusableAggregateBusinessInformationEntity:12"
        ),
        "rsm": "urn:ferd:CrossIndustryDocument:invoice:1p0",
        "udt": "urn:un:unece:uncefact:data:standard:UnqualifiedDataType:15",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
    },
    "ubl-2.1-invoice": {
        "default": "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
        "cac": "urn:oasis:names:specification:ubl:schema:xsd:"
        "CommonAggregateComponents-2",
        "cbc": "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "ccts": "urn:un:unece:uncefact:documentation:2",
        "qdt": "urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2",
        "udt": "urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2",
    },
    "ubl-2.1-creditnote": {
        "default": "urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2",
        "cac": "urn:oasis:names:specification:ubl:schema:xsd:"
        "CommonAggregateComponents-2",
        "cbc": "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "ccts": "urn:un:unece:uncefact:documentation:2",
        "qdt": "urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2",
        "udt": "urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2",
    },
}
CREATOR = f"factur-x Python lib v{VERSION} by Alexis de Lattre"
# Saxon server available from https://github.com/willemvlh/saxon-server
# We stopped using saxonche because of https://github.com/akretion/pyfrctc/issues/3
SAXON_SERVER_DEFAULT_URL = "http://localhost:5000/transform"
SAXON_SERVER_TIMEOUT = 5
CODEDB_FACTURX_LEVEL2URL = {
    "minimum": "https://raw.githubusercontent.com/akretion/factur-x/refs/heads/master/src/facturx/xsd_and_schematron/facturx-minimum/FACTUR-X_MINIMUM_codedb.xml",
    "basicwl": "https://raw.githubusercontent.com/akretion/factur-x/refs/heads/master/src/facturx/xsd_and_schematron/facturx-basicwl/FACTUR-X_BASIC-WL_codedb.xml",
    "basic": "https://raw.githubusercontent.com/akretion/factur-x/refs/heads/master/src/facturx/xsd_and_schematron/facturx-basic/FACTUR-X_BASIC_codedb.xml",
    "en16931": "https://raw.githubusercontent.com/akretion/factur-x/refs/heads/master/src/facturx/xsd_and_schematron/facturx-en16931/FACTUR-X_EN16931_codedb.xml",
    "extended": "https://raw.githubusercontent.com/akretion/factur-x/refs/heads/master/src/facturx/xsd_and_schematron/facturx-extended/FACTUR-X_EXTENDED_codedb.xml",
}


def xml_check_xsd(xml, flavor="autodetect", level="autodetect"):
    """
    Validate the XML file against the XSD
    :param xml: the Factur-X or Order-X XML
    :type xml: string, file or etree object
    :param flavor: possible values: 'factur-x', 'zugferd', 'order-x',
    'ubl-2.1-invoice', 'ubl-2.1-creditnote'
    or 'autodetect'.
    Value 'zugferd' means ZUGFeRD 1.0.
    :type flavor: string
    :param level: the level of the Factur-X or Order-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a small perf improvement.
    Possible values for Factur-X: minimum, basicwl, basic, en16931, extended.
    Possible values for Order-X: basic, comfort, extended.
    :return: True if the XML is valid against the XSD
    raise an error if it is not valid against the XSD
    """
    logger.debug("xml_check_xsd with factur-x lib %s", VERSION)
    if not isinstance(flavor, str):
        raise ValueError("Wrong type for flavor argument")
    if not isinstance(level, (type(None), str)):
        raise ValueError("Wrong type for level argument")
    start_chrono = datetime.now()
    xml_etree = None
    if isinstance(xml, (bytes, str)):
        try:
            xml_etree = etree.fromstring(xml)
        except Exception as err:
            raise Exception(
                f"The file to check is not a valid XML file. Error: {err}"
            ) from err
    elif isinstance(xml, type(etree.Element("pouet"))):
        xml_etree = xml
    elif isinstance(xml, IOBase):
        xml.seek(0)
        xml_bytes = xml.read()
        xml.close()
        try:
            xml_etree = etree.fromstring(xml_bytes)
        except Exception as err:
            raise Exception(
                f"The file to check is not a valid XML file. Error: {err}"
            ) from err
    else:
        raise ValueError("Wrong type for xml argument")

    # autodetect
    if flavor not in (
        "factur-x",
        "facturx",
        "zugferd",
        "order-x",
        "orderx",
        "ubl-2.1-invoice",
        "ubl-2.1-creditnote",
    ):
        flavor = get_flavor(xml_etree)
    if flavor in ("factur-x", "facturx"):
        if level not in FACTURX_LEVEL2xsd:
            level = get_level(xml_etree, flavor)
        if level not in FACTURX_LEVEL2xsd:
            raise ValueError(f"Wrong level '{level}' for Factur-X invoice.")
        xsd_file = f"xsd_and_schematron/{FACTURX_LEVEL2xsd[level]}"
    elif flavor == "zugferd":
        xsd_file = f"xsd_and_schematron/{ZUGFERD_xsd}"
    elif flavor in ("order-x", "orderx"):
        if level not in ORDERX_LEVEL2xsd:
            level = get_level(xml_etree, flavor)
        if level not in ORDERX_LEVEL2xsd:
            raise ValueError(f"Wrong level '{level}' for Order-X document.")
        xsd_file = f"xsd_and_schematron/{ORDERX_LEVEL2xsd[level]}"
    elif flavor in ("ubl-2.1-invoice", "ubl-2.1-creditnote"):
        xsd_file = f"xsd_and_schematron/{UBL_21_xsd[flavor]}"
    else:
        raise ValueError(f"Flavor '{flavor}' doesn't exist")

    xsd_absolute_filepath = importlib_resources.files(__package__).joinpath(xsd_file)
    logger.debug("Using XSD file %s", xsd_absolute_filepath)
    # str is added to be compatible with lxml 4.6.5
    official_schema = etree.XMLSchema(file=str(xsd_absolute_filepath))
    try:
        official_schema.assertValid(xml_etree)
    except Exception as err:
        # if the validation of the XSD fails, we arrive here
        logger.error("The XML file is invalid against the XML Schema Definition")
        logger.error("XSD Error: %s", err)
        raise Exception(
            f"The {flavor.capitalize()} XML file is not valid against the official "
            f"XML Schema Definition. Here is the error, which may give you an idea on "
            f"the cause of the problem: {err}."
        ) from err
    end_chrono = datetime.now()
    logger.info(
        "%s XML file successfully validated against XSD in %s sec",
        flavor,
        (end_chrono - start_chrono).total_seconds(),
    )
    return True


def xml_check_schematron(
    xml,
    flavor="autodetect",
    level="autodetect",
    check_option="base",
    saxon_server_url=None,
    saxon_server_codedb_dir=None,
    raise_if_http_error=False,
):
    """
    Validate the XML file against the schematron
    :param xml: the Factur-X or Order-X XML
    :type xml: string, file or etree object
    :param flavor: possible values: 'factur-x', 'zugferd', 'order-x', 'ubl-2.1',
    'ubl-2.1-invoice', 'ubl-2.1-creditnote'
    or 'autodetect'.
    Value 'zugferd' means ZUGFeRD 1.0.
    :type flavor: string
    :param level: the level of the Factur-X or Order-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a small perf improvement.
    Possible values for Factur-X: minimum, basicwl, basic, en16931, extended.
    Possible values for Order-X: basic, comfort, extended.
    :param check_option: keyword that designate the list of schematons to use.
    "base" (default value) will only check against the base schematon.
    "fr-ctc" will check against both the base schematron and France CTC
    schematon.
    "fr-chorus" will check against the base schematron, France CTC schematon
    and the Chorus-specific schematron (not available yet)
    :type check_option: string
    :param saxon_server_url: URL of the Saxon Server. If not set, the lib
    will use the default URL http://localhost:5000/transform
    :type saxon_server_url: string
    :param raise_if_http_error: raise an exception if the HTTP POST request
    to the saxon server fails. If False, a failure in the communication with
    the saxon server will not raise any error (it will just be logged)
    :type raise_if_http_error: bool
    :return: True if the XML is valid against the schematron
    raise an error if it is not valid against the schematron
    """
    logger.debug("xml_check_schematron with factur-x lib %s", VERSION)
    if not isinstance(flavor, str):
        raise ValueError("Wrong type for flavor argument")
    if not isinstance(level, (type(None), str)):
        raise ValueError("Wrong type for level argument")
    if not isinstance(saxon_server_url, (type(None), str)):
        raise ValueError("Wrong type for saxon_server_url argument")
    if not isinstance(saxon_server_codedb_dir, (type(None), str)):
        raise ValueError("Wrong type for saxon_server_codedb_dir argument")
    url = saxon_server_url
    if url is None:
        url = SAXON_SERVER_DEFAULT_URL
    start_chrono = datetime.now()
    xml_etree = None
    if isinstance(xml, bytes):
        xml_bytes = xml
        xml_str = xml_bytes.decode("utf-8")
    elif isinstance(xml, str):
        xml_str = xml
        xml_bytes = xml_str.encode("utf-8")
    elif isinstance(xml, type(etree.Element("pouet"))):
        xml_etree = xml
        xml_bytes = etree.tostring(
            xml, pretty_print=True, encoding="UTF-8", xml_declaration=True
        )
        xml_str = xml_bytes.decode("utf-8")
    elif isinstance(xml, IOBase):
        xml.seek(0)
        xml_bytes = xml.read()
        xml.close()
        xml_str = xml_bytes.decode("utf-8")
    else:
        raise ValueError("Wrong type for xml argument")

    if not xml_str or not xml_bytes:
        raise ValueError("xml argument is empty")

    # autodetect
    if flavor not in (
        "factur-x",
        "facturx",
        "zugferd",
        "order-x",
        "orderx",
        "ubl-2.1",
        "ubl-2.1-invoice",
        "ubl-2.1-creditnote",
    ):
        if xml_etree is None:
            try:
                xml_etree = etree.fromstring(xml_bytes)
            except Exception as e:
                raise Exception(f"The XML syntax is invalid: {e}.") from e
        flavor = get_flavor(xml_etree)
    if flavor in ("factur-x", "facturx"):
        if level not in FACTURX_LEVEL2schematron:
            if xml_etree is None:
                try:
                    xml_etree = etree.fromstring(xml_bytes)
                except Exception as e:
                    raise Exception(f"The XML syntax is invalid: {e}.") from e
            level = get_level(xml_etree, flavor)
        if level not in FACTURX_LEVEL2schematron:
            raise ValueError(f"Wrong level '{level}' for Factur-X invoice.")
        xsl_files = {"base": f"xsd_and_schematron/{FACTURX_LEVEL2schematron[level]}"}
        if check_option in ("fr-ctc", "fr-chorus") and level != "minimum":
            xsl_files["fr-ctc"] = f"xsd_and_schematron/{CII_FR_CTC_schematron}"
    elif flavor in ("order-x", "orderx"):
        if level not in ORDERX_LEVEL2schematron:
            if xml_etree is None:
                try:
                    xml_etree = etree.fromstring(xml_bytes)
                except Exception as e:
                    raise Exception(f"The XML syntax is invalid: {e}.") from e
            level = get_level(xml_etree, flavor)
        if level not in ORDERX_LEVEL2schematron:
            raise ValueError(f"Wrong level '{level}' for Order-X document.")
        xsl_files = {"base": f"xsd_and_schematron/{ORDERX_LEVEL2schematron[level]}"}
    elif flavor in ("ubl-2.1", "ubl-2.1-invoice", "ubl-2.1-creditnote"):
        if level not in UBL_21_LEVEL2schematron:
            raise ValueError(f"Wrong level '{level}' for UBL 2.1")
        xsl_files = {"base": f"xsd_and_schematron/{UBL_21_LEVEL2schematron[level]}"}
        if check_option in ("fr-ctc", "fr-chorus"):
            xsl_files["fr-ctc"] = f"xsd_and_schematron/{UBL_21_FR_CTC_schematron}"
    else:
        logger.warning("There is no schematron check for flavor '%s'", flavor)
        return True
    if check_option == "fr-chorus":
        logger.info(
            "The fr-chorus schematron is not available yet. "
            "It will be added as soon as it is available"
        )

    errors = []
    error_nr = 1
    xml_str_no_bom = xml_str.lstrip("\ufeff")
    for check_type, xsl_file in xsl_files.items():
        absolute_xsl_file_path = importlib_resources.files(__package__).joinpath(
            xsl_file
        )
        logger.debug(
            "Schematron check '%s': using XSL file %s",
            check_type,
            absolute_xsl_file_path,
        )
        xsl_file_str = absolute_xsl_file_path.read_text(encoding="utf-8")
        if (
            check_type == "base"
            and flavor in ("factur-x", "facturx")
            and level in CODEDB_FACTURX_LEVEL2URL
        ):
            codedb_url = CODEDB_FACTURX_LEVEL2URL[level]
            codedb_file = os.path.basename(codedb_url)
            if saxon_server_codedb_dir:
                saxon_server_codedb_file = os.path.join(
                    saxon_server_codedb_dir, codedb_file
                )
                xsl_file_str = xsl_file_str.replace(
                    codedb_file, saxon_server_codedb_file
                )
                logger.info(
                    f"Replaced {codedb_file} by {saxon_server_codedb_file} in "
                    "schematron XSL file"
                )
            else:
                logger.info(
                    "Replacing codedb XML files by public URLs in schematron file, "
                    "which will add latency to schematron validation. Use the "
                    "saxon_server_codedb_dir argument to reduce latency."
                )
                xsl_file_str = xsl_file_str.replace(codedb_file, codedb_url)

        rfiles = {
            "xml": ("file_to_check.xml", xml_str_no_bom, "text/xml"),
            "xsl": (xsl_file, xsl_file_str, "text/xml"),
        }
        req_start_chrono = datetime.now()
        logger.info(
            f"Sending HTTP POST request on {url} to validate "
            f"against schematron '{check_type}'"
        )
        try:
            res = requests.post(url, files=rfiles, timeout=SAXON_SERVER_TIMEOUT)
        except Exception as err:
            error_msg = (
                f"Check '{check_type}' failed in the POST request to saxon server "
                f"on {url}: {str(err)}"
            )
            logger.warning(error_msg)
            if raise_if_http_error:
                raise RuntimeError(error_msg) from err
            logger.warning(f"Skipping schematron check '{check_type}'")
            continue
        req_end_chrono = datetime.now()
        req_duration = (req_end_chrono - req_start_chrono).total_seconds()

        if res.status_code != 200:
            error_msg = (
                f"Saxon server returned HTTP code {res.status_code} for check "
                f"'{check_type}' (expected HTTP code: 200)"
            )
            logger.warning(error_msg)
            if raise_if_http_error:
                raise RuntimeError(error_msg)
            logger.warning(f"Skipping schematron check '{check_type}'")
            continue
        logger.info(
            f"Saxon server answered successfully for check '{check_type}' "
            f"in {req_duration} sec"
        )
        result_str = res.text
        logger.debug(f"schematron '{check_type}' result_str={result_str}")

        try:
            svrl_root = etree.fromstring(result_str.encode("utf-8"))
        except Exception as e:
            logger.error(
                f"Schematron '{check_type}' check on {flavor} {level} file generated "
                f"an invalid XML output. Error: {str(e)}"
            )
            return False
        xpath_errors = svrl_root.xpath(
            ".//svrl:successful-report | .//svrl:failed-assert",
            namespaces=svrl_root.nsmap,
        )
        for xpath_error in xpath_errors:
            detail_xpath = xpath_error.xpath(
                "*[local-name() = 'text']", namespaces=svrl_root.nsmap
            )
            if detail_xpath:
                error_msg = detail_xpath[0].text and detail_xpath[0].text.strip()
                error_msg = f"{error_nr}. [{check_type}] {error_msg}"
                location = xpath_error.attrib and xpath_error.attrib.get("location")
                if location:
                    error_msg = f"{error_msg}\nError location: {location}"
                errors.append(error_msg)
                error_nr += 1

    if errors:
        logger.error(
            f"The {flavor} {level} XML file is invalid against {len(xsl_files)} "
            f"schematron(s): {len(errors)} errors found."
        )
        for error_msg in errors:
            logger.error(error_msg)
        error_list_str = "\n".join(errors)
        full_error = (
            f"The {flavor} {level} XML file is not valid against the {len(xsl_files)} "
            f"schematron(s). {len(errors)} errors found:\n{error_list_str}"
        )
        logger.error("Dumping the XML file that has the above schematron error:")
        logger.error(xml_str)
        raise Exception(full_error)
    end_chrono = datetime.now()
    logger.info(
        "%s XML file successfully validated against %s schematron(s) in %s sec",
        flavor,
        len(xsl_files),
        (end_chrono - start_chrono).total_seconds(),
    )
    return True


def get_facturx_xml_from_pdf(
    pdf_file,
    check_xsd=True,
    check_schematron=False,
    saxon_server_url=None,
    saxon_server_codedb_dir=None,
):
    filenames = [FACTURX_FILENAME] + ZUGFERD_FILENAMES
    return get_xml_from_pdf(
        pdf_file,
        check_xsd=check_xsd,
        check_schematron=check_schematron,
        saxon_server_url=saxon_server_url,
        saxon_server_codedb_dir=saxon_server_codedb_dir,
        filenames=filenames,
    )


def get_orderx_xml_from_pdf(
    pdf_file,
    check_xsd=True,
    check_schematron=False,
    saxon_server_url=None,
    saxon_server_codedb_dir=None,
):
    filenames = [ORDERX_FILENAME]
    return get_xml_from_pdf(
        pdf_file,
        check_xsd=check_xsd,
        check_schematron=check_schematron,
        saxon_server_url=saxon_server_url,
        saxon_server_codedb_dir=saxon_server_codedb_dir,
        filenames=filenames,
    )


def get_xml_from_pdf(
    pdf_file,
    check_xsd=True,
    check_schematron=False,
    saxon_server_url=None,
    saxon_server_codedb_dir=None,
    filenames=None,
):
    logger.debug("get_xml_from_pdf with factur-x lib %s", VERSION)
    if filenames is None:
        filenames = []
    if not pdf_file:
        raise ValueError("Missing pdf_invoice argument")
    if not isinstance(check_xsd, bool):
        raise ValueError("Bad type for check_xsd argument")
    if not isinstance(check_schematron, bool):
        raise ValueError("Bad type for check_schematron argument")
    if not isinstance(filenames, list):
        raise ValueError("Bad type for filenames argument")
    if isinstance(pdf_file, (str, bytes)):
        pdf_file_in = BytesIO(pdf_file)
    elif isinstance(pdf_file, IOBase):
        pdf_file_in = pdf_file
    else:
        raise TypeError(
            f"The first argument of the method get_xml_from_pdf must be either a byte "
            f"or a file (it is a {type(pdf_file)})."
        )
    if not filenames:
        filenames = ALL_FILENAMES
    logger.debug("Searching for filenames %s", filenames)
    xml_bytes = xml_filename = False
    pdf_reader = PdfReader(pdf_file_in)
    for attach_obj in pdf_reader.attachment_list:
        filename = attach_obj.name
        logger.debug("Found filename=%s", filename)
        if filename.lower().endswith(".xml") and attach_obj.content:
            try:
                xml_root = etree.fromstring(attach_obj.content)
                logger.info("A valid XML file %s has been found in the PDF", filename)
            except Exception as e:
                logger.warning("File %s is not a valid XML file: %s", filename, str(e))
                continue
            try:
                flavor = get_flavor(xml_root)
            except Exception as e:
                logger.warning(
                    "File %s is not a factur-x/order-x/zugferd/xrechnung file. "
                    "Error: %s",
                    filename,
                    e,
                )
                continue
            if (filename == ORDERX_FILENAME and flavor != "order-x") or (
                filename == FACTURX_FILENAME and flavor != "factur-x"
            ):
                # Don't do that when filename is zugferd-invoice.xml
                # because it can be either zugferd (ie zugferd 1.0)
                # or 'factur-x' i.e. zugferd 2.0, see bug #41
                logger.warning(
                    "Filename is %s but detected flavor is %s. "
                    "This is very weird: skipping file.",
                    filename,
                    flavor,
                )
                continue
            level = False
            if check_xsd or check_schematron:
                try:
                    level = get_level(xml_root, flavor)
                except Exception:
                    logger.warning(
                        "Skipping file %s because the level could not be identified",
                        filename,
                    )
                    continue
            if check_xsd and level:
                try:
                    xml_check_xsd(xml_root, flavor=flavor, level=level)
                except Exception:
                    logger.warning(
                        "Skipping file %s because it is not valid against the XSD",
                        filename,
                    )
                    continue
            if check_schematron and level:
                try:
                    xml_check_schematron(
                        xml_root,
                        flavor=flavor,
                        level=level,
                        saxon_server_url=saxon_server_url,
                        saxon_server_codedb_dir=saxon_server_codedb_dir,
                    )
                except Exception:
                    logger.warning(
                        "Skipping %s: not valid against the schematron", filename
                    )
                    continue
            xml_bytes = attach_obj.content
            xml_filename = filename
            logger.info("XML file %s extracted from PDF", xml_filename)
            logger.debug("Content of the XML file: %s", xml_bytes)
            break
    if not xml_filename:
        logger.warning(
            "No valid factur-x/order-x/zugferd/xrechnung XML file found in this PDF"
        )
    return (xml_filename, xml_bytes)


def _get_pdf_timestamp(date=None):
    if date is None:
        date = datetime.now()
    # example date format: "D:20141006161354+02'00'"
    pdf_date = date.strftime("D:%Y%m%d%H%M%S+00'00'")
    return pdf_date


def _get_metadata_timestamp():
    now_dt = datetime.now()
    # example format : 2014-07-25T14:01:22+02:00
    meta_date = now_dt.strftime("%Y-%m-%dT%H:%M:%S+00:00")
    return meta_date


def _prepare_pdf_metadata_txt(pdf_metadata):
    pdf_date = _get_pdf_timestamp()
    info_dict = {
        "/Author": pdf_metadata.get("author", ""),
        "/CreationDate": pdf_date,
        "/Creator": CREATOR,
        "/Keywords": pdf_metadata.get("keywords", ""),
        "/ModDate": pdf_date,
        "/Subject": pdf_metadata.get("subject", ""),
        "/Title": pdf_metadata.get("title", ""),
    }
    return info_dict


def _prepare_pdf_metadata_xml(flavor, level, orderx_type, pdf_metadata):
    head = """<?xpacket begin="\ufeff" id="W5M0MpCehiHzreSzNTczkc9d"?>"""
    xml_str = """
<x:xmpmeta xmlns:x="adobe:ns:meta/">
  <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <rdf:Description xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/" rdf:about="">
      <pdfaid:part>3</pdfaid:part>
      <pdfaid:conformance>B</pdfaid:conformance>
    </rdf:Description>
    <rdf:Description xmlns:dc="http://purl.org/dc/elements/1.1/" rdf:about="">
      <dc:title>
        <rdf:Alt>
          <rdf:li xml:lang="x-default">##title</rdf:li>
        </rdf:Alt>
      </dc:title>
      <dc:creator>
        <rdf:Seq>
          <rdf:li>##author</rdf:li>
        </rdf:Seq>
      </dc:creator>
      <dc:description>
        <rdf:Alt>
          <rdf:li xml:lang="x-default">##subject</rdf:li>
        </rdf:Alt>
      </dc:description>
    </rdf:Description>
    <rdf:Description xmlns:pdf="http://ns.adobe.com/pdf/1.3/" rdf:about="">
      <pdf:Producer>##producer</pdf:Producer>
    </rdf:Description>
    <rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" rdf:about="">
      <xmp:CreatorTool>##creator_tool</xmp:CreatorTool>
      <xmp:CreateDate>##timestamp</xmp:CreateDate>
      <xmp:ModifyDate>##timestamp</xmp:ModifyDate>
    </rdf:Description>
    <rdf:Description xmlns:pdfaExtension="http://www.aiim.org/pdfa/ns/extension/" xmlns:pdfaSchema="http://www.aiim.org/pdfa/ns/schema#" xmlns:pdfaProperty="http://www.aiim.org/pdfa/ns/property#" rdf:about="">
      <pdfaExtension:schemas>
        <rdf:Bag>
          <rdf:li rdf:parseType="Resource">
            <pdfaSchema:schema>Factur-X PDFA Extension Schema</pdfaSchema:schema>
            <pdfaSchema:namespaceURI>{urn}</pdfaSchema:namespaceURI>
            <pdfaSchema:prefix>fx</pdfaSchema:prefix>
            <pdfaSchema:property>
              <rdf:Seq>
                <rdf:li rdf:parseType="Resource">
                  <pdfaProperty:name>DocumentFileName</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>The name of the embedded XML document</pdfaProperty:description>
                </rdf:li>
                <rdf:li rdf:parseType="Resource">
                  <pdfaProperty:name>DocumentType</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>The type of the hybrid document in capital letters, e.g. INVOICE or ORDER</pdfaProperty:description>
                </rdf:li>
                <rdf:li rdf:parseType="Resource">
                  <pdfaProperty:name>Version</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>The actual version of the standard applying to the embedded XML document</pdfaProperty:description>
                </rdf:li>
                <rdf:li rdf:parseType="Resource">
                  <pdfaProperty:name>ConformanceLevel</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>The conformance level of the embedded XML document</pdfaProperty:description>
                </rdf:li>
              </rdf:Seq>
            </pdfaSchema:property>
          </rdf:li>
        </rdf:Bag>
      </pdfaExtension:schemas>
    </rdf:Description>
    <rdf:Description xmlns:fx="{urn}" rdf:about="">
      <fx:DocumentType>##documenttype</fx:DocumentType>
      <fx:DocumentFileName>##xml_filename</fx:DocumentFileName>
      <fx:Version>##version</fx:Version>
      <fx:ConformanceLevel>##xmp_level</fx:ConformanceLevel>
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>
"""  # noqa: E501
    tail = """<?xpacket end="w"?>"""
    key2value = {
        "title": pdf_metadata.get("title", ""),
        "author": pdf_metadata.get("author", ""),
        "subject": pdf_metadata.get("subject", ""),
        "producer": "pypdf",
        "creator_tool": CREATOR,
        "timestamp": _get_metadata_timestamp(),
        "version": "1.0",
    }

    if flavor == "order-x":
        key2value.update(
            {
                "documenttype": orderx_type.upper(),
                "xml_filename": ORDERX_FILENAME,
                "xmp_level": level.upper(),
            }
        )
        urn = "urn:factur-x:pdfa:CrossIndustryDocument:1p0#"
    else:
        key2value.update(
            {
                "documenttype": "INVOICE",
                "xml_filename": FACTURX_FILENAME,
                "xmp_level": FACTURX_LEVEL2xmp[level],
            }
        )
        urn = "urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#"
    xml_str = xml_str.format(urn=urn)
    xml_root = etree.fromstring(xml_str)
    namespaces = xml_root.nsmap
    namespaces.update(
        {
            "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            "dc": "http://purl.org/dc/elements/1.1/",
            "fx": "urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#",
            "pdf": "http://ns.adobe.com/pdf/1.3/",
            "xmp": "http://ns.adobe.com/xap/1.0/",
        }
    )
    xpath2key = {
        "/x:xmpmeta/rdf:RDF/rdf:Description/dc:title//rdf:li": "title",
        "/x:xmpmeta/rdf:RDF/rdf:Description/dc:creator//rdf:li": "author",
        "/x:xmpmeta/rdf:RDF/rdf:Description/dc:description//rdf:li": "subject",
        "/x:xmpmeta/rdf:RDF/rdf:Description/pdf:Producer": "producer",
        "/x:xmpmeta/rdf:RDF/rdf:Description/xmp:CreatorTool": "creator_tool",
        "/x:xmpmeta/rdf:RDF/rdf:Description/xmp:CreateDate": "timestamp",
        "/x:xmpmeta/rdf:RDF/rdf:Description/xmp:ModifyDate": "timestamp",
        "/x:xmpmeta/rdf:RDF/rdf:Description/fx:DocumentType": "documenttype",
        "/x:xmpmeta/rdf:RDF/rdf:Description/fx:DocumentFileName": "xml_filename",
        "/x:xmpmeta/rdf:RDF/rdf:Description/fx:Version": "version",
        "/x:xmpmeta/rdf:RDF/rdf:Description/fx:ConformanceLevel": "xmp_level",
    }
    for xpath, key in xpath2key.items():
        xml_nodes = xml_root.xpath(xpath, namespaces=namespaces)
        if len(xml_nodes) != 1:
            raise Exception(
                f"XMP generation: wrong xpath {xpath} for {key}. "
                f"Please report it as a bug."
            )
        xml_node = xml_nodes[0]
        expected_node_text = f"##{key}"
        if xml_node.text != expected_node_text:
            raise Exception(
                f"XMP generation: xpath {xpath} contains {xml_node.text} "
                f"instead of {expected_node_text}. Please report it as a bug."
            )
        value = key2value[key]
        xml_node.text = value

    xml_bytes = etree.tostring(xml_root)
    xml_str_final = "\n".join([head, xml_bytes.decode("utf-8"), tail])
    xml_bytes_final = xml_str_final.encode("utf-8")
    logger.debug("metadata XML:")
    logger.debug(xml_bytes_final)
    return xml_bytes_final


def _filespec_additional_attachments(
    pdf_writer, name_arrayobj_cdict, file_dict, filename
):
    logger.debug("_filespec_additional_attachments filename=%s", filename)
    md5sum_bytes = hashlib.md5(file_dict["filedata"]).digest()
    md5sum_obj = ByteStringObject(md5sum_bytes)
    params_dict = DictionaryObject(
        {
            NameObject("/CheckSum"): md5sum_obj,
            NameObject("/Size"): NumberObject(len(file_dict["filedata"])),
        }
    )
    # creation date and modification date are optional
    if isinstance(file_dict.get("modification_datetime"), datetime):
        mod_date_pdf = _get_pdf_timestamp(file_dict["modification_datetime"])
        params_dict[NameObject("/ModDate")] = TextStringObject(mod_date_pdf)
    if isinstance(file_dict.get("creation_datetime"), datetime):
        creation_date_pdf = _get_pdf_timestamp(file_dict["creation_datetime"])
        params_dict[NameObject("/CreationDate")] = TextStringObject(creation_date_pdf)
    file_entry = DecodedStreamObject()
    file_entry.set_data(file_dict["filedata"])
    file_entry = file_entry.flate_encode()
    file_mimetype = mimetypes.guess_type(filename)[0]
    if not file_mimetype:
        file_mimetype = "application/octet-stream"
    file_entry.update(
        {
            NameObject("/Type"): NameObject("/EmbeddedFile"),
            NameObject("/Params"): params_dict,
            NameObject("/Subtype"): NameObject(f"/{file_mimetype}"),
        }
    )
    file_entry_obj = pdf_writer._add_object(file_entry)
    ef_dict = DictionaryObject(
        {
            NameObject("/F"): file_entry_obj,
        }
    )
    fname_obj = TextStringObject(filename)
    afrelationship = file_dict.get("afrelationship")
    if afrelationship not in ATTACHMENTS_AFRelationship:
        afrelationship = "unspecified"
    filespec_dict = DictionaryObject(
        {
            NameObject("/AFRelationship"): NameObject(
                f"/{afrelationship.capitalize()}"
            ),
            NameObject("/Desc"): TextStringObject(file_dict.get("description", "")),
            NameObject("/Type"): NameObject("/Filespec"),
            NameObject("/F"): fname_obj,
            NameObject("/EF"): ef_dict,
            NameObject("/UF"): fname_obj,
        }
    )
    filespec_obj = pdf_writer._add_object(filespec_dict)
    name_arrayobj_cdict[fname_obj] = filespec_obj


def _facturx_update_metadata_add_attachment(
    pdf_writer,
    xml_bytes,
    pdf_metadata,
    flavor,
    level,
    orderx_type=None,
    lang=None,
    additional_attachments=None,
    afrelationship="data",
    xmp_compression=True,
):
    """This method is inspired from the code of the add_attachment()
    method of the pypdf lib"""
    if additional_attachments is None:
        additional_attachments = {}
    # The entry for the file
    # facturx_xml_str = facturx_xml_str.encode('utf-8')
    if flavor == "order-x" and orderx_type not in ORDERX_TYPES:
        raise ValueError(
            f"Wrong value for orderx_type ({orderx_type}), must be in {ORDERX_TYPES}"
        )
    if afrelationship not in XML_AFRelationship:
        raise ValueError(
            f"Wrong value for afrelationship ({afrelationship}). "
            f"Possible values: {XML_AFRelationship}."
        )
    md5sum_bytes = hashlib.md5(xml_bytes).digest()
    md5sum_obj = ByteStringObject(md5sum_bytes)
    params_dict = DictionaryObject(
        {
            NameObject("/CheckSum"): md5sum_obj,
            NameObject("/ModDate"): TextStringObject(_get_pdf_timestamp()),
            NameObject("/Size"): NumberObject(len(xml_bytes)),
        }
    )
    file_entry = DecodedStreamObject()
    file_entry.set_data(xml_bytes)  # here we integrate the file itself
    file_entry = file_entry.flate_encode()
    file_entry.update(
        {
            NameObject("/Type"): NameObject("/EmbeddedFile"),
            NameObject("/Params"): params_dict,
            NameObject("/Subtype"): NameObject("/text/xml"),
        }
    )
    file_entry_obj = pdf_writer._add_object(file_entry)
    # The Filespec entry
    ef_dict = DictionaryObject(
        {
            NameObject("/F"): file_entry_obj,
            NameObject("/UF"): file_entry_obj,
        }
    )

    if flavor == "order-x":
        xml_filename = ORDERX_FILENAME
        desc = "Order-X XML file"
    else:
        xml_filename = FACTURX_FILENAME
        desc = "Factur-X XML file"

    fname_obj = TextStringObject(xml_filename)
    filespec_dict = DictionaryObject(
        {
            NameObject("/AFRelationship"): NameObject(
                f"/{afrelationship.capitalize()}"
            ),
            NameObject("/Desc"): TextStringObject(desc),
            NameObject("/Type"): NameObject("/Filespec"),
            NameObject("/F"): fname_obj,
            NameObject("/EF"): ef_dict,
            NameObject("/UF"): fname_obj,
        }
    )
    filespec_obj = pdf_writer._add_object(filespec_dict)
    name_arrayobj_cdict = {fname_obj: filespec_obj}
    for attach_filename, attach_dict in additional_attachments.items():
        _filespec_additional_attachments(
            pdf_writer, name_arrayobj_cdict, attach_dict, attach_filename
        )
    logger.debug("name_arrayobj_cdict=%s", name_arrayobj_cdict)
    name_arrayobj_content_sort = list(
        sorted(name_arrayobj_cdict.items(), key=lambda x: x[0])
    )
    logger.debug("name_arrayobj_content_sort=%s", name_arrayobj_content_sort)
    name_arrayobj_content_final = []
    af_list = []
    for fname_obj, filespec_obj in name_arrayobj_content_sort:
        name_arrayobj_content_final += [fname_obj, filespec_obj]
        af_list.append(filespec_obj)
    embedded_files_names_dict = DictionaryObject(
        {
            NameObject("/Names"): ArrayObject(name_arrayobj_content_final),
        }
    )
    # Then create the entry for the root, as it needs a
    # reference to the Filespec
    embedded_files_dict = DictionaryObject(
        {
            NameObject("/EmbeddedFiles"): embedded_files_names_dict,
        }
    )
    # Update the root
    af_value_obj = pdf_writer._add_object(ArrayObject(af_list))
    update_root_dict = {
        NameObject("/AF"): af_value_obj,
        NameObject("/Names"): embedded_files_dict,
        # show attachments when opening PDF
        NameObject("/PageMode"): NameObject("/UseAttachments"),
    }
    metadata_xml_bytes = _prepare_pdf_metadata_xml(
        flavor, level, orderx_type, pdf_metadata
    )
    metadata_file_entry = DecodedStreamObject()
    metadata_file_entry.update(
        {
            NameObject("/Subtype"): NameObject("/XML"),
            NameObject("/Type"): NameObject("/Metadata"),
        }
    )
    metadata_file_entry.set_data(metadata_xml_bytes)
    if xmp_compression:
        metadata_file_entry = metadata_file_entry.flate_encode()

    existing_metadata_obj = pdf_writer._root_object.get("/Metadata")
    if existing_metadata_obj:
        logger.debug("Found existing /Metadata entry in catalog: replacing it.")
        pdf_writer._replace_object(existing_metadata_obj, metadata_file_entry)
    else:
        logger.debug("No existing /Metadata entry in catalog: creating one.")
        metadata_obj = pdf_writer._add_object(metadata_file_entry)
        update_root_dict[NameObject("/Metadata")] = metadata_obj
    pdf_writer._root_object.update(update_root_dict)
    if lang:
        pdf_writer._root_object.update(
            {
                NameObject("/Lang"): TextStringObject(lang.replace("_", "-")),
            }
        )
    metadata_txt_dict = _prepare_pdf_metadata_txt(pdf_metadata)
    pdf_writer.add_metadata(metadata_txt_dict)
    logger.info("%s file added to PDF document", xml_filename)


def _extract_base_info(facturx_xml_etree, flavor):
    if flavor not in ("factur-x", "facturx", "order-x", "orderx", "zugferd"):
        raise ValueError("Wrong value for flavor argument.")
    namespaces = get_xml_namespaces(flavor)
    date_xpath = facturx_xml_etree.xpath(
        "//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString",
        namespaces=namespaces,
    )
    date = date_xpath[0].text
    date_format = date_xpath[0].attrib and date_xpath[0].attrib.get("format") or "102"
    format_map = {
        "102": "%Y%m%d",
        "203": "%Y%m%d%H%M",
    }
    date_dt = datetime.strptime(date, format_map.get(date_format, format_map["102"]))
    number_xpath = facturx_xml_etree.xpath(
        "//rsm:ExchangedDocument/ram:ID", namespaces=namespaces
    )
    number = number_xpath[0].text
    seller_xpath = facturx_xml_etree.xpath(
        "//ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:Name",
        namespaces=namespaces,
    )
    seller = seller_xpath[0].text
    buyer_xpath = facturx_xml_etree.xpath(
        "//ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:Name",
        namespaces=namespaces,
    )
    buyer = buyer_xpath[0].text

    doc_type_xpath = facturx_xml_etree.xpath(
        "//rsm:ExchangedDocument/ram:TypeCode", namespaces=namespaces
    )
    doc_type = doc_type_xpath[0].text
    base_info = {
        "seller": seller,
        "buyer": buyer,
        "number": number,
        "date": date_dt,
        "doc_type": doc_type,
    }
    logger.debug("Extraction of base_info: %s", base_info)
    return base_info


def _base_info2pdf_metadata(base_info):
    doc_type_map = {
        "220": "Order",
        "230": "Order Change",
        "231": "Order Response",
        "380": "Invoice",
        "381": "Refund",
    }
    doc_type_name = doc_type_map.get(base_info["doc_type"], "Invoice")
    date_str = datetime.strftime(base_info["date"], "%Y-%m-%d")
    if base_info["doc_type"] == "231":
        title = (
            f"{base_info['seller']}: Order Response on Order {base_info['number']} "
            f"from {base_info['buyer']}"
        )
        subject = (
            f"Response of {base_info['seller']} on {date_str} to order "
            f"{base_info['number']} from {base_info['buyer']}"
        )
        doc_x = "Order-X"
        author = base_info["seller"]
    elif base_info["doc_type"] in ("220", "230"):
        title = f"{base_info['buyer']}: {doc_type_name} {base_info['number']}"
        subject = (
            f"{doc_type_name} {base_info['number']} issued by {base_info['buyer']} "
            f"on {date_str}"
        )
        doc_x = "Order-X"
        author = base_info["buyer"]
    else:
        title = f"{base_info['seller']}: {doc_type_name} {base_info['number']}"
        subject = (
            f"{doc_type_name} {base_info['number']} dated {date_str} issued by "
            f"{base_info['seller']}"
        )
        doc_x = "Factur-X"
        author = base_info["seller"]
    pdf_metadata = {
        "author": author,
        "keywords": f"{doc_type_name}, {doc_x}",
        "title": title,
        "subject": subject,
    }
    logger.debug("Converted base_info to pdf_metadata: %s", pdf_metadata)
    return pdf_metadata


def get_xml_namespaces(flavor):
    if flavor not in (
        "factur-x",
        "facturx",
        "order-x",
        "orderx",
        "zugferd",
        "ubl-2.1-invoice",
        "ubl-2.1-creditnote",
    ):
        raise ValueError("Wrong value for flavor argument.")
    if flavor == "facturx":
        flavor = "factur-x"
    elif flavor == "orderx":
        flavor = "order-x"
    return dict(XML_NAMESPACES[flavor])  # dict() to make a copy


def get_facturx_level(facturx_xml_etree):
    return get_level(facturx_xml_etree)


def get_level(xml_etree, flavor="autodetect"):
    if not isinstance(xml_etree, type(etree.Element("pouet"))):
        raise ValueError("xml_etree must be an etree.Element() object")
    if flavor not in (
        "autodetect",
        "factur-x",
        "facturx",
        "order-x",
        "orderx",
        "zugferd",
        "ubl-2.1-invoice",
        "ubl-2.1-creditnote",
    ):
        raise ValueError("Wrong value for flavor argument.")
    if flavor == "autodetect":
        flavor = get_flavor(xml_etree)
    namespaces = get_xml_namespaces(flavor)
    if flavor in ("factur-x", "facturx", "order-x", "orderx"):
        xpath = (
            "//rsm:ExchangedDocumentContext"
            "/ram:GuidelineSpecifiedDocumentContextParameter"
            "/ram:ID"
        )
    elif flavor == "zugferd":
        xpath = (
            "//rsm:SpecifiedExchangedDocumentContext"
            "/ram:GuidelineSpecifiedDocumentContextParameter"
            "/ram:ID"
        )
    elif flavor == "ubl-2.1-invoice":
        xpath = "/default:Invoice/cbc:CustomizationID"
    elif flavor == "ubl-2.1-creditnote":
        xpath = "/default:CreditNote/cbc:CustomizationID"
    else:
        raise ValueError(f"Wrong flavor '{flavor}'")
    doc_id_xpath = xml_etree.xpath(xpath, namespaces=namespaces)
    if not doc_id_xpath:
        raise ValueError(
            f"This {flavor} XML misses the XML tag {xpath}, "
            "although this XML tag is required"
        )
    doc_id = doc_id_xpath[0].text
    # Content of the ID field per level for Factur-X:
    # minimum: urn:factur-x.eu:1p0:minimum
    # basicwl: urn:factur-x.eu:1p0:basicwl
    # basic: urn:cen.eu:en16931:2017#compliant#urn:factur-x.eu:1p0:basic
    # en16931: urn:cen.eu:en16931:2017
    # extended: urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:extended
    # We also want to support variants such as:
    # urn:cen.eu:en16931:2017#conformant#urn.cpro.gouv.fr:1p0:extended-ctc-fr
    # Content of the ID field per level for Order-X:
    # basic: urn:order-x.eu:1p0:basic
    # comfort: urn:order-x.eu:1p0:comfort
    # extended: urn:order-x.eu:1p0:extended
    # ZUGFeRD 1.0 levels are the same as orderx
    possible_values = dict(FACTURX_LEVEL2xsd)
    possible_values.update(ORDERX_LEVEL2xsd)
    level = doc_id.split(":")[-1]
    if level == "extended-ctc-fr" and flavor == "factur-x":
        level = "extended"
    if level not in possible_values:
        # Ignore what is after the first "#"
        doc_id_cut = doc_id.split("#")[0]
        if len(doc_id_cut) > 1:
            level = doc_id_cut.split(":")[-2]
    if level not in possible_values:
        raise ValueError(f"Invalid Factur-X/Order-X URN: '{doc_id}'")
    logger.info("Level is %s (autodetected)", level)
    return level


def get_flavor(xml_etree):
    if not isinstance(xml_etree, type(etree.Element("pouet"))):
        raise ValueError("xml_etree must be an etree.Element() object")
    logger.debug("First XML tag: %s", xml_etree.tag)
    if xml_etree.tag.endswith("CrossIndustryInvoice"):
        flavor = "factur-x"
    elif xml_etree.tag.endswith("CrossIndustryDocument"):
        flavor = "zugferd"
    elif xml_etree.tag.endswith("SCRDMCCBDACIOMessageStructure"):
        flavor = "order-x"
    elif xml_etree.tag.endswith("Invoice"):
        flavor = "ubl-2.1-invoice"
    elif xml_etree.tag.endswith("CreditNote"):
        flavor = "ubl-2.1-creditnote"
    else:
        raise Exception(
            "Could not detect if the document is a Factur-X, ZUGFeRD 1.0 "
            "or Order-X document."
        )
    logger.info("Flavor is %s (autodetected)", flavor)
    return flavor


def get_orderx_type(xml_etree):
    if not isinstance(xml_etree, type(etree.Element("pouet"))):
        raise ValueError("xml_etree must be an etree.Element() object")
    type_code_xpath = (
        "/rsm:SCRDMCCBDACIOMessageStructure/rsm:ExchangedDocument/ram:TypeCode"
    )
    xpath_res = xml_etree.xpath(type_code_xpath, namespaces=XML_NAMESPACES["order-x"])
    code = xpath_res and xpath_res[0].text and xpath_res[0].text.strip() or None
    if code not in ORDERX_code2type:
        raise Exception(
            f"The TypeCode extracted from the XML is {code}. "
            f"This is not a valid Order-X TypeCode."
        )
    logger.info(
        "Order-X type is %s code %s (autodetected)", ORDERX_code2type[code], code
    )
    return ORDERX_code2type[code]


def generate_from_binary(
    pdf_file,
    xml,
    flavor="autodetect",
    level="autodetect",
    orderx_type="autodetect",
    check_xsd=True,
    check_schematron=False,
    saxon_server_url=None,
    saxon_server_codedb_dir=None,
    pdf_metadata=None,
    lang=None,
    attachments=None,
    afrelationship="data",
    xmp_compression=True,
):
    """
    Generate a Factur-X or Order-X PDF from a regular PDF and a factur-X
    or Order-X XML file. The method uses a binary as input (the regular PDF)
    and returns a binary as output (the Factur-X or Order-X PDF document).
    :param pdf_file: the regular PDF document as bytes
    :type pdf_file: bytes
    :param xml: the Factur-X or Order-X XML. If xml is a bytes, it must be
    the XML itself encoded as UTF-8. If xml is a string, it can be either
    a file path or the XML itself.
    :type xml: bytes, string, file or etree object
    :param flavor: possible values: 'factur-x', 'order-x' or 'autodetect'
    :type flavor: string
    :param level: the level of the Factur-X or Order-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a very very small perf improvement.
    Possible values: minimum, basicwl, basic, en16931, extended for Factur-X
    basic, comfort, extended for Order-X
    :type level: string
    :param orderx_type: If generating an Order-X file (flavor='order-x'),
    specify the type of Order-X document. Default value: autodetect.
    Possible values: order, order_change, order_response, autodetect.
    :type orderx_type: string
    :param check_xsd: if enable, checks the Factur-X XML file against the XSD
    (XML Schema Definition). If this step has already been performed
    beforehand, you should disable this feature to avoid a double check
    and get a small performance improvement.
    :type check_xsd: boolean
    :param check_schematron: if enable, checks the Factur-X XML file against
    the schematron. If this step has already been performed
    beforehand, you should disable this feature to avoid a double check
    and get a small performance improvement.
    :type check_schematron: boolean
    :param saxon_server_url: URL of the Saxon server for schematron validation.
    If None, the default Saxon server URL is used.
    :type saxon_server_url: boolean
    :param pdf_metadata: Specify the metadata of the generated PDF.
    If pdf_metadata is None (default value), this lib will generate some
    metadata in English by extracting relevant info from the Factur-X/Order-X XML.
    Here is an example for the pdf_metadata argument:
    pdf_metadata = {
        'author': 'Akretion',
        'keywords': 'Factur-X, Invoice',
        'title': 'Akretion: Invoice I1242',
        'subject': 'Factur-X invoice I1242 dated 2017-08-17 issued by Akretion',
        }
    If you pass the pdf_metadata argument, you will not use the automatic
    generation based on the extraction of the Factur-X/Order-X XML file, which will
    bring a very small perf improvement.
    :type pdf_metadata: dict
    :param lang: Language identifier in RFC 3066 format to specify the
    natural language of the PDF document. Used by PDF readers for blind people.
    Example: en-US or fr-FR
    :type lang: string
    :param output_pdf_file: File Path to the output Factur-X/Order-X PDF file
    :type output_pdf_file: string
    :param attachments: Specify the other files that you want to
    embed in the PDF file. It is a dict where key is the filename and value
    is a dict. In this dict, keys are 'filepath' (value is the full file path)
    or 'filedata' (value is the encoded file),
    'description' (text description, optional),
    'modification_datetime' (modification date and time as datetime object, optional).
    'creation_datetime' (creation date and time as datetime object, optional),
    'afrelationship' (AFRelationship of the attachment.
                      Possible values: supplement, unspecified.
                      Default value: unspecified).
    :type attachments: dict
    :param afrelationship: Set the AFRelationship PDF property of the
    Factur-X/Order-X XML file.
    Possible value: data, source, alternative. Default value: data.
    :type afrelationship: string
    :param xmp_compression: Enable flate compression of the XMP metadata.
    Default value: True. Set this option to False if you plan to later add a
    PAdES signature to the generated PDF file.
    :type xmp_compression: bool
    :return: The Factur-X or Order-X PDF file as bytes
    :rtype: bytes
    """

    if not isinstance(pdf_file, bytes):
        raise ValueError("pdf_invoice argument must be a string")
    result_pdf = False
    with NamedTemporaryFile(prefix="facturx-", suffix=".pdf") as f:
        f.write(pdf_file)
        generate_from_file(
            f,
            xml,
            flavor=flavor,
            level=level,
            orderx_type=orderx_type,
            check_xsd=check_xsd,
            check_schematron=check_schematron,
            saxon_server_url=saxon_server_url,
            saxon_server_codedb_dir=saxon_server_codedb_dir,
            pdf_metadata=pdf_metadata,
            lang=lang,
            attachments=attachments,
            afrelationship=afrelationship,
            xmp_compression=xmp_compression,
        )
        f.seek(0)
        result_pdf = f.read()
        f.close()
    return result_pdf


def generate_from_file(
    pdf_file,
    xml,
    flavor="autodetect",
    level="autodetect",
    orderx_type="autodetect",
    check_xsd=True,
    check_schematron=False,
    saxon_server_url=None,
    saxon_server_codedb_dir=None,
    pdf_metadata=None,
    lang=None,
    output_pdf_file=None,
    attachments=None,
    afrelationship="data",
    xmp_compression=True,
):
    """
    Generate a Factur-X or Order-X PDF file from a regular PDF and a Factur-X
    or Order-X XML file. The method uses a file as input (regular PDF file)
    and re-writes the file (Factur-X or Order-X PDF file).
    :param pdf_file: the regular PDF file as file path
    (type string) or as file object
    :type pdf_file: string or file
    :param xml: the Factur-X or Order-X XML. If xml is a bytes, it must be
    the XML itself encoded as UTF-8. If xml is a string, it can be either
    a file path or the XML itself.
    :type xml: bytes, string, file or etree object
    :param flavor: possible values: 'factur-x', 'order-x' or 'autodetect'
    :type flavor: string
    :param level: the level of the Factur-X or Order-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a very very small perf improvement.
    Possible values: minimum, basicwl, basic, en16931, extended for Factur-X
    basic, comfort, extended for Order-X
    :type level: string
    :param orderx_type: If generating an Order-X file (flavor='order-x'),
    specify the type of Order-X document. Default value: autodetect.
    Possible values: order, order_change, order_response, autodetect.
    :type orderx_type: string
    :param check_xsd: if enable, checks the Factur-X XML file against the XSD
    (XML Schema Definition). If this step has already been performed
    beforehand, you should disable this feature to avoid a double check
    and get a small performance improvement.
    :type check_xsd: boolean
    :param check_schematron: if enable, checks the Factur-X XML file against
    the schematron. If this step has already been performed
    beforehand, you should disable this feature to avoid a double check
    and get a small performance improvement.
    :type check_schematron: boolean
    :param saxon_server_url: URL of the Saxon server for schematron validation.
    If None, the default Saxon server URL is used.
    :type saxon_server_url: boolean
    :param pdf_metadata: Specify the metadata of the generated PDF.
    If pdf_metadata is None (default value), this lib will generate some
    metadata in English by extracting relevant info from the Factur-X/Order-X XML.
    Here is an example for the pdf_metadata argument:
    pdf_metadata = {
        'author': 'Akretion',
        'keywords': 'Factur-X, Invoice',
        'title': 'Akretion: Invoice I1242',
        'subject':
          'Factur-X invoice I1242 dated 2017-08-17 issued by Akretion',
        }
    If you pass the pdf_metadata argument, you will not use the automatic
    generation based on the extraction of the Factur-X/Order-X XML file, which will
    bring a very small perf improvement.
    :type pdf_metadata: dict
    :param lang: Language identifier in RFC 3066 format to specify the
    natural language of the PDF document. Used by PDF readers for blind people.
    Example: en-US or fr-FR
    :type lang: string
    :param output_pdf_file: File Path to the output Factur-X/Order-X PDF file
    :type output_pdf_file: string
    :param attachments: Specify the other files that you want to
    embed in the PDF file. It is a dict where key is the filename and value
    is a dict. In this dict, keys are 'filepath' (value is the full file path)
    or 'filedata' (value is the encoded file),
    'description' (text description, optional),
    'modification_datetime' (modification date and time as datetime object, optional).
    'creation_datetime' (creation date and time as datetime object, optional),
    'afrelationship' (AFRelationship of the attachment.
                      Possible values: supplement, unspecified.
                      Default value: unspecified).
    :type attachments: dict
    :param afrelationship: Set the AFRelationship PDF property of the
    Factur-X/Order-X XML file.
    Possible value: data, source, alternative. Default value: data.
    :type afrelationship: string
    :param xmp_compression: Enable flate compression of the XMP metadata.
    Default value: True. Set this option to False if you plan to later add a
    PAdES signature to the generated PDF file.
    :type xmp_compression: bool
    :return: Returns True. This method re-writes the input PDF file,
    unless if the argument output_pdf_file is set.
    :rtype: bool
    """
    start_chrono = datetime.now()
    logger.debug("generate_from_file with factur-x lib %s", VERSION)
    logger.debug("1st arg pdf_file type=%s", type(pdf_file))
    logger.debug("2nd arg xml type=%s", type(xml))
    logger.debug("optional arg flavor=%s", flavor)
    logger.debug("optional arg level=%s", level)
    logger.debug("optional arg orderx_type=%s", orderx_type)
    logger.debug("optional arg check_xsd=%s", check_xsd)
    logger.debug(f"optional arg check_schematron={check_schematron}")
    logger.debug("optional arg pdf_metadata=%s", pdf_metadata)
    logger.debug("optional arg lang=%s", lang)
    logger.debug("optional arg output_pdf_file=%s", output_pdf_file)
    logger.debug("optional arg attachments=%s", attachments)
    logger.debug("optional arg afrelationship=%s", afrelationship)
    if not pdf_file:
        raise ValueError("Missing pdf_file argument")
    if not xml:
        raise ValueError("Missing xml argument")
    if not isinstance(flavor, str):
        raise ValueError(f"flavor argument is a {type(flavor)}, must be a string")
    if not isinstance(level, str):
        raise ValueError(f"level argument is a {type(level)}, must be a string")
    if not isinstance(orderx_type, (str, type(None))):
        raise ValueError(
            f"orderx_type argument is a {type(orderx_type)}, must be a string or None"
        )
    if not isinstance(check_xsd, bool):
        raise ValueError(f"check_xsd argument is a {type(check_xsd)}, must be boolean")
    if not isinstance(check_schematron, bool):
        raise ValueError(
            "check_schematron argument is a {type(check_schematron)}, must be a boolean"
        )
    if not isinstance(pdf_metadata, (dict, type(None))):
        raise ValueError(
            f"pdf_metadata argument is a {type(pdf_metadata)}, must be a dict or None"
        )
    if not isinstance(lang, (type(None), str)):
        raise ValueError(f"lang argument is a {type(lang)}, must be a string or None")
    if not isinstance(output_pdf_file, (type(None), str)):
        raise ValueError(
            f"output_pdf_file argument is a {type(output_pdf_file)}, "
            f"must be a string or None"
        )
    if not isinstance(attachments, (dict, type(None))):
        raise ValueError(
            f"attachments argument is a {type(attachments)}, must be a dict or None"
        )
    if not isinstance(afrelationship, (str, type(None))):
        raise ValueError(
            f"afrelationship argument is a {type(afrelationship)}, "
            f"must be a string or None"
        )
    # Tolerance on arguments - reformatting
    flavor = flavor.lower()
    flavor_fix_mapping = {
        "orderx": "order-x",
        "facturx": "factur-x",
    }
    flavor = flavor_fix_mapping.get(flavor, flavor)
    level = level.lower().replace(" ", "")
    if orderx_type:
        orderx_type = orderx_type.lower().replace("-", "_").replace(" ", "_")
    if afrelationship:
        afrelationship = afrelationship.lower()
    else:
        afrelationship = "data"
    if afrelationship not in XML_AFRelationship:
        logger.warning(
            "Wrong value for afrelationship (%s). Forcing it to 'data'.", afrelationship
        )
        afrelationship = "data"

    if isinstance(pdf_file, str):
        file_type = "path"
    else:
        file_type = "file"
    xml_root = None
    if isinstance(xml, bytes):
        xml_bytes = xml
    elif isinstance(xml, str):
        # we accept both a file path or the XML string itself
        if os.path.isfile(xml):
            with open(xml, "rb") as xml_file:
                xml_bytes = xml_file.read()
        else:
            xml_bytes = xml.encode("utf8")
    elif isinstance(xml, type(etree.Element("pouet"))):
        xml_root = xml
        xml_bytes = etree.tostring(
            xml_root, pretty_print=True, encoding="UTF-8", xml_declaration=True
        )
    elif isinstance(xml, IOBase):
        xml.seek(0)
        xml_bytes = xml.read()
        # xml.close()
        # If xml is passed as file descriptor
        # I don't think we expect the lib to close it
    else:
        raise TypeError(
            f"The second argument of the method generate_from_file must be either a "
            f"string, an etree.Element() object or a file (it is a {type(xml)})."
        )
    if attachments is None:
        attachments = {}
    if attachments:
        # I used list() to avoid the following error in Python3:
        # Error: dictionary changed size during iteration
        for filename in list(attachments.keys()):
            if filename in ALL_FILENAMES:
                logger.warning(
                    "You cannot provide as attachment a file named %s. "
                    "This file will NOT be attached.",
                    filename,
                )
                attachments.pop(filename)
        for fadict in attachments.values():
            if fadict.get("filepath") and not fadict.get("filedata"):
                with open(fadict["filepath"], "rb") as fa:
                    fa.seek(0)
                    fadict["filedata"] = fa.read()
                    fa.close()

                # As explained here
                # https://stackoverflow.com/questions/237079/how-to-get-file-creation-modification-date-times-in-python
                # creation date is not easy to get.
                # So we only implement getting the modification date
                if not fadict.get("modification_datetime"):
                    mod_timestamp = os.path.getmtime(fadict["filepath"])
                    fadict["modification_datetime"] = datetime.fromtimestamp(
                        mod_timestamp
                    )
                if fadict.get("afrelationship"):
                    fadict["afrelationship"] = fadict["afrelationship"].lower()
                if fadict.get("afrelationship") not in ATTACHMENTS_AFRelationship:
                    # set default value
                    fadict["afrelationship"] = "unspecified"
    if flavor not in ("factur-x", "order-x"):
        if xml_root is None:
            xml_root = etree.fromstring(xml_bytes)
        logger.debug("Flavor will be autodetected")
        flavor = get_flavor(xml_root)
        if flavor == "zugferd":
            raise ValueError(
                "XML is ZUGFeRD 1.x. Generating ZUGFeRD 1.x PDF is not supported. "
                "You should update the XML to ZUGFeRD 2.x."
            )
    if (flavor == "factur-x" and level not in FACTURX_LEVEL2xsd) or (
        flavor == "order-x" and level not in ORDERX_LEVEL2xsd
    ):
        if xml_root is None:
            xml_root = etree.fromstring(xml_bytes)
        logger.debug("level will be autodetected")
        level = get_level(xml_root, flavor)
    if (
        flavor == "factur-x"
        and level in ("minimum", "basicwl")
        and afrelationship in ("source", "alternative")
    ):
        logger.warning(
            "afrelationship switched from '%s' to 'data' because it must be 'data' "
            "for Factur-X profile '%s'.",
            afrelationship,
            level,
        )
        afrelationship = "data"
    if flavor == "order-x" and orderx_type not in ORDERX_TYPES:
        if xml_root is None:
            xml_root = etree.fromstring(xml_bytes)
        orderx_type = get_orderx_type(xml_root)
    if check_xsd:
        if xml_root is None:
            xml_root = etree.fromstring(xml_bytes)
        xml_check_xsd(xml_root, flavor=flavor, level=level)
    if flavor in ("factur-x", "order-x") and check_schematron:
        xml_check_schematron(
            xml_bytes,
            flavor=flavor,
            level=level,
            saxon_server_url=saxon_server_url,
            saxon_server_codedb_dir=saxon_server_codedb_dir,
        )
    if pdf_metadata is None:
        if xml_root is None:
            xml_root = etree.fromstring(xml_bytes)
        base_info = _extract_base_info(xml_root, flavor)
        pdf_metadata = _base_info2pdf_metadata(base_info)
    else:
        # clean-up pdf_metadata dict
        for key, value in pdf_metadata.items():
            if not isinstance(value, str):
                pdf_metadata[key] = ""
    pdf_reader = PdfReader(pdf_file)
    pdf_writer = PdfWriter()
    pdf_writer._header = b"%PDF-1.6"
    pdf_writer.clone_document_from_reader(pdf_reader)

    _facturx_update_metadata_add_attachment(
        pdf_writer,
        xml_bytes,
        pdf_metadata,
        flavor,
        level,
        orderx_type=orderx_type,
        lang=lang,
        additional_attachments=attachments,
        afrelationship=afrelationship,
        xmp_compression=xmp_compression,
    )
    if output_pdf_file:
        with open(output_pdf_file, "wb") as output_f:
            pdf_writer.write(output_f)
            output_f.close()
    else:
        if file_type == "path":
            with open(pdf_file, "wb") as f:
                pdf_writer.write(f)
                f.close()
        elif file_type == "file":
            pdf_writer.write(pdf_file)
    end_chrono = datetime.now()
    logger.info(
        "%s PDF generated in %s sec",
        flavor,
        (end_chrono - start_chrono).total_seconds(),
    )
    return True
