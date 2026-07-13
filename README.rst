Factur-X / Order-X / UBL Python library
========================================

Factur-X is a Franco-German e-invoicing standard which complies with the European e-invoicing standard `EN 16931 <https://ec.europa.eu/digital-building-blocks/wikis/display/DIGITAL/Obtaining+a+copy+of+the+European+standard+on+eInvoicing>`_. The Factur-X specifications are available on the `FNFE-MPE website <http://fnfe-mpe.org/factur-x/>`_ in English and French. The Factur-X standard is also called `ZUGFeRD 2.x in Germany <https://www.ferd-net.de/standards/zugferd>`_. A Factur-X invoice is a PDF invoice with a Cross Industry Invoice (CII) XML file embedded in the PDF.

Order-X is the equivalent of Factur-X for purchase orders. The Order-X specifications are available in English on `the FNFE-MPE website <https://fnfe-mpe.org/factur-x/order-x/>`_ and on the `FeRD website <https://www.ferd-net.de/standards/order-x>`_.

UBL (Universal Business Language) is an XML standard written by OASIS to describe invoices, purchase orders, delivery notes, pricelists and many different business documents. UBL version 2.1 has become ISO/IEC 19845:2015. The UBL standard competes with the Cross Industry Invoice (CII) standard, but both are supported by EN-16931.

The main feature of this Python library is to generate Factur-X invoices and Order-X orders from a regular PDF document and a Factur-X or Order-X compliant XML file.

This lib provides additionnal features such as:

* extract the XML file from a Factur-X or Order-X PDF file,
* check a Factur-X, Order-X or UBL XML file against the official `XML Schema Definition <https://en.wikipedia.org/wiki/XML_Schema_(W3C)>`_ and the official schematrons.
* generate CII XML and UBL XML files from a simple python dictionnary that use EN-16931 tags (BT-1, BT-2, BG-25, ...) as keys.

Some of the features provided by this lib also work for ZUGFeRD 1.0 (the ancestor of the Factur-X standard).

Installation
============

To install it on Linux, run:

.. code::

  sudo pip3 install --upgrade factur-x

Usage
=====

.. code::

  from facturx import generate_from_file

  generate_from_file(regular_pdf_file, xml_file)

The PDF file *regular_pdf_file* will be updated to Factur-X/Order-X. If you want to write the resulting Factur-X/Order-X PDF to another file, use the argument *output_pdf_file*.

To have more examples, look at the docstrings in the source code or look at the source code of the command line tools located in the *bin* subdirectory.

Development
=============

Use hatch
-------------

Install the env with all lib

.. code::

  hatch env create

Execute the test
-------------------

.. code::

  hatch run test:pytest

Command line tools
==================

Several command line tools are provided with this lib:

* **facturx-pdfgen**: generate a Factur-X or Order-X PDF file from a regular PDF file and an XML file
* **facturx-pdfextractxml**: extract the XML file from a Factur-X or Order-X PDF file
* **facturx-xmlcheck**: check a Factur-X or Order-X XML file against the official XML Schema Definition

All these commande line tools have a **--help** option that explains how to use them and shows all the available options.

Tutorial: generate a Factur-X invoice under Windows
===================================================

Download the last version of Python for Windows from `python.org/downloads <https://www.python.org/downloads/>`_.

Launch the installer. On the first screen of the installer, enable the option **Add python.exe to PATH**. At the end of the installation process, the installer displays a screen with the message **Setup was successful** ; at that step, it may propose you **Disable path length limit** with a help message that says *Changes your machine configuration to allow programs, including Python, to bypass the 260 character "MAX_PATH" limitation*. You must accept this proposal (otherwise the installation of the factur-x library will fail): click on the label **Disable path length limit** and follow the instructions.

Open a Windows command prompt as Administrator and enter the following command to download and install the factur-x library:

.. code::

  pip3 install --upgrade factur-x

Look at the installation logs and make sure there are no error messages. Close the Windows command prompt.

Open a new Windows command prompt (not as Administrator) and enter the following command (adapt the path to your filesystem):

.. code::

  python C:\Users\Alexis\AppData\Local\Programs\Python\Python311\Scripts\facturx-pdfgen --help

