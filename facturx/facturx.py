# -*- coding: utf-8 -*-
# © 2016-2017, Alexis de Lattre <alexis.delattre@akretion.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * The name of the authors may not be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# TODO list:
# - have both python2 and python3 support
# - add automated tests (currently, we only have tests at odoo module level)

from io import BytesIO
from lxml import etree
from tempfile import NamedTemporaryFile
from datetime import datetime
from PyPDF2 import PdfFileWriter, PdfFileReader
from PyPDF2.generic import DictionaryObject, DecodedStreamObject,\
    NameObject, createStringObject, ArrayObject
from pkg_resources import resource_filename
import logging

FORMAT = '%(asctime)s [%(levelname)s] %(message)s'
logging.basicConfig(format=FORMAT)
logger = logging.getLogger('factur-x')
logger.setLevel(logging.INFO)

FACTURX_FILENAME = 'factur-x.xml'
FACTURX_LEVEL2xsd = {
    'minimum': 'Factur-X_BASIC_WL.xsd',
    'basicwl': 'Factur-X_BASIC_WL.xsd',
    'basic': 'Factur-X_EN16931.xsd',
    'en16931': 'Factur-X_EN16931.xsd',  # comfort
}
FACTURX_LEVEL2xmp = {
    'minimum': 'MINIMUM',
    'basicwl': 'BASIC WL',
    'basic': 'BASIC',
    'en16931': 'EN 16931',
    }


def check_facturx_xsd(
        facturx_xml, flavor='autodetect', facturx_level='autodetect'):
    """
    Validate the XML file against the XSD
    :param facturx_xml: the Factur-X XML
    :type facturx_xml: string, file or etree object
    :param flavor: possible values: 'factur-x', 'zugferd' or 'autodetect'
    :type flavor: string
    :param facturx_level: the level of the Factur-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a small perf improvement.
    Possible values: minimum, basicwl, basic, en16931.
    :return: True if the XML is valid against the XSD
    raise an error if it is not valid against the XSD
    """
    if not facturx_xml:
        raise ValueError('Missing facturx_xml argument')
    if not isinstance(flavor, (str, unicode)):
        raise ValueError('Wrong type for flavor argument')
    if not isinstance(facturx_level, (type(None), str, unicode)):
        raise ValueError('Wrong type for facturx_level argument')
    facturx_xml_etree = None
    if isinstance(facturx_xml, str):
        xml_string = facturx_xml
    elif isinstance(facturx_xml, unicode):
        xml_string = facturx_xml.encode('utf8')
    elif isinstance(facturx_xml, type(etree.Element('pouet'))):
        facturx_xml_etree = facturx_xml
        xml_string = etree.tostring(
            facturx_xml, pretty_print=True, encoding='UTF-8',
            xml_declaration=True)
    elif isinstance(facturx_xml, file):
        facturx_xml.seek(0)
        xml_string = facturx_xml.read()
        facturx_xml.close()

    if flavor not in ('factur-x', 'facturx', 'zugferd'):  # autodetect
        if facturx_xml_etree is None:
            try:
                facturx_xml_etree = etree.fromstring(xml_string)
            except Exception as e:
                raise Exception(
                    "The XML syntax is invalid: %s." % unicode(e))
        flavor = get_facturx_flavor(facturx_xml_etree)
    if flavor in ('factur-x', 'facturx'):
        if facturx_level not in FACTURX_LEVEL2xsd:
            if facturx_xml_etree is None:
                try:
                    facturx_xml_etree = etree.fromstring(xml_string)
                except Exception as e:
                    raise Exception(
                        "The XML syntax is invalid: %s." % unicode(e))
            facturx_level = get_facturx_level(facturx_xml_etree)
        if facturx_level not in FACTURX_LEVEL2xsd:
            raise ValueError(
                "Wrong level '%s' for Factur-X invoice." % facturx_level)
        xsd_filename = FACTURX_LEVEL2xsd[facturx_level]
        xsd_file = resource_filename(
            __name__, 'xsd/factur-x/%s' % xsd_filename)
    elif flavor == 'zugferd':
        xsd_file = resource_filename(
            __name__, 'xsd/xsd-zugferd/ZUGFeRD1p0.xsd')
    xsd_etree_obj = etree.parse(open(xsd_file))
    official_schema = etree.XMLSchema(xsd_etree_obj)
    try:
        t = etree.parse(BytesIO(xml_string))
        official_schema.assertValid(t)
        logger.info('Factur-X XML file successfully validated against XSD')
    except Exception as e:
        # if the validation of the XSD fails, we arrive here
        logger.error(
            "The XML file is invalid against the XML Schema Definition")
        logger.error(xml_string)
        raise Exception(
            "The %s XML file is not valid against the official "
            "XML Schema Definition. The XML file and the "
            "full error have been written in the server logs. "
            "Here is the error, which may give you an idea on the "
            "cause of the problem: %s." % (flavor.capitalize(), unicode(e)))
    return True


