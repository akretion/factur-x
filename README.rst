Factur-X Python library
=======================

Factur-X is the e-invoicing standard for France and Germany. The Factur-X specifications are available on the `FNFE-MPE website <http://fnfe-mpe.org/factur-x/>`_ in English and French. The Factur-X standard is also called ZUGFeRD 2.0 in Germany.

The main feature of this Python library is to generate Factur-X invoices from a regular PDF invoice and a Factur-X compliant XML file.

This lib provides additionnal features such as:

* extract the Factur-X XML file from a Factur-X PDF invoice,
* check a Factur-X XML file against the official XML Schema Definition.

Some of the features provided by this lib also work for ZUGFeRD 1.0 (the ancestor of the Factur-X standard).

Installation
============

This library works both on python 2.7 and python 3.

To install it for python 3, run:

.. code::

  sudo pip3 install --upgrade factur-x

To install it for python 2.7, run:

.. code::

  sudo pip install --upgrade factur-x

Usage
=====

.. code::

  from facturx import generate_facturx_from_file

  facturx_pdf_invoice = generate_facturx_from_file(regular_pdf_invoice, facturx_xml_file)


To have more examples, look at the source code of the command line tools located in the *bin* subdirectory.

Command line tools
==================

Several command line tools are provided with this lib:

* **facturx-pdfgen**: generate a Factur-X PDF invoice from a regular PDF invoice and an XML file
* **facturx-pdfextractxml**: extract the Factur-X XML file from a Factur-X PDF invoice
* **facturx-xmlcheck**: check a Factur-X XML file against the official Factur-X XML Schema Definition

All these commande line tools have a **-h** option that explains how to use them and shows all the available options.

Webservice
==========

This project also provides a webservice to generate a Factur-X invoice from a regular PDF invoice, the *factur-x.xml* file and additional attachments (if any). This webservice runs on Python3 and uses `Flask <https://www.palletsprojects.com/p/flask/>`_. To run the webservice, run **facturx-webservice** available in the *bin* subdirectory of the project. To query the webservice, you must send an **HTTP POST** request in **multipart/form-data** using the following keys:

* **pdf** -> PDF invoice (required)
* **xml** -> factur-x.xml file (any profile, required)
* **attachment1** -> First attachment (optional)
* **attachment2** -> Second attachment (optional)
* ...

It is recommended to run the webservice behind an HTTPS/HTTP proxy such as `Nginx <https://www.nginx.com/>`_ or `Apache <https://httpd.apache.org/>`_. You will certainly have to increase the default maximum upload size (default value is only 1MB under Nginx!): use the parameter **client_max_body_size** for Nginx and **LimitRequestBody** for Apache.

You can use `curl <https://curl.haxx.se/>`_, a command line tool to send HTTP requests (on Linux Ubuntu/Debian, just install the **curl** package) to generate the request:

.. code::

  curl -X POST -F 'pdf=@/home/me/invoice.pdf' -F 'xml=@/home/me/factur-x.xml' -F 'attachment1=@/home/me/purchase_order.pdf' -o /home/me/facturx_invoice.pdf https://ws.fnfe-mpe.org/generate_facturx

A public instance of this webservice is available on a server of `FNFE-MPE <http://fnfe-mpe.org/>`_ at the URL **https://ws.fnfe-mpe.org/generate_facturx**.

Licence
=======

This library is published under the BSD licence (same licence as `PyPDF4 <https://github.com/claird/PyPDF4/>`_ on which this lib depends).

Contributors
============

* Alexis de Lattre <alexis.delattre@akretion.com>

Changelog
=========

* Version 1.9 dated 2020-02-11

  * Improve Python3 support in get_facturx_xml_from_pdf()

* Version 1.8 dated 2020-01-16

  * New tool facturx-webservice which implements a REST webservice using Flask to generate a Factur-X PDF invoice via a simple POST request.
  * New argument 'attachments' for generate_facturx_from_file() which replaces argument additional_attachments:

    * Possibility to set a filename for the attachment different from filename of the filepath
    * Possibility to set creation dates for attachments
    * Update script facturx-pdfgen to use the new attachments argument

* Version 1.7 dated 2020-01-13

  * Fix bug in release 1.6 in XMP: variables were not replaced by their real value

* Version 1.6 dated 2020-01-09

  * Generate XMP (XML-based PDF metadata) via string replacement instead of using XML lib

* Version 1.5 dated 2019-11-13

  * Fix bug in generate_facturx_from_file() when using argument additional_attachments

* Version 1.4 dated 2019-07-24

  * Update Factur-X XSD to the final version of Factur-X v1.0.04
  * Support XML extraction with ZUGFeRD invoices using 'zugferd-invoice.xml' filename (instead of the filename 'ZUGFeRD-invoice.xml' specified by the standard)

* Version 1.3 dated 2019-06-12

  * Add XSD files for Extended profile in the Python package

* Version 1.2 dated 2019-06-12

  * add support for the Extended profile
  * validate XML for Minimum and Basic WL profiles with the XSD of profile EN 16931, as asked by Cyrille Sautereau
  * minor improvements in the code for /Kids

* Version 1.1 dated 2019-04-22

  * Improve support for embedded files extraction by adding support for /Kids

* Version 1.0 dated 2019-01-26

  * Use PyPDF4 instead of PyPDF2, because there are no new releases of PyPDF2 since May 2016 (cf https://github.com/mstamy2/PyPDF2/wiki/State-of-PyPDF2-and-Future-Plans), and we need a recent version of PyPDF2 to be able to generate fully compliant PDF/A-3 files.

* Version 0.9 dated 2019-01-25

  * Port to python 3 contributed by JoshuaJan (https://github.com/joshuajan)
  * Fix path to ZUGFeRD 1.0 XSD

* Version 0.8 dated 2018-06-10

  * Make pretty_print work for XMP file, for better readability of that file

* Version 0.7 dated 2018-05-24

  * Fix XMP structure under /x:xmpmeta/rdf:RDF/rdf:Description (use XML tags instead of XML attributes)
  * declare PDF-1.6 instead of PDF-1.3 (still declared by default by pyPDF2)

* Version 0.6 dated 2018-05-01

  * Now fully PDF/A-3 compliant with additionnal attachments (tested with veraPDF)
  * facturx-pdfgen: don't overwrite by default and add --overwrite option
  * Add factur-x library version number in metadata creator entry

* Version 0.5 dated 2018-03-29

  * Fix XMP metadata structure
  * Now fully PDF/A-3 compliant when the input PDF file is PDF/A compliant (tested with veraPDF). This implied copying /OutputIntents and /ID datas from source PDF to Factur-X PDF.
  * Fix support for additionnal attachments: they can now all be saved with Acrobat Reader
  * Improve XML extraction from PDF Factur-x file

* Version 0.4 dated 2018-03-27

  * Factur-x specs say /AFRelationship must be /Data (and not /Alternative)
  * Update Factur-X XSD to v1.0 final
  * Add support for additionnal attachments
  * Add factur-x lib version in Creator metadata table
  * Add /PageMode = /UseAttachments, so that the attachments are displayed by default when opening Factur-X PDF invoice with Acrobat Reader
  * Improve and enrich PDF objects (ModDate, CheckSum, Size)
