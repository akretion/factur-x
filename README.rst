Factur-X and Order-X Python library
===================================

Factur-X is a Franco-German e-invoicing standard which complies with the European e-invoicing standard `EN 16931 <https://ec.europa.eu/digital-building-blocks/wikis/display/DIGITAL/Obtaining+a+copy+of+the+European+standard+on+eInvoicing>`_. The Factur-X specifications are available on the `FNFE-MPE website <http://fnfe-mpe.org/factur-x/>`_ in English and French. The Factur-X standard is also called `ZUGFeRD 2.2 in Germany <https://www.ferd-net.de/standards/zugferd>`_.

Order-X is the equivalent of Factur-X for purchase orders. The Order-X specifications are available in English on `the FNFE-MPE website <https://fnfe-mpe.org/factur-x/order-x/>`_ and on the `FeRD website <https://www.ferd-net.de/standards/order-x>`_.

The main feature of this Python library is to generate Factur-X invoices and Order-X orders from a regular PDF document and a Factur-X or Order-X compliant XML file.

This lib provides additionnal features such as:

* extract the XML file from a Factur-X or Order-X PDF file,
* check a Factur-X or Order-X XML file against the official `XML Schema Definition <https://en.wikipedia.org/wiki/XML_Schema_(W3C)>`_.

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

Changelog
=========

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