def get_facturx_xml_from_pdf(pdf_invoice, check_xsd=True):
    if not pdf_invoice:
        raise ValueError('Missing pdf_invoice argument')
    if not isinstance(check_xsd, bool):
        raise ValueError('Missing pdf_invoice argument')
    if isinstance(pdf_invoice, str):
        pdf_file = BytesIO(pdf_invoice)
    elif isinstance(pdf_invoice, file):
        pdf_file = pdf_invoice
    else:
        raise TypeError(
            "The first argument of the method get_facturx_xml_from_pdf must "
            "be either a string or a file (it is a %s)." % type(pdf_invoice))
    xml_string = xml_filename = False
    try:
        pdf = PdfFileReader(pdf_file)
        pdf_root = pdf.trailer['/Root']
        logger.debug('pdf_root=%s', pdf_root)
        embeddedfiles = pdf_root['/Names']['/EmbeddedFiles']['/Names']
        i = 0
        for embeddedfile in embeddedfiles[:-1]:
            if embeddedfile in (FACTURX_FILENAME, 'ZUGFeRD-invoice.xml'):
                xml_file_dict = embeddedfiles[i+1].getObject()
                logger.debug('xml_file_dict=%s', xml_file_dict)
                tmp_xml_string = xml_file_dict['/EF']['/F'].getData()
                xml_root = etree.fromstring(tmp_xml_string)
                logger.info(
                    'A valid XML file %s has been found in the PDF file',
                    embeddedfile)
                if check_xsd:
                    check_facturx_xsd(xml_root)
                    xml_string = tmp_xml_string
                    xml_filename = embeddedfile
                else:
                    xml_string = tmp_xml_string
                    xml_filename = embeddedfile
                break
    except:
        logger.error('No valid XML file found in the PDF')
        return (None, None)
    logger.info('Returning an XML file %s', xml_filename)
    logger.debug('Content of the XML file: %s', xml_string)
    return (xml_filename, xml_string)


def _get_pdf_timestamp():
    now_dt = datetime.now()
    # example date format: "D:20141006161354+02'00'"
    pdf_date = now_dt.strftime("D:%Y%m%d%H%M%S+00'00'")
    return pdf_date


def _get_metadata_timestamp():
    now_dt = datetime.now()
    # example format : 2014-07-25T14:01:22+02:00
    meta_date = now_dt.strftime('%Y-%m-%dT%H:%M:%S+00:00')
    return meta_date


def _prepare_pdf_metadata_txt(pdf_metadata):
    pdf_date = _get_pdf_timestamp()
    info_dict = {
        '/Author': pdf_metadata.get('author', ''),
        '/CreationDate': pdf_date,
        '/Creator': u'factur-x Python lib by Alexis de Lattre',
        '/Keywords': pdf_metadata.get('keywords', ''),
        '/ModDate': pdf_date,
        '/Subject': pdf_metadata.get('subject', ''),
        '/Title': pdf_metadata.get('title', ''),
        }
    return info_dict


