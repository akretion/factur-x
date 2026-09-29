#! /usr/bin/env python
# Copyright 2017-2023 Alexis de Lattre <alexis.delattre@akretion.com>

import argparse
import json
import logging
import mimetypes
import sys
from os.path import isdir, isfile

from facturx import __version__ as fxversion
from facturx import (
    configure_script_logging,
    data_dict_to_json,
    generate_xml,
    get_xml_from_pdf,
    parse_ubl_cii_xml,
)

__author__ = "Alexis de Lattre <alexis.delattre@akretion.com>"
__date__ = "September 2026"
__version__ = "0.2beta"

logger = logging.getLogger("factur-x")


def convert(args):
    logger.info(
        "pdfextractxml version %s using factur-x lib version %s", __version__, fxversion
    )

    in_filename = args.input_invoice_file
    out_filename = args.output_file_to_create
    out_flavor_list = args.output_flavor
    if not isfile(in_filename):
        logger.error(f"Argument {in_filename} is not a filename")
        sys.exit(1)
    if isdir(out_filename):
        logger.error(
            f"2nd argument {out_filename} is a directory name (should be a the "
            "output filename)",
        )
        sys.exit(1)
    check_xsd = not args.disable_xsd_check
    check_schematron = not args.disable_schematron_check
    in_mtype, _ignore = mimetypes.guess_type(in_filename)
    out_mtype, _ignore = mimetypes.guess_type(out_filename)
    logger.debug(f"Input file MIME type is {in_mtype}")
    xml_string = None
    if in_mtype == "application/pdf":
        with open(in_filename, "rb") as in_file:
            try:
                xml_filename, xml_string = get_xml_from_pdf(
                    in_file, check_xsd=check_xsd, check_schematron=check_schematron
                )
            except Exception as e:
                logger.error(e)
                sys.exit(1)
        if not xml_string:
            logger.error("Could not extract XML file from PDF")
            sys.exit(1)
    elif in_mtype == "application/xml":
        with open(in_filename, "rb") as in_file:
            xml_string = in_file.read()
        if not xml_string:
            logger.error("Input XML file is empty")
            sys.exit(1)
    elif in_mtype == "application/json":
        with open(in_filename, "rb") as in_file:
            json_string = in_file.read()
        data_dict = json.loads(json_string)
    else:
        logger.error(
            f"Input file is identified as an {in_mtype} file. "
            f"The only supported input files types are 'application/pdf', "
            f"'application/xml' and 'application/json'."
        )
        sys.exit(1)
    float_as = "string"
    if out_mtype == "application/json":
        float_as = "float"
    if xml_string:
        data_dict = parse_ubl_cii_xml(
            xml_string,
            float_as=float_as,
            date_as="string",
            bytes_as="string",
            check_xsd=check_xsd,
            check_schematron=check_schematron,
        )
    # TODO
    if "BT-24" in data_dict:
        data_dict.pop("BT-24")

    # pprint(data_dict)

    if out_mtype == "application/xml":
        if not out_flavor_list:
            logger.error(
                "For XML output, you must indicate the flavor to generate: "
                "ubl or cii"
            )
            sys.exit(1)
        cli_flavor = out_flavor_list[0]
        if cli_flavor not in ("ubl", "cii"):
            logger.error(
                f"Invalid flavor requested on the command line ({cli_flavor}). "
                "Supported flavors: ubl or cii"
            )
        flavor_map = {
            "ubl": "ubl-2.1",
            "cii": "factur-x",
        }
        prefixed_namespaces = not args.absolute_namespaces
        data_to_write_bytes = generate_xml(
            data_dict,
            flavor=flavor_map[cli_flavor],
            #  level="autodetect",
            level="en16931",  # TODO
            check_xsd=check_xsd,
            check_schematron=check_schematron,
            #  saxon_server_url=None,
            #  saxon_server_codedb_base_url=None,
            #  saxon_server_codedb_dir=None,
            #  saxon_server_raise_if_http_error=False,
            prefixed_namespaces=prefixed_namespaces,
        )

    elif out_mtype == "application/json":
        json_to_write = data_dict_to_json(data_dict)
        data_to_write_bytes = json_to_write.encode("utf-8")
    else:
        logger.error(
            f"Output file is identified as an {out_mtype} file. "
            f"The only supported output files types are 'application/xml' "
            f"and 'application/json' (for the moment)."
        )
        sys.exit(1)

    if data_to_write_bytes:
        if isfile(out_filename):
            logger.warning(f"File {out_filename} already exists. Overwriting it!")
        with open(out_filename, "wb") as out_file:
            out_file.write(data_to_write_bytes)
        logger.info(f"Output file {out_filename} generated")
    else:
        logger.warning(f"File {out_filename} has not been created")
        sys.exit(1)


def main(args=None):
    if args is None:
        args = sys.argv[1:]
    usage = (
        "facturx-convert <input_invoice_file> <output_file_to_create> "
        "<output_format_if_xml>"
    )
    epilog = f"Author: {__author__} - Version: {__version__}"
    description = (
        "Convert the invoice file (Factur-X, UBL XML, CII XML, JSON) "
        "to another format (UBL XML, CII XML, JSON)."
    )
    parser = argparse.ArgumentParser(
        usage=usage, epilog=epilog, description=description
    )
    parser.add_argument(
        "-l",
        "--log-level",
        dest="log_level",
        choices=["debug", "info", "warn", "error"],
        default="info",
        help="Set log level. Default value: info.",
    )
    parser.add_argument(
        "-d",
        "--disable-xsd-check",
        dest="disable_xsd_check",
        action="store_true",
        help="De-activate XML Schema Definition check on Factur-X/Order-X XML file "
        "(the check is enabled by default)",
    )
    parser.add_argument(
        "-ds",
        "--disable-schematron-check",
        dest="disable_schematron_check",
        action="store_true",
        help="De-activate Schematron check on Factur-X/Order-X XML file "
        "(the check is enabled by default)",
    )
    parser.add_argument(
        "-a",
        "--absolute-namespaces",
        dest="absolute_namespaces",
        action="store_true",
        help="If the output file is XML, use absolute namespaces instead of "
        "prefixed namespaces.",
    )

    parser.add_argument(
        "input_invoice_file",
        help="Input invoice file (Factur-X, UBL XML, CII XML, JSON)",
    )
    parser.add_argument(
        "output_file_to_create",
        help="Filename of the output file (UBL XML, CII XML, JSON)",
    )
    parser.add_argument(
        "output_flavor",
        nargs="*",
        help="Output format (if XML output)",
    )
    args = parser.parse_args()
    log_map = {
        "debug": logging.DEBUG,
        "info": logging.INFO,
        "warn": logging.WARN,
        "error": logging.ERROR,
    }
    configure_script_logging(level=log_map[args.log_level])
    convert(args)


def run():
    if __name__ == "__main__":
        main()


run()