It should display the help of the command *facturx-pdfgen*.

Enter the following command to generate a Factur-X invoice:

.. code::

  python C:\Users\Alexis\AppData\Local\Programs\Python\Python311\Scripts\facturx-pdfgen C:\Users\Alexis\Documents\invoice.pdf C:\Users\Alexis\Documents\fx.xml C:\Users\Alexis\Documents\invoice-facturx.pdf

where:

* *C:\\Users\\Alexis\\Documents\\invoice.pdf* is the original PDF invoice,
* *C:\\Users\\Alexis\\Documents\\fx.xml* is the Factur-X XML file,
* *C:\\Users\\Alexis\\Documents\\invoice-facturx.pdf* is the Factur-X PDF invoice that will be generated.

Webservice
==========

This project also provides a webservice to generate a Factur-X or Order-X PDF file from a regular PDF file, the XML file and additional attachments (if any). This webservice uses `Flask <https://www.palletsprojects.com/p/flask/>`_. To run the webservice, run **facturx-webservice** available in the *bin* subdirectory of the project. To query the webservice, you must send an **HTTP POST** request in **multipart/form-data** using the following keys:

* **pdf** -> PDF file (required)
* **xml** -> Factur-X or Order-X file (any profile, required)
* **attachment1** -> First attachment (optional)
* **attachment2** -> Second attachment (optional)
* ...

To deploy this webservice in production, follow the `guidelines <https://flask.palletsprojects.com/en/2.3.x/deploying/>`_ of the official Flask documentation: you should use a WSGI server (such as `Gunicorn <https://gunicorn.org/>`_) and a reverse proxy (such as `Nginx <https://www.nginx.com/>`_ or `Apache <https://httpd.apache.org/>`_). You will certainly have to increase the default maximum upload size (default value is only 1MB under Nginx!): use the parameter **client_max_body_size** for Nginx and **LimitRequestBody** for Apache.

I recommend this `tutorial <https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-gunicorn-and-nginx-on-ubuntu-20-04-fr>`_ (in French) which explains how to deploy a Flask application with Gunicorn and Nginx on Ubuntu.

You can use `curl <https://curl.haxx.se/>`_, a command line tool to send HTTP requests (on Linux Ubuntu/Debian, just install the **curl** package) to generate the request:

.. code::

  curl -X POST -F 'pdf=@/home/me/regular_invoice.pdf' -F 'xml=@/home/me/factur-x.xml' -F 'attachment1=@/home/me/delivery_note.pdf' -o /home/me/facturx_invoice.pdf https://ws.fnfe-mpe.org/generate_facturx

A public instance of this webservice is available on a server of `FNFE-MPE <http://fnfe-mpe.org/>`_ at the URL **https://ws.fnfe-mpe.org/generate_facturx**.

Licence
=======

This library is published under the BSD licence (same licence as `pypdf <https://github.com/py-pdf/pypdf/>`_ on which this lib depends).

Contributors
============

* Alexis de Lattre <alexis.delattre@akretion.com>
* Houzéfa Abbasbhay <houzefa.abba@xcg-consulting.fr>

Changelog
=========

* Version 6.4 dated 2026-07-14:

  * add method facturx_schematron_get_codedb_xml_file(level) to get the CodeDB XML file of the Factur-X schematron for a specific level
  * Add argument saxon_server_codedb_base_url to customize the URL where the Saxon Server can get the CodeDB XML file. This is an alternative to the argument saxon_server_codedb_dir with the same purpose: reduce latency of Factur-X schematron check (the base Factur-X schematron XSLT file depends on an external CodeDB XML file).

* Version 6.3 dated 2026-07-13:

  * generate_xml(): change processing of BT-8, to avoid changing the value in data_dict, to allow double use of data_dict to generate both UBL and Factur-X/CII XML.
  * generate_xml(): fix BG-24 in UBL (no DocumentTypeCode=916 like in CII)
  * Update schematron and XSD files from the new `FNFE Github repo <https://github.com/fnfempe/France_RFE>`_ It includes important fixes in UBL schematrons.
  * Fix tests

