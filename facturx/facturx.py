# -*- coding: utf-8 -*-
# Copyright 2016-2018, Alexis de Lattre <alexis.delattre@akretion.com>
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
# - keep original metadata by copy of pdf_tailer[/Info] ?

from ._version import __version__
from io import BytesIO
from lxml import etree
from tempfile import NamedTemporaryFile
from datetime import datetime
from PyPDF2 import PdfFileWriter, PdfFileReader
from PyPDF2.generic import DictionaryObject, DecodedStreamObject,\
    NameObject, createStringObject, ArrayObject
from PyPDF2.utils import b_
from pkg_resources import resource_filename
import os.path
import mimetypes
import hashlib
import logging

FORMAT = '%(asctime)s [%(levelname)s] %(message)s'
logging.basicConfig(format=FORMAT)
logger = logging.getLogger('factur-x')
logger.setLevel(logging.INFO)

FACTURX_FILENAME = 'factur-x.xml'
FACTURX_LEVEL2xsd = {
    'minimum': 'FACTUR-X_BASIC-WL.xsd',
    'basicwl': 'FACTUR-X_BASIC-WL.xsd',
    'basic': 'FACTUR-X_EN16931.xsd',
    'en16931': 'FACTUR-X_EN16931.xsd',  # comfort
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
        logger.error('XSD Error: %s', e)
        raise Exception(
            "The %s XML file is not valid against the official "
            "XML Schema Definition. "
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
        logger.debug('embeddedfiles=%s', embeddedfiles)
        # embeddedfiles must contain an even number of elements
        if len(embeddedfiles) % 2 != 0:
            raise
        embeddedfiles_by_two = zip(embeddedfiles, embeddedfiles[1:])[::2]
        logger.debug('embeddedfiles_by_two=%s', embeddedfiles_by_two)
        for (filename, file_obj) in embeddedfiles_by_two:
            logger.debug('found filename=%s', filename)
            if filename in (FACTURX_FILENAME, 'ZUGFeRD-invoice.xml'):
                xml_file_dict = file_obj.getObject()
                logger.debug('xml_file_dict=%s', xml_file_dict)
                tmp_xml_string = xml_file_dict['/EF']['/F'].getData()
                xml_root = etree.fromstring(tmp_xml_string)
                logger.info(
                    'A valid XML file %s has been found in the PDF file',
                    filename)
                if check_xsd:
                    check_facturx_xsd(xml_root)
                    xml_string = tmp_xml_string
                    xml_filename = filename
                else:
                    xml_string = tmp_xml_string
                    xml_filename = filename
                break
    except:
        logger.error('No valid XML file found in the PDF')
        return (None, None)
    logger.info('Returning an XML file %s', xml_filename)
    logger.debug('Content of the XML file: %s', xml_string)
    return (xml_filename, xml_string)


def _get_pdf_timestamp(date=None):
    if date is None:
        date = datetime.now()
    # example date format: "D:20141006161354+02'00'"
    pdf_date = date.strftime("D:%Y%m%d%H%M%S+00'00'")
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
        '/Creator':
        u'factur-x Python lib v%s by Alexis de Lattre' % __version__,
        '/Keywords': pdf_metadata.get('keywords', ''),
        '/ModDate': pdf_date,
        '/Subject': pdf_metadata.get('subject', ''),
        '/Title': pdf_metadata.get('title', ''),
        }
    return info_dict


def _prepare_pdf_metadata_xml(facturx_level, pdf_metadata):
    nsmap_x = {'x': 'adobe:ns:meta/'}
    nsmap_rdf = {'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'}
    nsmap_dc = {'dc': 'http://purl.org/dc/elements/1.1/'}
    nsmap_pdf = {'pdf': 'http://ns.adobe.com/pdf/1.3/'}
    nsmap_xmp = {'xmp': 'http://ns.adobe.com/xap/1.0/'}
    nsmap_pdfaid = {'pdfaid': 'http://www.aiim.org/pdfa/ns/id/'}
    nsmap_fx = {
        'fx': 'urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#'}
    ns_x = '{%s}' % nsmap_x['x']
    ns_dc = '{%s}' % nsmap_dc['dc']
    ns_rdf = '{%s}' % nsmap_rdf['rdf']
    ns_pdf = '{%s}' % nsmap_pdf['pdf']
    ns_xmp = '{%s}' % nsmap_xmp['xmp']
    ns_pdfaid = '{%s}' % nsmap_pdfaid['pdfaid']
    ns_fx = '{%s}' % nsmap_fx['fx']
    ns_xml = '{http://www.w3.org/XML/1998/namespace}'

    root = etree.Element(ns_x + 'xmpmeta', nsmap=nsmap_x)
    rdf = etree.SubElement(
        root, ns_rdf + 'RDF', nsmap=nsmap_rdf)
    desc_pdfaid = etree.SubElement(
        rdf, ns_rdf + 'Description', nsmap=nsmap_pdfaid)
    desc_pdfaid.set(ns_rdf + 'about', '')
    etree.SubElement(
        desc_pdfaid, ns_pdfaid + 'part').text = '3'
    etree.SubElement(
        desc_pdfaid, ns_pdfaid + 'conformance').text = 'B'
    desc_dc = etree.SubElement(
        rdf, ns_rdf + 'Description', nsmap=nsmap_dc)
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
        rdf, ns_rdf + 'Description', nsmap=nsmap_pdf)
    desc_adobe.set(ns_rdf + 'about', '')
    producer = etree.SubElement(
        desc_adobe, ns_pdf + 'Producer')
    producer.text = 'PyPDF2'
    desc_xmp = etree.SubElement(
        rdf, ns_rdf + 'Description', nsmap=nsmap_xmp)
    desc_xmp.set(ns_rdf + 'about', '')
    creator = etree.SubElement(
        desc_xmp, ns_xmp + 'CreatorTool')
    creator.text = 'factur-x python lib v%s by Alexis de Lattre' % __version__
    timestamp = _get_metadata_timestamp()
    etree.SubElement(desc_xmp, ns_xmp + 'CreateDate').text = timestamp
    etree.SubElement(desc_xmp, ns_xmp + 'ModifyDate').text = timestamp

    xmp_file = resource_filename(
        __name__, 'xmp/Factur-X_extension_schema.xmp')
    facturx_ext_schema_root = etree.parse(open(xmp_file))
    # The Factur-X extension schema must be embedded into each PDF document
    facturx_ext_schema_desc_xpath = facturx_ext_schema_root.xpath(
        '//rdf:Description', namespaces=nsmap_rdf)
    rdf.append(facturx_ext_schema_desc_xpath[1])
    # Now is the Factur-X description tag
    facturx_desc = etree.SubElement(
        rdf, ns_rdf + 'Description', nsmap=nsmap_fx)
    facturx_desc.set(ns_rdf + 'about', '')
    fx_doc_type = etree.SubElement(
        facturx_desc, ns_fx + 'DocumentType', nsmap=nsmap_fx)
    fx_doc_type.text = 'INVOICE'
    fx_doc_filename = etree.SubElement(
        facturx_desc, ns_fx + 'DocumentFileName', nsmap=nsmap_fx)
    fx_doc_filename.text = FACTURX_FILENAME
    fx_doc_version = etree.SubElement(
        facturx_desc, ns_fx + 'Version', nsmap=nsmap_fx)
    fx_doc_version.text = '1.0'
    fx_conformance_level = etree.SubElement(
        facturx_desc, ns_fx + 'ConformanceLevel', nsmap=nsmap_fx)
    fx_conformance_level.text = FACTURX_LEVEL2xmp[facturx_level]

    # TODO: should be UTF-16be ??
    xml_str = etree.tostring(
        root, pretty_print=True, encoding="UTF-8", xml_declaration=False)
    head = u'<?xpacket begin="\ufeff" id="W5M0MpCehiHzreSzNTczkc9d"?>'.encode(
        'utf-8')
    tail = u'<?xpacket end="w"?>'.encode('utf-8')
    xml_final_str = head + xml_str + tail
    logger.debug('metadata XML:')
    logger.debug(xml_final_str)
    return xml_final_str


