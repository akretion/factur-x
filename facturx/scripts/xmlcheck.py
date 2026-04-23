#! /usr/bin/env python
# Copyright 2017-2023 Alexis de Lattre <alexis.delattre@akretion.com>

import argparse
import sys
from facturx import xml_check_xsd, xml_check_schematron, __version__ as fxversion
from facturx.facturx import logger
import logging
from os.path import isfile

__author__ = "Alexis de Lattre <alexis.delattre@akretion.com>"
__date__ = "March 2026"
__version__ = "0.5"


def xmlcheck(args):
    logger.info('xmlcheck version %s using factur-x lib version %s', __version__, fxversion)
    log_map = {
        'debug': logging.DEBUG,
        'info': logging.INFO,
        'warn': logging.WARN,
        'error': logging.ERROR,
    }
    logger.setLevel(log_map[args.log_level])

    if not isfile(args.xml_file):
        logger.error('%s is not a filename', args.xml_file)
        sys.exit(1)
    with open(args.xml_file, 'rb') as xml_file:
        xml_bytes = xml_file.read()
    try:
        xml_check_xsd(
            xml_bytes, flavor=args.flavor, level=args.level)
    except Exception as e:
        logger.error(e)
        sys.exit(1)
    try:
        xml_check_schematron(xml_bytes, flavor=args.flavor, level=args.level)
    except Exception as e:
        logger.error(e)
        sys.exit(1)


def main(args=None):
    if args is None:
        args = sys.argv[1:]
    usage = "facturx-xmlcheck <xml_file>"
    epilog = "Author: %s - Version: %s" % (__author__, __version__)
    description = "This script checks the Factur-X or Order-XML XML against the XML "\
                  "Schema Definition."
    parser = argparse.ArgumentParser(
        usage=usage, epilog=epilog, description=description)
    parser.add_argument(
        '-l', '--log-level', dest='log_level', default='info',
        help="Set log level. Possible values: debug, info, warn, error. "
        "Default value: info.", choices=['debug', 'info', 'warn', 'error'])
    parser.add_argument(
        '-f', '--flavor', dest='flavor', default='autodetect',
        help="Set XML flavor. Possible values: factur-x, zugferd, order-x or autodetect. "
        "Default value: autodetect.")
    parser.add_argument(
        '-n', '--facturx-level', dest='level',
        default='autodetect',
        help="Specify the level of the Factur-X or Order-X XML file. "
        "Default: autodetect. If you specify a particular level instead of "
        "using autodetection, you will win a very small amount of time "
        "(less than 1 millisecond). "
        "Possible values for Factur-X: minimum, basicwl, basic, en16931, extended. "
        "Possible values for Order-X: basic, comfort, extended.")
    parser.add_argument(
        "xml_file", help="Factur-X or Order-X XML file to check")
    args = parser.parse_args()
    xmlcheck(args)


def run():
    if __name__ == '__main__':
        main()


run()