* Version 6.2 dated 2026-07-10:

  * add support for UBL 2.1 CreditNote in generate_xml(), xml_check_xsd() and get_xml_namespaces(). Beware that flavor "ubl-2.1" is replaced by "ubl-2.1-invoice" and "ubl-2.1-creditnote"

* Version 6.1 dated 2026-07-08:

  * generate_xml(): replace EXT-FR-FE-187 by BT-173, EXT-FR-FE-188 by BT-174, EXT-FR-FE-189 by BT-175 and EXT-FR-FE-190 by BT-176

* Version 6.0 dated 2026-07-08: Remove saxonche and query Saxon Server via HTTP POST request

  * Stop using `saxonche <https://pypi.org/project/saxonche/>`_ (to know why, read `bug #77 <https://github.com/akretion/factur-x/issues/77>`_). Replaced by an HTTP POST query to a `Saxon Server <https://github.com/willemvlh/saxon-server>`_. For Factur-X, there is a small issue linked to the fact that the Factur-X schematron uses an external codeDB XML file, cf `this issue <https://github.com/willemvlh/saxon-server/issues/23>`_. 2 solutions have been implémented to workaround this issue. First solution (by default): replace the CodeDB XML file by a public URL to that the Saxon Server can retreive the CodeDB XML file. This first solution is not ideal because it adds extra latency and requires an Internet connection. The second solution: put a copy of the CodeDB files on the Saxon Server and indicate the path to the directory that contains the CodeDB XML files (via the argument **saxon_server_codedb_dir**). This second solution is better because it doesn't add extra latency and doesn't require an Internet connexion, but it requires some extra work to setup the directory that contains the CodeDB files on the Saxon Server.
  * generate_xml(): Add support for BT-193, BT-177, EXT-FR-FE-178, EXT-FR-FE-179, EXT-FR-FE-187, EXT-FR-FE-188, EXT-FR-FE-189 and EXT-FR-FE-190.
  * generate_xml(): change behavior for BT-110 and BT-111: BT-110 is required, BT-111 is optional (some countries like France make it required when invoicing in a foreign currency)
  * Improve XSD verification code, which should improve performances.
  * Log the XML file when the schematron check fails, to ease debugging.

* Version 5.1 dated 2026-06-30: UBL is gaining maturity. New dependency on `python-stdnum <https://arthurdejong.org/python-stdnum/>`_

  * Add support for UBL in get_flavor(), get_level() and get_xml_namespace()
  * in generate_xml(), stop using BT-84-0 which is Factur-x specific
  * Add extended fields used in XP-Z12-014 in UBL and Factur-X
  * generate_xml(): replace BT-X-xxx by EXT-FR-FE-xxx, which are used both by CII and UBL
  * New option in generate_xml() to use prefixed namespaces or default namespaces
  * Improve tests on generate_xml, add tests on get_flavor() and get_level()
  * Fix double logging (fix designed by Baptiste Ravier)

* Version 5.0 dated 2026-06-25: UBL has just arrived!

  * 3 new methods **generate_ubl_xml()**, **generate_cii_xml()** and **generate_xml()**. The method generate_xml() is a simple wrapper to call either generate_cii_xml() or generate_ubl_xml(). These methods take a python dictionnary with EN16931 tags as keys (BT-1, BT-2, BG-25, ...) and generate the corresponding XML in the profile you asked for. See tests/test_generate_xml.py to have an example of the data structure to use.
  * xml_check_xsd(): add support for UBL 2.1. To use it, set argument flavor='ubl-2.1'.
  * xml_check_schematron(): new argument **check_option** that allows to test against several schematrons and not only the base schematron. For example, if you use check_option='fr-ctc', the XML file will be tested both against the base schematron and the FR-CTC schematron that contains additionnal rules for the French e-invoicing reform. Add support for UBL 2.1.
  * Update Factur-X XSD and schematrons to release 1.0.9.
  * pypdf: replace create_string_object by TextStringObject
  * Make saxonche dependency optional
  * improve logging code (contribution of Baptiste Ravier)