# def createByteObject(string):
#    string_to_encode = u'\ufeff' + string
#    x = string_to_encode.encode('utf-16be')
#    return ByteStringObject(x)


def _filespec_additional_attachments(
        pdf_filestream, name_arrayobj_cdict, file_dict, file_bin):
    filename = file_dict['filename']
    logger.debug('_filespec_additional_attachments filename=%s', filename)
    mod_date_pdf = _get_pdf_timestamp(file_dict['mod_date'])
    md5sum = hashlib.md5(file_bin).hexdigest()
    md5sum_obj = createStringObject(md5sum)
    params_dict = DictionaryObject({
        NameObject('/CheckSum'): md5sum_obj,
        NameObject('/ModDate'): createStringObject(mod_date_pdf),
        NameObject('/Size'): NameObject(str(len(file_bin))),
        })
    file_entry = DecodedStreamObject()
    file_entry.setData(file_bin)
    file_mimetype = mimetypes.guess_type(filename)[0]
    if not file_mimetype:
        file_mimetype = 'application/octet-stream'
    file_mimetype_insert = '/' + file_mimetype.replace('/', '#2f')
    file_entry.update({
        NameObject("/Type"): NameObject("/EmbeddedFile"),
        NameObject("/Params"): params_dict,
        NameObject("/Subtype"): NameObject(file_mimetype_insert),
        })
    file_entry_obj = pdf_filestream._addObject(file_entry)
    ef_dict = DictionaryObject({
        NameObject("/F"): file_entry_obj,
        })
    fname_obj = createStringObject(filename)
    filespec_dict = DictionaryObject({
        NameObject("/AFRelationship"): NameObject("/Unspecified"),
        NameObject("/Desc"): createStringObject(file_dict.get('desc', '')),
        NameObject("/Type"): NameObject("/Filespec"),
        NameObject("/F"): fname_obj,
        NameObject("/EF"): ef_dict,
        NameObject("/UF"): fname_obj,
        })
    filespec_obj = pdf_filestream._addObject(filespec_dict)
    name_arrayobj_cdict[fname_obj] = filespec_obj