def _prepare_pdf_metadata_xml(facturx_level, pdf_metadata):
    nsmap_rdf = {'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'}
    nsmap_dc = {'dc': 'http://purl.org/dc/elements/1.1/'}
    nsmap_pdf = {'pdf': 'http://ns.adobe.com/pdf/1.3/'}
    nsmap_xmp = {'xmp': 'http://ns.adobe.com/xap/1.0/'}
    nsmap_pdfaid = {'pdfaid': 'http://www.aiim.org/pdfa/ns/id/'}
    nsmap_fx = {
        'fx': 'urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#'}
    ns_dc = '{%s}' % nsmap_dc['dc']
    ns_rdf = '{%s}' % nsmap_rdf['rdf']
    ns_pdf = '{%s}' % nsmap_pdf['pdf']
    ns_xmp = '{%s}' % nsmap_xmp['xmp']
    ns_pdfaid = '{%s}' % nsmap_pdfaid['pdfaid']
    ns_fx = '{%s}' % nsmap_fx['fx']
    ns_xml = '{http://www.w3.org/XML/1998/namespace}'

    root = etree.Element(ns_rdf + 'RDF', nsmap=nsmap_rdf)
    desc_pdfaid = etree.SubElement(
        root, ns_rdf + 'Description', nsmap=nsmap_pdfaid)
    desc_pdfaid.set(ns_rdf + 'about', '')
    etree.SubElement(
        desc_pdfaid, ns_pdfaid + 'part').text = '3'
    etree.SubElement(
        desc_pdfaid, ns_pdfaid + 'conformance').text = 'B'
    desc_dc = etree.SubElement(
        root, ns_rdf + 'Description', nsmap=nsmap_dc)
    desc_dc.set(ns_rdf + 'about', '')
    dc_title = etree.SubElement(desc_dc, ns_dc + 'title')
    dc_title_alt = etree.SubElement(dc_title, ns_rdf + 'Alt')
    dc_title_alt_li = etree.SubElement(
        dc_title_alt, ns_rdf + 'li')
    dc_title_alt_li.text = pdf_metadata.get('title', '')
    dc_title_alt_li.set(ns_xml + 'lang', 'x-default')
    dc_creator = etree.SubElement(desc_dc, ns_dc + 'creator')
    dc_creator_seq = etree.SubElement(dc_creator, ns_rdf + 'Seq')
    etree.SubElement(
        dc_creator_seq, ns_rdf + 'li').text = pdf_metadata.get('author', '')
    dc_desc = etree.SubElement(desc_dc, ns_dc + 'description')
    dc_desc_alt = etree.SubElement(dc_desc, ns_rdf + 'Alt')
    dc_desc_alt_li = etree.SubElement(
        dc_desc_alt, ns_rdf + 'li')
    dc_desc_alt_li.text = pdf_metadata.get('subject', '')
    dc_desc_alt_li.set(ns_xml + 'lang', 'x-default')
    desc_adobe = etree.SubElement(
        root, ns_rdf + 'Description', nsmap=nsmap_pdf)
    desc_adobe.set(ns_rdf + 'about', '')
    producer = etree.SubElement(
        desc_adobe, ns_pdf + 'Producer')
    producer.text = 'PyPDF2'
    desc_xmp = etree.SubElement(
        root, ns_rdf + 'Description', nsmap=nsmap_xmp)
    desc_xmp.set(ns_rdf + 'about', '')
    creator = etree.SubElement(
        desc_xmp, ns_xmp + 'CreatorTool')
    creator.text = 'factur-x python lib by Alexis de Lattre'
    timestamp = _get_metadata_timestamp()
    etree.SubElement(desc_xmp, ns_xmp + 'CreateDate').text = timestamp
    etree.SubElement(desc_xmp, ns_xmp + 'ModifyDate').text = timestamp

    xmp_file = resource_filename(
        __name__, 'xmp/Factur-X_extension_schema.xmp')
    facturx_ext_schema_root = etree.parse(open(xmp_file))
    # The Factur-X extension schema must be embedded into each PDF document
    facturx_ext_schema_desc_xpath = facturx_ext_schema_root.xpath(
        '//rdf:Description', namespaces=nsmap_rdf)
    root.append(facturx_ext_schema_desc_xpath[1])
    # Now is the Factur-X description tag
    facturx_desc = etree.SubElement(
        root, ns_rdf + 'Description', nsmap=nsmap_fx)
    facturx_desc.set(ns_rdf + 'about', '')
    facturx_desc.set(
        ns_fx + 'ConformanceLevel', FACTURX_LEVEL2xmp[facturx_level])
    facturx_desc.set(ns_fx + 'DocumentFileName', FACTURX_FILENAME)
    facturx_desc.set(ns_fx + 'DocumentType', 'INVOICE')
    facturx_desc.set(ns_fx + 'Version', '1.0')

    xml_str = etree.tostring(
        root, pretty_print=True, encoding="UTF-8", xml_declaration=False)
    logger.debug('metadata XML:')
    logger.debug(xml_str)
    return xml_str


