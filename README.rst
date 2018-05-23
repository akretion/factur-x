Factur-X Python library
=======================

Factur-X is the e-invoicing standard for France and Germany. The Factur-X specifications are available on the `FNFE-MPE website <http://fnfe-mpe.org/factur-x/>`_. The Factur-X standard is also called ZUGFeRD 2.0 in Germany.

The main feature of this Python library is to generate Factur-X invoices from a regular PDF invoice and a Factur-X compliant XML file.

This lib provides additionnal features such as:

* extract the Factur-X XML file from a Factur-X PDF invoice,
* check a Factur-X XML file against the official XML Schema Definition.

Some of the features provided by this lib also work for ZUGFeRD 1.0 (the ancestor of the Factur-X standard).

Installation
============

.. code::

  sudo pip install --upgrade factur-x


Usage
=====

.. code::

  from facturx import generate_facturx

  facturx_pdf_invoice = generate_facturx(regular_pdf_invoice, facturx_xml_file)


To have more examples, look at the source code of the command line tools located in the *bin* subdirectory.

Command line tools
==================

Several command line tools are provided with this lib:

* **facturx-pdfgen**: generate a Factur-X PDF invoice from a regular PDF invoice and an XML file
* **facturx-pdfextractxml**: extract the Factur-X XML file from a Factur-X PDF invoice
* **facturx-xmlcheck**: check a Factur-X XML file against the official Factur-X XML Schema Definition

All these commande line tools have a **-h** option that explains how to use them and shows all the available options.

Licence
=======

This library is published under the BSD licence (same licence as `PyPDF2 <http://mstamy2.github.io/PyPDF2/>`_ on which this lib depends).

Contributors
============

* Alexis de Lattre <alexis.delattre@akretion.com>

Changelog
=========

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