def _facturx_update_metadata_add_attachment(
        pdf_filestream, facturx_xml_str, pdf_metadata, facturx_level,
        output_intents=[], additional_attachments={}):
    '''This method is inspired from the code of the addAttachment()
    method of the PyPDF2 lib'''
    # The entry for the file
    md5sum = hashlib.md5(facturx_xml_str).hexdigest()
    md5sum_obj = createStringObject(md5sum)
    params_dict = DictionaryObject({
        NameObject('/CheckSum'): md5sum_obj,
        NameObject('/ModDate'): createStringObject(_get_pdf_timestamp()),
        NameObject('/Size'): NameObject(str(len(facturx_xml_str))),
        })
    file_entry = DecodedStreamObject()
    file_entry.setData(facturx_xml_str)  # here we integrate the file itself
    file_entry.update({
        NameObject("/Type"): NameObject("/EmbeddedFile"),
        NameObject("/Params"): params_dict,
        # 2F is '/' in hexadecimal
        NameObject("/Subtype"): NameObject("/text#2Fxml"),
        })
    file_entry_obj = pdf_filestream._addObject(file_entry)
    # The Filespec entry
    ef_dict = DictionaryObject({
        NameObject("/F"): file_entry_obj,
        NameObject('/UF'): file_entry_obj,
        })

    fname_obj = createStringObject(FACTURX_FILENAME)
    filespec_dict = DictionaryObject({
        NameObject("/AFRelationship"): NameObject("/Data"),
        NameObject("/Desc"): createStringObject("Factur-X Invoice"),
        NameObject("/Type"): NameObject("/Filespec"),
        NameObject("/F"): fname_obj,
        NameObject("/EF"): ef_dict,
        NameObject("/UF"): fname_obj,
        })
    filespec_obj = pdf_filestream._addObject(filespec_dict)
    name_arrayobj_cdict = {fname_obj: filespec_obj}
    for attach_bin, attach_dict in additional_attachments.items():
        _filespec_additional_attachments(
            pdf_filestream, name_arrayobj_cdict, attach_dict, attach_bin)
    logger.debug('name_arrayobj_cdict=%s', name_arrayobj_cdict)
    name_arrayobj_content_sort = list(
        sorted(name_arrayobj_cdict.items(), key=lambda x: x[0]))
    logger.debug('name_arrayobj_content_sort=%s', name_arrayobj_content_sort)
    name_arrayobj_content_final = []
    af_list = []
    for (fname_obj, filespec_obj) in name_arrayobj_content_sort:
        name_arrayobj_content_final += [fname_obj, filespec_obj]
        af_list.append(filespec_obj)
    embedded_files_names_dict = DictionaryObject({
        NameObject("/Names"): ArrayObject(name_arrayobj_content_final),
        })
    # Then create the entry for the root, as it needs a
    # reference to the Filespec
    embedded_files_dict = DictionaryObject({
        NameObject("/EmbeddedFiles"): embedded_files_names_dict,
        })
    res_output_intents = []
    logger.debug('output_intents=%s', output_intents)
    for output_intent_dict, dest_output_profile_dict in output_intents:
        dest_output_profile_obj = pdf_filestream._addObject(
            dest_output_profile_dict)
        # TODO detect if there are no other objects in output_intent_dest_obj
        # than /DestOutputProfile
        output_intent_dict.update({
            NameObject("/DestOutputProfile"): dest_output_profile_obj,
            })
        output_intent_obj = pdf_filestream._addObject(output_intent_dict)
        res_output_intents.append(output_intent_obj)
    # Update the root
    metadata_xml_str = _prepare_pdf_metadata_xml(facturx_level, pdf_metadata)
    metadata_file_entry = DecodedStreamObject()
    metadata_file_entry.setData(metadata_xml_str)
    metadata_file_entry.update({
        NameObject('/Subtype'): NameObject('/XML'),
        NameObject('/Type'): NameObject('/Metadata'),
        })
    metadata_obj = pdf_filestream._addObject(metadata_file_entry)
    af_value_obj = pdf_filestream._addObject(ArrayObject(af_list))
    pdf_filestream._root_object.update({
        NameObject("/AF"): af_value_obj,
        NameObject("/Metadata"): metadata_obj,
        NameObject("/Names"): embedded_files_dict,
        # show attachments when opening PDF
        NameObject("/PageMode"): NameObject("/UseAttachments"),
        })
    logger.debug('res_output_intents=%s', res_output_intents)
    if res_output_intents:
        pdf_filestream._root_object.update({
            NameObject("/OutputIntents"): ArrayObject(res_output_intents),
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


def _get_original_output_intents(original_pdf):
    output_intents = []
    try:
        pdf_root = original_pdf.trailer['/Root']
        ori_output_intents = pdf_root['/OutputIntents']
        logger.debug('output_intents_list=%s', ori_output_intents)
        for ori_output_intent in ori_output_intents:
            ori_output_intent_dict = ori_output_intent.getObject()
            logger.debug('ori_output_intents_dict=%s', ori_output_intent_dict)
            dest_output_profile_dict =\
                ori_output_intent_dict['/DestOutputProfile'].getObject()
            output_intents.append(
                (ori_output_intent_dict, dest_output_profile_dict))
    except:
        pass
    return output_intents


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
        check_xsd=True, pdf_metadata=None, output_pdf_file=None,
        additional_attachments=None):
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
    :type pdf_metadata: dict
    :param output_pdf_file: File Path to the output Factur-X PDF file
    :type output_pdf_file: string or unicode
    :param additional_attachments: Specify the other files that you want to
    embed in the PDF file. It is a dict where keys are filepath and value
    is the description of the file (as unicode or string).
    :type additional_attachments: dict
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
    logger.debug(
        'optional arg additional_attachments=%s', additional_attachments)
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
    if not isinstance(additional_attachments, (dict, type(None))):
        raise ValueError(
            'additional_attachments argument must be a dict or None')
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
    additional_attachments_read = {}
    if additional_attachments:
        for attach_filepath, attach_desc in additional_attachments.items():
            filename = os.path.basename(attach_filepath)
            mod_timestamp = os.path.getmtime(attach_filepath)
            mod_dt = datetime.fromtimestamp(mod_timestamp)
            with open(attach_filepath, 'r') as fa:
                fa.seek(0)
                additional_attachments_read[fa.read()] = {
                    'filename': filename,
                    'desc': attach_desc,
                    'mod_date': mod_dt,
                    }
                fa.close()
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
    # Extract /OutputIntents obj from original invoice
    output_intents = _get_original_output_intents(original_pdf)
    new_pdf_filestream = PdfFileWriter()
    new_pdf_filestream._header = b_("%PDF-1.6")
    new_pdf_filestream.appendPagesFromReader(original_pdf)

    original_pdf_id = original_pdf.trailer.get('/ID')
    logger.debug('original_pdf_id=%s', original_pdf_id)
    if original_pdf_id:
        new_pdf_filestream._ID = original_pdf_id
        # else : generate some ?
    _facturx_update_metadata_add_attachment(
        new_pdf_filestream, xml_string, pdf_metadata, facturx_level,
        output_intents=output_intents,
        additional_attachments=additional_attachments_read)
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