def _facturx_update_metadata_add_attachment(
        pdf_filestream, facturx_xml_str, pdf_metadata, facturx_level):
    '''This method is inspired from the code of the addAttachment()
    method of the PyPDF2 lib'''
    # The entry for the file
    moddate = DictionaryObject()
    moddate.update({
        NameObject('/ModDate'): createStringObject(_get_pdf_timestamp())})
    file_entry = DecodedStreamObject()
    file_entry.setData(facturx_xml_str)
    file_entry.update({
        NameObject("/Type"): NameObject("/EmbeddedFile"),
        NameObject("/Params"): moddate,
        # 2F is '/' in hexadecimal
        NameObject("/Subtype"): NameObject("/text#2Fxml"),
        })
    file_entry_obj = pdf_filestream._addObject(file_entry)
    # The Filespec entry
    efEntry = DictionaryObject()
    efEntry.update({
        NameObject("/F"): file_entry_obj,
        NameObject('/UF'): file_entry_obj,
        })

    fname_obj = createStringObject(FACTURX_FILENAME)
    filespec = DictionaryObject()
    filespec.update({
        NameObject("/AFRelationship"): NameObject("/Alternative"),
        NameObject("/Desc"): createStringObject("Factur-X Invoice"),
        NameObject("/Type"): NameObject("/Filespec"),
        NameObject("/F"): fname_obj,
        NameObject("/EF"): efEntry,
        NameObject("/UF"): fname_obj,
        })
    embeddedFilesNamesDictionary = DictionaryObject()
    embeddedFilesNamesDictionary.update({
        NameObject("/Names"): ArrayObject(
            [fname_obj, pdf_filestream._addObject(filespec)])
        })
    # Then create the entry for the root, as it needs a
    # reference to the Filespec
    embeddedFilesDictionary = DictionaryObject()
    embeddedFilesDictionary.update({
        NameObject("/EmbeddedFiles"): embeddedFilesNamesDictionary
        })
    # Update the root
    metadata_xml_str = _prepare_pdf_metadata_xml(facturx_level, pdf_metadata)
    metadata_file_entry = DecodedStreamObject()
    metadata_file_entry.setData(metadata_xml_str)
    metadata_value = pdf_filestream._addObject(metadata_file_entry)
    af_value = pdf_filestream._addObject(
        ArrayObject([pdf_filestream._addObject(filespec)]))
    pdf_filestream._root_object.update({
        NameObject("/AF"): af_value,
        NameObject("/Metadata"): metadata_value,
        NameObject("/Names"): embeddedFilesDictionary,
        })
    metadata_txt_dict = _prepare_pdf_metadata_txt(pdf_metadata)
    pdf_filestream.addMetadata(metadata_txt_dict)


