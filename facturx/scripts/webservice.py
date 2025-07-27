#! /usr/bin/env python
# Copyright 2020-2023 Alexis de Lattre <alexis.delattre@akretion.com>
# Published under the BSD licence
# REST webservice to generated Factur-X invoice
#
# If you deploy it in production, follow these instructions:
# https://flask.palletsprojects.com/en/2.3.x/deploying/
# Here is a good tutorial (in French) about the deployment of a Flask
# application in production with Gunicorn + Nginx:
# https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-gunicorn-and-nginx-on-ubuntu-20-04-fr
#
# Sample client request:
#   curl -X POST -F 'pdf=@/home/alexis/invoice_test.pdf'
#        -F 'xml=@/home/alexis/factur-x.xml' -o result_facturx.pdf
#        http://localhost:5000/generate_facturx

from flask import Flask, request, send_file
from tempfile import NamedTemporaryFile
from facturx import generate_from_file, __version__ as fxversion
from facturx.facturx import logger as fxlogger
import argparse
import logging
import sys
from logging.handlers import RotatingFileHandler

MAX_ATTACHMENTS = 3  # TODO make it a cmd line option
__author__ = "Alexis de Lattre <alexis.delattre@akretion.com>"
__date__ = "July 2025"
__version__ = "0.2"
app = Flask(__name__)


@app.route('/generate_facturx', methods=['POST'])
def generate_facturx():
    app.logger.debug('request.files=%s', request.files)
    attachments = {}
    for i in range(MAX_ATTACHMENTS):
        attach_key = 'attachment%d' % (i + 1)
        if request.files.get(attach_key):
            with NamedTemporaryFile(prefix='fx-api-attach-') as attach_file:
                request.files[attach_key].save(attach_file.name)
                attach_file.seek(0)
                attachments[request.files[attach_key].filename] = {
                    'filedata': attach_file.read(),
                    }
                attach_file.close()

    with NamedTemporaryFile(prefix='fx-api-xml-', suffix='.xml') as xml_file:
        request.files['xml'].save(xml_file.name)
        app.logger.debug('xml_file.name=%s', xml_file.name)
        xml_file.seek(0)
        xml_byte = xml_file.read()
        xml_file.close()
    res = ''
    with NamedTemporaryFile(prefix='fx-api-pdf-', suffix='.pdf') as pdf_file:
        with NamedTemporaryFile(
                prefix='fx-api-outpdf-', suffix='.pdf') as output_pdf_file:
            request.files['pdf'].save(pdf_file.name)
            app.logger.debug('pdf_file.name=%s', pdf_file.name)
            app.logger.debug('output_pdf_file.name=%s', output_pdf_file.name)
            app.logger.debug('attachments keys=%s', attachments.keys())
            generate_from_file(
                pdf_file, xml_byte, output_pdf_file=output_pdf_file.name,
                attachments=attachments)
            output_pdf_file.seek(0)
            res = send_file(output_pdf_file.name, as_attachment=True)
            app.logger.info(
                'Factur-X or Order-X document successfully returned by webservice')
            output_pdf_file.close()
        pdf_file.close()
    return res


def main(args=None):
    if args is None:
        args = sys.argv[1:]
    usage = "facturx_webservice.py [options]"
    epilog = "Script written by Alexis de Lattre. "\
        "Published under the BSD licence."
    description = "This is a Flask application that exposes a REST "\
        "webservice to generate a Factur-X invoice from a PDF file and an "\
        "XML file."
    parser = argparse.ArgumentParser(
        usage=usage, epilog=epilog, description=description)
    parser.add_argument(
        '-s', '--host', dest='host', default='127.0.0.1',
        help="The hostname to listen on. Defaults to '127.0.0.1': "
             "the webservice will only accept connexions from localhost. Use "
             "'0.0.0.0' to have the webservice available from a remote host (but "
             "it is recommended to listen on localhost and use an HTTPS proxy to "
             "listen to remote connexions).")
    parser.add_argument(
        '-p', '--port', dest='port', type=int, default=5000,
        help="Port on which the webservice listens. You can select "
             "any port between 1024 and 65535. Default port is 5000.")
    parser.add_argument(
        '-d', '--debug', dest='debug', action='store_true',
        help="Enable debug mode.")
    parser.add_argument(
        '-l', '--logfile', dest='logfile',
        help="Logs to a file instead of stdout.")
    parser.add_argument(
        '-n', '--loglevel', dest='loglevel', default='info',
        help="Log level. Possible values: critical, error, warning, "
             "info (default), debug.")
    args = parser.parse_args()
    if args.logfile:
        formatter = logging.Formatter(
            "[%(asctime)s] %(levelname)s %(message)s")
        handler = RotatingFileHandler(args.logfile)
        if args.loglevel == 'debug':
            level = logging.DEBUG
        elif args.loglevel == 'critical':
            level = logging.CRITICAL
        elif args.loglevel == 'warning':
            level = logging.WARNING
        elif args.loglevel == 'error':
            level = logging.ERROR
        else:
            level = logging.INFO
        handler.setLevel(level)
        handler.setFormatter(formatter)
        fxlogger.setLevel(level)
        fxlogger.addHandler(handler)
        app.logger.addHandler(handler)
        app.logger.info('Start webservice to generate Factur-X invoices')
    fxlogger.info('webservice version %s using factur-x lib version %s', __version__, fxversion)
    app.run(debug=args.debug, port=args.port, host=args.host)


def run():
    if __name__ == '__main__':
        main()


run()
