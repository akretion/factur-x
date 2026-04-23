#! /usr/bin/env python
# Copyright 2017-2023 Alexis de Lattre <alexis.delattre@akretion.com>

import argparse
import sys
from facturx import get_xml_from_pdf, __version__ as fxversion
from facturx.facturx import logger
import logging
from os.path import isfile, isdir

__author__ = "Alexis de Lattre <alexis.delattre@akretion.com>"
__date__ = "March 2026"
__version__ = "0.4"


def pdfextractxml(args):
    logger.info('pdfextractxml version %s using factur-x lib version %s', __version__, fxversion)
    log_map = {
        'debug': logging.DEBUG,
        'info': logging.INFO,
        'warn': logging.WARN,
        'error': logging.ERROR,
    }
    logger.setLevel(log_map[args.log_level])

    pdf_filename = args.facturx_orderx_file
    out_xml_filename = args.xml_file_to_create
    if not isfile(pdf_filename):
        logger.error('Argument %s is not a filename', pdf_filename)
        sys.exit(1)
    if isdir(out_xml_filename):
        logger.error(
            '2nd argument %s is a directory name (should be a the '
            'output XML filename)', out_xml_filename)
        sys.exit(1)
    pdf_file = open(pdf_filename, 'rb')
    check_xsd = not args.disable_xsd_check
    check_schematron = not args.disable_schematron_check
    # The important line of code is below !
    try:
        (xml_filename, xml_string) = get_xml_from_pdf(
            pdf_file, check_xsd=check_xsd, check_schematron=check_schematron)
    except Exception as e:
        logger.error(e)
        sys.exit(1)
    if xml_filename and xml_string:
        if isfile(out_xml_filename):
            logger.warning(
                'File %s already exists. Overwriting it!', out_xml_filename)
        xml_file = open(out_xml_filename, 'wb')
        xml_file.write(xml_string)
        xml_file.close()
        logger.info('File %s generated', out_xml_filename)
    else:
        logger.warning('File %s has not been created', out_xml_filename)
        sys.exit(1)


def main(args=None):
    if args is None:
        args = sys.argv[1:]
    usage = "facturx-pdfextractxml <facturx_orderx_file> <xml_file_to_create>"
    epilog = "Author: %s - Version: %s" % (__author__, __version__)
    description = "This extracts the XML file from a Factur-X or Order-X PDF file."
    parser = argparse.ArgumentParser(
        usage=usage, epilog=epilog, description=description)
    parser.add_argument(
        '-l', '--log-level', dest="log_level", default='info',
        help="Set log level. Possible values: debug, info, warn, error. "
        "Default value: info.", choices=['debug', 'info', 'warn', 'error'])
    parser.add_argument(
        '-d', '--disable-xsd-check', dest='disable_xsd_check',
        action='store_true',
        help="De-activate XML Schema Definition check on Factur-X/Order-X XML file "
        "(the check is enabled by default)")
    parser.add_argument(
        '-ds', '--disable-schematron-check', dest='disable_schematron_check',
        action='store_true',
        help="De-activate Schematron check on Factur-X/Order-X XML file "
        "(the check is enabled by default)")
    parser.add_argument(
        "facturx_orderx_file", help="PDF Factur-X or Order-X file")
    parser.add_argument(
        "xml_file_to_create",
        help="Filename of the XML file that will be extracted from the PDF")
    args = parser.parse_args()
    pdfextractxml(args)


def run():
    if __name__ == '__main__':
        main()


run()