def _extract_base_info(facturx_xml_etree):
    namespaces = facturx_xml_etree.nsmap
    date_xpath = facturx_xml_etree.xpath(
        '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString',
        namespaces=namespaces)
    date = date_xpath[0].text
    date_dt = datetime.strptime(date, '%Y%m%d')
    inv_num_xpath = facturx_xml_etree.xpath(
        '//rsm:ExchangedDocument/ram:ID', namespaces=namespaces)
    inv_num = inv_num_xpath[0].text
    seller_xpath = facturx_xml_etree.xpath(
        '//ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:Name',
        namespaces=namespaces)
    seller = seller_xpath[0].text
    doc_type_xpath = facturx_xml_etree.xpath(
        '//rsm:ExchangedDocument/ram:TypeCode', namespaces=namespaces)
    doc_type = doc_type_xpath[0].text
    base_info = {
        'seller': seller,
        'number': inv_num,
        'date': date_dt,
        'doc_type': doc_type,
        }
    logger.debug('Extraction of base_info: %s', base_info)
    return base_info


def _base_info2pdf_metadata(base_info):
    if base_info['doc_type'] == '381':
        doc_type_name = u'Refund'
    else:
        doc_type_name = u'Invoice'
    date_str = datetime.strftime(base_info['date'], '%Y-%m-%d')
    title = '%s: %s %s' % (
        base_info['seller'], doc_type_name, base_info['number'])
    subject = 'Factur-X %s %s dated %s issued by %s' % (
        doc_type_name, base_info['number'], date_str, base_info['seller'])
    pdf_metadata = {
        'author': base_info['seller'],
        'keywords': u'%s, Factur-X' % doc_type_name,
        'title': title,
        'subject': subject,
        }
    logger.debug('Converted base_info to pdf_metadata: %s', pdf_metadata)
    return pdf_metadata


def get_facturx_level(facturx_xml_etree):
    if not isinstance(facturx_xml_etree, type(etree.Element('pouet'))):
        raise ValueError('facturx_xml_etree must be an etree.Element() object')
    namespaces = facturx_xml_etree.nsmap
    doc_id_xpath = facturx_xml_etree.xpath(
        "//rsm:ExchangedDocumentContext"
        "/ram:GuidelineSpecifiedDocumentContextParameter"
        "/ram:ID", namespaces=namespaces)
    if not doc_id_xpath:
        raise ValueError(
            "This XML is not a Factur-X XML because it misses the XML tag "
            "ExchangedDocumentContext/"
            "GuidelineSpecifiedDocumentContextParameter/ID.")
    doc_id = doc_id_xpath[0].text
    level = doc_id.split(':')[-1]
    if level not in FACTURX_LEVEL2xmp:
        level = doc_id.split(':')[-2]
    if level not in FACTURX_LEVEL2xmp:
        raise ValueError(
            "Invalid Factur-X URN: '%s'" % doc_id)
    logger.info('Factur-X level is %s (autodetected)', level)
    return level


def get_facturx_flavor(facturx_xml_etree):
    if not isinstance(facturx_xml_etree, type(etree.Element('pouet'))):
        raise ValueError('facturx_xml_etree must be an etree.Element() object')
    if facturx_xml_etree.tag.startswith('{urn:un:unece:uncefact:'):
        flavor = 'factur-x'
    elif facturx_xml_etree.tag.startswith('{urn:ferd:'):
        flavor = 'zugferd'
    else:
        raise Exception(
            "Could not detect if the invoice is a Factur-X or ZUGFeRD "
            "invoice.")
    logger.info('Factur-X flavor is %s (autodetected)', flavor)
    return flavor