* Version 4.3 dated 2026-05-26 (`OCA code sprint Santander <https://www.aeodoo.org/event/spanish-oca-days-2026-143/page/introduccion-spanish-oca-days-2026>`_)

  * Restore compatibility with lxml 4.6.5
  * Add test infrastructure
  * Fix wrong error message

* Version 4.2 dated 2026-03-23

  * Fix resource leak in the loading of the XSD file for XML schema validation (closes bug #68)

* Version 4.1 dated 2026-03-19

  * Fix compatibility with python < 3.12

* Version 4.0 dated 2026-03-18

  * Add method xml_check_schematron(). It adds a dependency in saxonche.
  * Add named argument check_shematron=True on generate_from_binary(), generate_from_file() and get_xml_from_pdf(). When this new arg is True, it calls the new method xml_check_schematron(). When check_shematron=True, the performance impact is signifiant (it adds about 0.3 seconds on my laptop).
  * Remove deprecated methods check_facturx_xsd(), get_facturx_flavor(), generate_facturx_from_binary() and generate_facturx_from_file(). These methods have been marked as deprecated for 5 years now (since release 2.0 dated April 4th 2021).
  * Update scripts facturx-pdfextractxml and facturx-pdfgen: add option --disable-schematron-check
  * Update script facturx-xmlcheck: add check against schematron after the check against XSD

* Version 3.16 dated 2026-03-13

  * /CheckSum is now a Bytes string object instead of a string object (patch by Adrian Devries)

* Version 3.15 dated 2025-12-05

  * Update XSD files to Factur-X 1.0.8

* Version 3.14 dated 2025-11-18

  * Fix regression in get_level() since release 3.10 caused by a bad understanding of extended-ctc-fr

* Version 3.13 dated 2025-10-31

  * Add support for XRechnung in get_xml_from_pdf(). get_xml_from_pdf() now accepts filenames that don't strictly follow the standard.

* Version 3.12 dated 2025-10-29

  * In the method generate_from_file(), if the second argument (xml) is provided as a string, we now accept
    either a file path as string (like for the first argument) or the XML itself as a string. It was
    difficult for users to admit that, for the first argument, the lib accepted a file path as string but
    not for the second argument.

* Version 3.11 dated 2025-10-29

  * Add an option to disable XMP compression. This is useful if you plan to later add a PAdES signature to the generated PDF file. New named boolean argument **xmp_compression** on generate_from_binary() and generate_from_file(). Option also added to the facturx-pdfgen script (see --help).

* Version 3.10 dated 2025-10-29

  * Fix parsing of the ID tag of the XML file that contains "#" (example:  urn:cen.eu:en16931:2017#conformant#urn.cpro.gouv.fr:1p0:extended-ctc-fr). Fixes bug #55.
  * Fix generation of XMP metadata: change the implementation used since version 1.6 and come back to generation via lxml to avoid issues with special caracters that need special treatment in XML. Fixes bug #57.

* Version 3.9 dated 2025-10-29

  * Update XSD files to Factur-X 1.07.3

* Version 3.8 dated 2025-07-27

  * Import fallback for compatibility with Python 3.8.
    Requires `importlib-resources backport <https://pypi.org/project/importlib-resources/>`_ on Python 3.8.

* Version 3.7 dated 2025-07-27

  * Require pypdf 5.3.0, to have the support for /Kids when listing attachments, cf my `issue 2087 <https://github.com/py-pdf/pypdf/issues/2087>`_ which has been fixed by `pull request 3108 <https://github.com/py-pdf/pypdf/pull/3108>`_. So we now use the high-level API of pypdf to get the attachments instead of our own implementation using the low-level API of pypdf.
  * Add property __version__ on the lib
  * When executing the scripts provided by the lib, log the version of the script and the version of the lib
  * Remove outdated warning in README

* Version 3.6 dated 2024-12-14

  * Fix regression for order-x and zugferd caused by change to support absolute namespace declaration
  * Add new method get_xml_namespaces(flavor)

* Version 3.5 dated 2024-12-14

  * Fix dependency declaration in python package
  * Fix packaging of scripts (was broken since the move from setup.py to pyproject.toml)
  * Add support for absolute namespace declaration in XML file

* Version 3.4 dated 2024-12-04

  * Fix minimum python version: 3.7 (was 3.6) because importlib.resources was added in python 3.7

* Version 3.3 dated 2024-12-02

  * Migrate packaging from setup.py to pyproject.toml
  * Version is now stored in pyproject.toml and python code use it

* Version 3.2 dated 2024-12-02

  * Update to Factur-X XSD version 1.0.7.2 (equivalent to ZUGFeRD 2.3)
  * Don't set flavor autodetection when file is zugferd-invoice.xml (fixes bug #41)

* Version 3.1 dated 2023-08-13

  * Keep bookmarks, annotations, etc. from input PDF file. For that, we use the method clone_document_from_reader() of pypdf instead of append_pages_from_reader()
  * Fix bug on xml type parsing (bug introduced in version 3.0)
  * raise explicit error when trying to generate a ZUGFeRD 1.x PDF invoice

* Version 3.0 dated 2023-08-13

  * Replace dependency on PyPDF4 by pypdf. The development focus is back on **pypdf** and the forks PyPDF2, PyPDF3 and PyPDF4 are not maintained any more, cf this `article <https://martinthoma.medium.com/pypdf-the-2022-review-8925dea750d9>`_.
  * Remove support for Python 2.7
  * In the scripts, replace /usr/bin/python3 by /usr/bin/env python

* Version 2.5 dated 2023-03-24

  * Add support for ZUGFeRD 1.0 in get_level()
  * xml_check_xsd(): avoid warning *Use specific 'len(elem)' or 'elem is not None' test instead.*

* Version 2.4 dated 2023-03-13

  * Update Factur-X XSD of all profiles to version 1.0.6
  * Update Order-X XSD of all profiles to version 1.0.0

* Version 2.3 dated 2021-04-12

  * Fix wrong flavor argument passed by generate_facturx_from_file() to generate_from_file()

* Version 2.2 dated 2021-04-08

  * Make method generate_from_binary() accessible via the lib

* Version 2.1 dated 2021-04-07

  * Update Order-X XSD to the latest version provided to me by FNFE-MPE

* Version 2.0 dated 2021-04-04

  * Add support for **Order-X**. This implies several changes:

    * method *check_facturx_xsd()* deprecated in favor of the new method *xml_check_xsd()* but still operates with a warning
    * method *get_facturx_flavor()* deprecated in favor of the new method *get_flavor()* but still operates with a warning
    * method *generate_facturx_from_binary()* deprecated in favor of the new method *generate_from_binary()* but still operates with a warning
    * method *generate_facturx_from_file()* deprecated in favor of the new method *generate_from_file()* but still operates with a warning
    * new optional argument *orderx_type* for methods *generate_from_file()* and *generate_from_binary()* with default value *autodetect*
    * new method *get_orderx_type()* to get the Order-X type (order, order change or order response)
    * new method *get_xml_from_pdf()* that work both on Factur-X and Order-X (the method get_facturx_xml_from_pdf() still exists and only operates on Factur-X)
    * scripts updated

  * Add **lang** argument to methods *generate_from_file()* and *generate_from_binary()* to set the lang of the PDF. This is one of the requirements for PDF accessibility, which is important for people with disabilities: it allows PDF speech synthesizers for blind people to choose the right language.
  * Add ability to choose the AFRelationship PDF property for the Factur-X/Order-X XML file and also for the additionnal attachments:

    * new argument *afrelationship* for methods *generate_from_file()* and *generate_from_binary()*
    * new key *afrelationship* for the *attachments* dict as argument of *generate_from_file()* and *generate_from_binary()*

  * Argument *additional_attachments* was deprecated in method *generate_facturx_from_file()* in version 1.8: it doesn't operate any more and only displays a warning.
  * Replace the *optparse* lib by the *argparse* lib in scripts.

* Version 1.12 dated 2020-07-16

  * Compress attachments and XMP metadata using Flate compression

* Version 1.11 dated 2020-05-11

  * Fix crash UnicodeEncodeError on Python 2.7

* Version 1.10 dated 2020-04-14

  * Update XSD of all profiles to Factur-X version 1.0.5

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
