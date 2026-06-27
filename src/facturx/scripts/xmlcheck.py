#! /usr/bin/env python
# Copyright 2017-2023 Alexis de Lattre <alexis.delattre@akretion.com>

import argparse
import logging
import sys
from os.path import isfile

from facturx import __version__ as fxversion
from facturx import configure_script_logging, xml_check_schematron, xml_check_xsd

__author__ = "Alexis de Lattre <alexis.delattre@akretion.com>"
__date__ = "June 2026"
__version__ = "0.6"


logger = logging.getLogger("factur-x")


def xmlcheck(args):
    logger.info(
        "xmlcheck version %s using factur-x lib version %s", __version__, fxversion
    )

    if not isfile(args.xml_file):
        logger.error("%s is not a filename", args.xml_file)
        sys.exit(1)
    with open(args.xml_file, "rb") as xml_file:
        xml_bytes = xml_file.read()
    try:
        xml_check_xsd(xml_bytes, flavor=args.flavor, level=args.level)
    except Exception as e:
        logger.error(e)
        sys.exit(1)
    try:
        xml_check_schematron(
            xml_bytes,
            flavor=args.flavor,
            level=args.level,
            check_option=args.check_option,
        )
    except Exception as e:
        logger.error(e)
        sys.exit(1)


def main(args=None):
    if args is None:
        args = sys.argv[1:]
    usage = "facturx-xmlcheck <xml_file>"
    epilog = f"Author: {__author__} - Version: {__version__}"
    description = (
        "This script checks Factur-X, Order-X and UBL 2.1 XML files against the XML "
        "Schema Definition and Schematron."
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
        "-f",
        "--flavor",
        dest="flavor",
        choices=["factur-x", "zugferd", "order-x", "ubl-2.1", "autodetect"],
        default="autodetect",
        help="Set XML flavor. Default value: autodetect.",
    )
    parser.add_argument(
        "-p",
        "--check-option",
        dest="check_option",
        choices=["base", "fr-ctc", "fr-chorus"],
        default="base",
        help="Set check_option for schematron. Default value: base.",
    )
    parser.add_argument(
        "-n",
        "--facturx-level",
        dest="level",
        default="autodetect",
        help="Specify the level of the Factur-X or Order-X XML file. "
        "Default: autodetect. If you specify a particular level instead of "
        "using autodetection, you will win a very small amount of time "
        "(less than 1 millisecond). "
        "Possible values for Factur-X: minimum, basicwl, basic, en16931, extended "
        "or extended-ctc-fr. "
        "Possible values for Order-X: basic, comfort, extended."
        "Possible values for UBL 2.1: en16931 or extended-ctc-fr.",
    )
    parser.add_argument("xml_file", help="Factur-X or Order-X XML file to check")
    args = parser.parse_args()
    log_map = {
        "debug": logging.DEBUG,
        "info": logging.INFO,
        "warn": logging.WARN,
        "error": logging.ERROR,
    }
    configure_script_logging(level=log_map[args.log_level])
    xmlcheck(args)


def run():
    if __name__ == "__main__":
        main()


run()