def generate_facturx_from_binary(
        pdf_invoice, facturx_xml, facturx_level='autodetect',
        check_xsd=True, pdf_metadata=None):
    """
    Generate a Factur-X invoice from a regular PDF invoice and a factur-X XML
    file. The method uses a binary as input (the regular PDF invoice) and
    returns a binary as output (the Factur-X PDF invoice).
    :param pdf_invoice: the regular PDF invoice as binary string
    :type pdf_invoice: string
    :param facturx_xml: the Factur-X XML
    :type facturx_xml: string, file or etree object
    :param facturx_level: the level of the Factur-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a very very small perf improvement.
    Possible values: minimum, basicwl, basic, en16931.
    :type facturx_level: string
    :param check_xsd: if enable, checks the Factur-X XML file against the XSD
    (XML Schema Definition). If this step has already been performed
    beforehand, you should disable this feature to avoid a double check
    and get a small performance improvement.
    :type check_xsd: boolean
    :param pdf_metadata: Specify the metadata of the generated Factur-X PDF.
    If pdf_metadata is None (default value), this lib will generate some
    metadata in English by extracting relevant info from the Factur-X XML.
    Here is an example for the pdf_metadata argument:
    pdf_metadata = {
        'author': 'Akretion',
        'keywords': 'Factur-X, Invoice',
        'title': 'Akretion: Invoice I1242',
        'subject':
          'Factur-X invoice I1242 dated 2017-08-17 issued by Akretion',
        }
    If you pass the pdf_metadata argument, you will not use the automatic
    generation based on the extraction of the Factur-X XML file, which will
    bring a very small perf improvement.
    :type pdf_metadata: dict
    :return: The Factur-X PDF file as binary string.
    :rtype: string
    """

    if not isinstance(pdf_invoice, str):
        raise ValueError('pdf_invoice argument must be a string')
    facturx_pdf_invoice = False
    with NamedTemporaryFile(prefix='invoice-facturx-', suffix='.pdf') as f:
        f.write(pdf_invoice)
        generate_facturx_from_file(
            f, facturx_xml, facturx_level=facturx_level,
            check_xsd=check_xsd, pdf_metadata=pdf_metadata)
        f.seek(0)
        facturx_pdf_invoice = f.read()
        f.close()
    return facturx_pdf_invoice


