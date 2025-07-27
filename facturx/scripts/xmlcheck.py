#! /usr/bin/env python
# Copyright 2017-2023 Alexis de Lattre <alexis.delattre@akretion.com>

import argparse
import sys
from facturx import xml_check_xsd, __version__ as fxversion
from facturx.facturx import logger
import logging
from os.path import isfile

__author__ = "Alexis de Lattre <alexis.delattre@akretion.com>"
__date__ = "July 2025"
__version__ = "0.4"


def xmlcheck(args):
    logger.info('xmlcheck version %s using factur-x lib version %s', __version__, fxversion)
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

    if not isfile(args.xml_file):
        logger.error('%s is not a filename', args.xml_file)
        sys.exit(1)
    xml_file = open(args.xml_file, 'rb')
    # The important line of code is below !
    try:
        xml_check_xsd(
            xml_file, flavor=args.flavor, level=args.level)
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
        "Default value: info.")
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
