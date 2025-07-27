#! /usr/bin/env python
# Copyright 2017-2023 Alexis de Lattre <alexis.delattre@akretion.com>

import argparse
import sys
from facturx import generate_from_file, __version__ as fxversion
from facturx.facturx import logger
import logging
from os.path import isfile, isdir, basename

__author__ = "Alexis de Lattre <alexis.delattre@akretion.com>"
__date__ = "July 2025"
__version__ = "0.7"


def pdfgen(args):
    logger.info('pdfgen version %s using factur-x lib version %s', __version__, fxversion)
    if args.log_level:
        log_level = args.log_level.lower()
        log_map = {
            'debug': logging.DEBUG,
            'info': logging.INFO,
            'warn': logging.WARN,
            'error': logging.ERROR,
        }
        if log_level in log_map:
            logger.setLevel(log_map[log_level])
        else:
            logger.error(
                'Wrong value for log level (%s). Possible values: %s',
                log_level, ', '.join(log_map.keys()))
            sys.exit(1)

    pdf_filename = args.regular_pdf_file
    xml_filename = args.xml_file
    output_pdf_filename = args.facturx_orderx_pdf_file
    additional_attachment_filenames = args.optional_attachments
    for filename in [pdf_filename, xml_filename] + additional_attachment_filenames:
        if not isfile(filename):
            logger.error('Argument %s is not a filename', filename)
            sys.exit(1)
    if isdir(output_pdf_filename):
        logger.error(
            '3rd argument %s is a directory name (should be a the '
            'Factur-X or Order-X PDF filename)', output_pdf_filename)
        sys.exit(1)
    xml_file = open(xml_filename, 'rb')
    check_xsd = True
    if args.disable_xsd_check:
        check_xsd = False
    pdf_metadata = None
    if (
            args.meta_author or
            args.meta_keywords or
            args.meta_title or
            args.meta_subject):
        pdf_metadata = {
            'author': args.meta_author,
            'keywords': args.meta_keywords,
            'title': args.meta_title,
            'subject': args.meta_subject,
            }
    if isfile(output_pdf_filename):
        if args.overwrite:
            logger.warning(
                'File %s already exists. Overwriting it.',
                output_pdf_filename)
        else:
            logger.error(
                'File %s already exists. Exit.', output_pdf_filename)
            sys.exit(1)
    attachments = {}
    for additional_attachment_filename in additional_attachment_filenames:
        attachments[basename(additional_attachment_filename)] = {
            'filepath': additional_attachment_filename}
    lang = args.lang or None
    try:
        # The important line of code is below !
        generate_from_file(
            pdf_filename, xml_file, check_xsd=check_xsd,
            flavor=args.flavor, level=args.level, orderx_type=args.orderx_type,
            pdf_metadata=pdf_metadata, lang=lang, output_pdf_file=output_pdf_filename,
            attachments=attachments, afrelationship=args.afrelationship)
    except Exception as e:
        logger.error('factur-x lib call failed. Error: %s', e)
        sys.exit(1)


def main(args=None):
    if args is None:
        args = sys.argv[1:]
    usage = "facturx-pdfgen <regular_pdf_file> <xml_file> "\
            "<facturx_orderx_pdf_file> <optional_attachments>"
    epilog = "Author: %s - Version: %s" % (__author__, __version__)
    description = "This script generate a Factur-X or Order-X PDF from a "\
                  "regular PDF/A document and a Factur-X or Order-X XML file. "\
                  "It can also include additional embedded files in the PDF. "\
                  "To generate a valid PDF/A-3 document as requested by the "\
                  "Factur-X/Order-X standards, you need to give a valid PDF/A "\
                  "document as input."\
                  "\n\nIf you use one of the --meta-* arguments, you should specify "\
                  "all the meta-* arguments because the default values for "\
                  "metadata only apply if none of the meta-* arguments are used."
    parser = argparse.ArgumentParser(
        usage=usage, epilog=epilog, description=description)
    parser.add_argument(
        '-l', '--log-level', dest='log_level', default='info',
        help="Set log level. Possible values: debug, info, warn, error. "
        "Default value: info.")
    parser.add_argument(
        '-d', '--disable-xsd-check', dest='disable_xsd_check',
        action='store_true',
        help="De-activate XML Schema Definition check on XML file "
        "(the check is enabled by default)")
    parser.add_argument(
        '-f', '--flavor', dest='flavor', default='autodetect',
        help="Specify if you want to generate a Factur-X or Order-X PDF file. "
        "Default: autodetect. If you specify a particular flavor instead of "
        "using autodetection from the XML, you will win a very small amount of time "
        "(less than 1 millisecond). "
        "Possible values: order-x, factur-x or autodetect.")
    parser.add_argument(
        '-n', '--level', '--facturx-level', dest='level', default='autodetect',
        help="Specify the Factur-X or Order-X level of the XML file. "
        "Default: autodetect. If you specify a particular level instead of "
        "using autodetection, you will win a very small amount of time "
        "(less than 1 millisecond). "
        "Possible values for Factur-X: minimum, basicwl, basic, en16931, extended."
        "Possible values for Order-X: basic, comfort, extended."
        )
    parser.add_argument(
        '-p', '--orderx-type', dest='orderx_type', default='autodetect',
        help="When you generate an Order-X document, specify the order type. "
        "Default: autodetect. If you specify a particular order type instead of "
        "using autodetection, you will win a very small amount of time "
        "(less than 1 millisecond). "
        "Possible values: order, order_change, order_response.")
    parser.add_argument(
        '-g', '--lang', dest='lang',
        help="Set the language identifier as RFC 3066 to specify the "
        "natural language of the PDF document. Example: en-US.")
    parser.add_argument(
        '-r', '--afrelationship', dest='afrelationship', default='data',
        help="Set the AFRelationship PDF property of the Factur-X/Order-X XML file. "
        "Possible values: data, source, alternative. "
        "Default value: data.")
    parser.add_argument(
        '-a', '--meta-author', dest='meta_author',
        help="Specify the author for PDF metadata. Default: use the vendor "
        "name extracted from the XML file.")
    parser.add_argument(
        '-k', '--meta-keywords', dest='meta_keywords',
        help="Specify the keywords for PDF metadata. "
        "Default for Factur-X: 'Invoice, Factur-X'."
        "Default for Order-X: 'Order Change, Order-X' where 'Order Change' is "
        "the order type.")
    parser.add_argument(
        '-t', '--meta-title', dest='meta_title',
        help="Specify the title of PDF metadata. "
        "Default: generic English title with information extracted from "
        "the XML file such as: 'Akretion: Invoice I1242'")
    parser.add_argument(
        '-s', '--meta-subject', dest='meta_subject',
        help="Specify the subject of PDF metadata. "
        "Default: generic English subject with information extracted from the "
        "XML file such as: "
        "'Factur-X invoice I1242 dated 2017-08-17 issued by Akretion'")
    parser.add_argument(
        '-w', '--overwrite', dest='overwrite', action='store_true',
        help="Overwrite output PDF file if it already exists.")
    parser.add_argument("regular_pdf_file", help="Regular PDF invoice")
    parser.add_argument("xml_file", help="Factur-X or Order-X XML file")
    parser.add_argument(
        "facturx_orderx_pdf_file", help="Generated Factur-X or Order-X PDF file")
    parser.add_argument(
        "optional_attachments", nargs='*',
        help="Optional list of additionnal attachments")
    args = parser.parse_args()
    pdfgen(args)


def run():
    if __name__ == '__main__':
        main()


run()