def generate_facturx_from_file(
        pdf_invoice, facturx_xml, facturx_level='autodetect',
        check_xsd=True, pdf_metadata=None, output_pdf_file=None):
    """
    Generate a Factur-X invoice from a regular PDF invoice and a factur-X XML
    file. The method uses a file as input (regular PDF invoice) and re-writes
    the file (Factur-X PDF invoice).
    :param pdf_invoice: the regular PDF invoice as file path
    (type string) or as file object
    :type pdf_invoice: string or file
    :param facturx_xml: the Factur-X XML
    :type facturx_xml: string, file or etree object
    :param facturx_level: the level of the Factur-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a very very small perf improvement.
    Possible values: minimum, basicwl, basic, en16931.
    :type facturx_level: string
    :param check_xsd: if enable, checks the Factur-X XML file against the XSD
    (XML Schema Definition). If this step has already been performed
    beforehand, you should disable this feature to avoid a double check
    and get a small performance improvement.
    :type check_xsd: boolean
    :param pdf_metadata: Specify the metadata of the generated Factur-X PDF.
    If pdf_metadata is None (default value), this lib will generate some
    metadata in English by extracting relevant info from the Factur-X XML.
    Here is an example for the pdf_metadata argument:
    pdf_metadata = {
        'author': 'Akretion',
        'keywords': 'Factur-X, Invoice',
        'title': 'Akretion: Invoice I1242',
        'subject':
          'Factur-X invoice I1242 dated 2017-08-17 issued by Akretion',
        }
    If you pass the pdf_metadata argument, you will not use the automatic
    generation based on the extraction of the Factur-X XML file, which will
    bring a very small perf improvement.
    :param output_pdf_file: File Path to the output Factur-X PDF file
    :type output_pdf_file: string or unicode
    :type pdf_metadata: dict
    :return: Returns True. This method re-writes the input PDF invoice file,
    unless if the output_pdf_file is provided.
    :rtype: bool
    """
    start_chrono = datetime.now()
    logger.debug('1st arg pdf_invoice type=%s', type(pdf_invoice))
    logger.debug('2nd arg facturx_xml type=%s', type(facturx_xml))
    logger.debug('optional arg facturx_level=%s', facturx_level)
    logger.debug('optional arg check_xsd=%s', check_xsd)
    logger.debug('optional arg pdf_metadata=%s', pdf_metadata)
    if not pdf_invoice:
        raise ValueError('Missing pdf_invoice argument')
    if not facturx_xml:
        raise ValueError('Missing facturx_xml argument')
    if not isinstance(facturx_level, (str, unicode)):
        raise ValueError('Wrong facturx_level argument')
    if not isinstance(check_xsd, bool):
        raise ValueError('check_xsd argument must be a boolean')
    if not isinstance(pdf_metadata, (type(None), dict)):
        raise ValueError('pdf_metadata argument must be a dict or None')
    if not isinstance(pdf_metadata, (dict, type(None))):
        raise ValueError('pdf_metadata argument must be a dict or None')
    if not isinstance(output_pdf_file, (type(None), str, unicode)):
        raise ValueError('output_pdf_file argument must be a string or None')
    if isinstance(pdf_invoice, (str, unicode)):
        file_type = 'path'
    else:
        file_type = 'file'
    xml_root = None
    if isinstance(facturx_xml, str):
        xml_string = facturx_xml
    elif isinstance(facturx_xml, unicode):
        xml_string = facturx_xml.encode('utf8')
    elif isinstance(facturx_xml, type(etree.Element('pouet'))):
        xml_root = facturx_xml
        xml_string = etree.tostring(
            xml_root, pretty_print=True, encoding='UTF-8',
            xml_declaration=True)
    elif isinstance(facturx_xml, file):
        facturx_xml.seek(0)
        xml_string = facturx_xml.read()
        facturx_xml.close()
    else:
        raise TypeError(
            "The second argument of the method generate_facturx must be "
            "either a string, an etree.Element() object or a file "
            "(it is a %s)." % type(facturx_xml))
    if pdf_metadata is None:
        if xml_root is None:
            xml_root = etree.fromstring(xml_string)
        base_info = _extract_base_info(xml_root)
        pdf_metadata = _base_info2pdf_metadata(base_info)
    else:
        # clean-up pdf_metadata dict
        for key, value in pdf_metadata.iteritems():
            if not isinstance(value, (str, unicode)):
                pdf_metadata[key] = ''
    facturx_level = facturx_level.lower()
    if facturx_level not in FACTURX_LEVEL2xsd:
        if xml_root is None:
            xml_root = etree.fromstring(xml_string)
        logger.debug('Factur-X level will be autodetected')
        facturx_level = get_facturx_level(xml_root)
    if check_xsd:
        check_facturx_xsd(
            xml_string, flavor='factur-x', facturx_level=facturx_level)
    original_pdf = PdfFileReader(pdf_invoice)
    new_pdf_filestream = PdfFileWriter()
    new_pdf_filestream.appendPagesFromReader(original_pdf)
    _facturx_update_metadata_add_attachment(
        new_pdf_filestream, xml_string, pdf_metadata, facturx_level)
    if output_pdf_file:
        with open(output_pdf_file, 'wb') as output_f:
            new_pdf_filestream.write(output_f)
            output_f.close()
    else:
        if file_type == 'path':
            with open(pdf_invoice, 'wb') as f:
                new_pdf_filestream.write(f)
                f.close()
        elif file_type == 'file':
            new_pdf_filestream.write(pdf_invoice)
    logger.info('%s file added to PDF invoice', FACTURX_FILENAME)
    end_chrono = datetime.now()
    logger.info(
        'Factur-X invoice generated in %s seconds',
        (end_chrono - start_chrono).total_seconds())
    return True
