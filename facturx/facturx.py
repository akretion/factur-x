# -*- coding: utf-8 -*-
# Copyright 2016-2021, Alexis de Lattre <alexis.delattre@akretion.com>
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
# - add automated tests (currently, we only have tests at odoo module level)
# - keep original metadata by copy of pdf_tailer[/Info] ?

from ._version import __version__
from io import BytesIO
from lxml import etree
from tempfile import NamedTemporaryFile
from datetime import datetime
from PyPDF4 import PdfFileWriter, PdfFileReader
from PyPDF4.generic import DictionaryObject, DecodedStreamObject,\
    NameObject, createStringObject, ArrayObject, IndirectObject
from PyPDF4.utils import b_
from pkg_resources import resource_filename
import os.path
import mimetypes
import hashlib
import logging
import sys
if sys.version_info[0] == 3:
    unicode = str
    from io import IOBase
    file = IOBase


FORMAT = '%(asctime)s [%(levelname)s] %(message)s'
logging.basicConfig(format=FORMAT)
logger = logging.getLogger('factur-x')
logger.setLevel(logging.INFO)

FACTURX_FILENAME = 'factur-x.xml'
ZUGFERD_FILENAMES = ['zugferd-invoice.xml', 'ZUGFeRD-invoice.xml']
ORDERX_FILENAME = 'order-x.xml'
ALL_FILENAMES = [FACTURX_FILENAME] + ZUGFERD_FILENAMES + [ORDERX_FILENAME]
FACTURX_LEVEL2xsd = {
    'minimum': 'facturx-minimum/FACTUR-X_MINIMUM.xsd',
    'basicwl': 'facturx-basicwl/FACTUR-X_BASIC-WL.xsd',
    'basic': 'facturx-basic/FACTUR-X_BASIC.xsd',
    'en16931': 'facturx-en16931/FACTUR-X_EN16931.xsd',
    'extended': 'facturx-extended/FACTUR-X_EXTENDED.xsd',
}
ORDERX_LEVEL2xsd = {
    'basic': 'orderx-basic/SCRDMCCBDACIOMessageStructure_100pD20B.xsd',
    'comfort': 'orderx-comfort/SCRDMCCBDACIOMessageStructure_100pD20B.xsd',
    'extended': 'orderx-extended/SCRDMCCBDACIOMessageStructure_100pD20B.xsd',
    }
FACTURX_LEVEL2xmp = {
    'minimum': 'MINIMUM',
    'basicwl': 'BASIC WL',
    'basic': 'BASIC',
    'en16931': 'EN 16931',
    'extended': 'EXTENDED',
    }
ORDERX_TYPES = ('order', 'order_change', 'order_response')
ORDERX_code2type = {
    '220': 'order',
    '230': 'order_change',
    '231': 'order_response',
    }
XML_AFRelationship = ('data', 'source', 'alternative')
ATTACHMENTS_AFRelationship = ('supplement', 'unspecified')


def check_facturx_xsd(
        facturx_xml, flavor='autodetect', facturx_level='autodetect'):
    logger.warning(
        'check_facturx_xsd() is deprecated. Use xml_check_xsd() instead.')
    return xml_check_xsd(facturx_xml, flavor=flavor, level=facturx_level)


def xml_check_xsd(xml, flavor='autodetect', level='autodetect'):
    """
    Validate the XML file against the XSD
    :param xml: the Factur-X or Order-X XML
    :type xml: string, file or etree object
    :param flavor: possible values: 'factur-x', 'zugferd', 'order-x' or 'autodetect'.
    Value 'zugferd' means ZUGFeRD 1.0.
    :type flavor: string
    :param level: the level of the Factur-X or Order-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a small perf improvement.
    Possible values for Factur-X: minimum, basicwl, basic, en16931, extended.
    Possible values for Order-X: basic, comfort, extended.
    :return: True if the XML is valid against the XSD
    raise an error if it is not valid against the XSD
    """
    logger.debug(
        'xml_check_xsd with factur-x lib %s', __version__)
    if not isinstance(flavor, (str, unicode)):
        raise ValueError('Wrong type for flavor argument')
    if not isinstance(level, (type(None), str, unicode)):
        raise ValueError('Wrong type for level argument')
    xml_etree = None
    if isinstance(xml, (str, bytes)):
        xml_bytes = xml
    elif isinstance(xml, unicode):
        xml_bytes = xml.encode('utf8')
    elif isinstance(xml, type(etree.Element('pouet'))):
        xml_etree = xml
        xml_bytes = etree.tostring(
            xml, pretty_print=True, encoding='UTF-8',
            xml_declaration=True)
    elif isinstance(xml, file):
        xml.seek(0)
        xml_bytes = xml.read()
        xml.close()
    else:
        raise ValueError('Wrong type for xml argument')

    if not xml_bytes:
        raise ValueError('xml argument is empty')

    # autodetect
    if flavor not in ('factur-x', 'facturx', 'zugferd', 'order-x', 'orderx'):
        if xml_etree is None:
            try:
                xml_etree = etree.fromstring(xml_bytes)
            except Exception as e:
                raise Exception(
                    "The XML syntax is invalid: %s." % unicode(e))
        flavor = get_flavor(xml_etree)
    if flavor in ('factur-x', 'facturx'):
        if level not in FACTURX_LEVEL2xsd:
            if xml_etree is None:
                try:
                    xml_etree = etree.fromstring(xml_bytes)
                except Exception as e:
                    raise Exception(
                        "The XML syntax is invalid: %s." % unicode(e))
            level = get_level(xml_etree)
        if level not in FACTURX_LEVEL2xsd:
            raise ValueError(
                "Wrong level '%s' for Factur-X invoice." % level)
        xsd_file = resource_filename(
            __name__, 'xsd/%s' % FACTURX_LEVEL2xsd[level])
    elif flavor == 'zugferd':
        xsd_file = resource_filename(
            __name__, 'xsd/zugferd/ZUGFeRD1p0.xsd')
    elif flavor in ('order-x', 'orderx'):
        if level not in ORDERX_LEVEL2xsd:
            if xml_etree is None:
                try:
                    xml_etree = etree.fromstring(xml_bytes)
                except Exception as e:
                    raise Exception(
                        "The XML syntax is invalid: %s." % unicode(e))
            level = get_level(xml_etree)
        if level not in ORDERX_LEVEL2xsd:
            raise ValueError(
                "Wrong level '%s' for Order-X document." % level)
        xsd_file = resource_filename(
            __name__, 'xsd/%s' % ORDERX_LEVEL2xsd[level])

    logger.debug('Using XSD file %s', xsd_file)
    xsd_etree_obj = etree.parse(open(xsd_file))
    official_schema = etree.XMLSchema(xsd_etree_obj)
    try:
        t = etree.parse(BytesIO(xml_bytes))
        official_schema.assertValid(t)
        logger.info('%s XML file successfully validated against XSD', flavor)
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


def _get_dict_entry(node, entry):
    if not isinstance(node, dict):
        raise ValueError('The node must be a dict')
    dict_entry = node.get(entry)
    if isinstance(dict_entry, dict):
        return dict_entry
    elif isinstance(dict_entry, IndirectObject):
        res_dict_entry = dict_entry.getObject()
        if isinstance(res_dict_entry, dict):
            return res_dict_entry
        else:
            return False
    else:
        return False


def _parse_embeddedfiles_kids_node(kids_node, level, res):
    if level not in [1, 2]:
        raise ValueError('Level argument should be 1 or 2')
    if not isinstance(kids_node, list):
        logger.error(
            'The /Kids entry of the EmbeddedFiles name tree must '
            'be an array')
        return False
    logger.debug("kids_node=%s", kids_node)
    for kid_entry in kids_node:
        if not isinstance(kid_entry, IndirectObject):
            logger.error(
                'The /Kids entry of the EmbeddedFiles name tree '
                'must be a list of IndirectObjects')
            return False
        kids_node = kid_entry.getObject()
        logger.debug('kids_node=%s', kids_node)
        if not isinstance(kids_node, dict):
            logger.error(
                'The /Kids entry of the EmbeddedFiles name tree '
                'must be a list of IndirectObjects that point to '
                'dict objects')
            return False
        if '/Names' in kids_node:
            if not isinstance(kids_node['/Names'], list):
                logger.error(
                    'The /Names entry in EmbeddedFiles must be an array')
                return False
            res += kids_node['/Names']
        elif '/Kids' in kids_node and level == 1:
            kids_node_l2 = kids_node['/Kids']
            _parse_embeddedfiles_kids_node(kids_node_l2, 2, res)
        else:
            logger.error('/Kids node should have a /Names or /Kids entry')
            return False
    return True


def _get_embeddedfiles(embeddedfiles_node):
    if not isinstance(embeddedfiles_node, dict):
        raise ValueError('The EmbeddedFiles node must be a dict')
    res = []
    if '/Names' in embeddedfiles_node:
        if not isinstance(embeddedfiles_node['/Names'], list):
            logger.error(
                'The /Names entry of the EmbeddedFiles name tree must '
                'be an array')
            return False
        res = embeddedfiles_node['/Names']
    elif '/Kids' in embeddedfiles_node:
        kids_node = embeddedfiles_node['/Kids']
        parse_result = _parse_embeddedfiles_kids_node(kids_node, 1, res)
        if parse_result is False:
            return False
    else:
        logger.error(
            'The EmbeddedFiles name tree should have either a /Names '
            'or a /Kids entry')
        return False
    if len(res) % 2 != 0:
        logger.error(
            'The EmbeddedFiles name tree should point to an even number of '
            'elements')
        return False
    return res


def get_facturx_xml_from_pdf(pdf_file, check_xsd=True):
    filenames = [FACTURX_FILENAME] + ZUGFERD_FILENAMES
    return get_xml_from_pdf(pdf_file, check_xsd=check_xsd, filenames=filenames)


def get_orderx_xml_from_pdf(pdf_file, check_xsd=True):
    filenames = [ORDERX_FILENAME]
    return get_xml_from_pdf(pdf_file, check_xsd=check_xsd, filenames=filenames)


def get_xml_from_pdf(pdf_file, check_xsd=True, filenames=[]):
    logger.debug(
        'get_xml_from_pdf with factur-x lib %s', __version__)
    if not pdf_file:
        raise ValueError('Missing pdf_invoice argument')
    if not isinstance(check_xsd, bool):
        raise ValueError('Bad type for check_xsd argument')
    if not isinstance(filenames, list):
        raise ValueError('Bad type for filenames argument')
    if isinstance(pdf_file, (str, bytes)):
        pdf_file_in = BytesIO(pdf_file)
    elif isinstance(pdf_file, file):
        pdf_file_in = pdf_file
    else:
        raise TypeError(
            "The first argument of the method get_xml_from_pdf must "
            "be either a byte or a file (it is a %s)." % type(pdf_file))
    if not filenames:
        filenames = ALL_FILENAMES
    logger.debug('Searching for filenames %s', filenames)
    xml_bytes = xml_filename = False
    pdf = PdfFileReader(pdf_file_in)
    pdf_root = pdf.trailer['/Root']  # = Catalog
    logger.debug('pdf_root=%s', pdf_root)
    catalog_name = _get_dict_entry(pdf_root, '/Names')
    if not catalog_name:
        logger.info('No Names entry in Catalog')
        return (None, None)
    embeddedfiles_node = _get_dict_entry(catalog_name, '/EmbeddedFiles')
    if not embeddedfiles_node:
        logger.info('No EmbeddedFiles entry in the /Names of the Catalog')
        return (None, None)
    embeddedfiles = _get_embeddedfiles(embeddedfiles_node)
    logger.debug('embeddedfiles=%s', embeddedfiles)
    if not embeddedfiles:
        return (None, None)
    embeddedfiles_by_two = list(zip(embeddedfiles, embeddedfiles[1:]))[::2]
    logger.debug('embeddedfiles_by_two=%s', embeddedfiles_by_two)
    try:
        for (filename, file_obj) in embeddedfiles_by_two:
            logger.debug('found filename=%s', filename)
            if filename in filenames:
                xml_file_dict = file_obj.getObject()
                logger.debug('xml_file_dict=%s', xml_file_dict)
                tmp_xml_bytes = xml_file_dict['/EF']['/F'].getData()
                xml_root = etree.fromstring(tmp_xml_bytes)
                logger.info(
                    'A valid XML file %s has been found in the PDF file',
                    filename)
                if check_xsd:
                    flavor = 'autodetect'
                    if filename == ORDERX_FILENAME:
                        flavor = 'order-x'
                    elif filename == FACTURX_FILENAME:
                        flavor = 'factur-x'
                    elif filename in ZUGFERD_FILENAMES:
                        flavor = 'zugferd'
                    xml_check_xsd(xml_root, flavor=flavor)
                    xml_bytes = tmp_xml_bytes
                    xml_filename = filename
                else:
                    xml_bytes = tmp_xml_bytes
                    xml_filename = filename
                break
    except Exception as e:
        logger.error('No valid XML file found in the PDF: %s', e)
        return (None, None)
    logger.info('Returning an XML file %s', xml_filename)
    logger.debug('Content of the XML file: %s', xml_bytes)
    return (xml_filename, xml_bytes)


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
        'factur-x Python lib v%s by Alexis de Lattre' % __version__,
        '/Keywords': pdf_metadata.get('keywords', ''),
        '/ModDate': pdf_date,
        '/Subject': pdf_metadata.get('subject', ''),
        '/Title': pdf_metadata.get('title', ''),
        }
    return info_dict


def _prepare_pdf_metadata_xml(flavor, level, orderx_type, pdf_metadata):
    xml_str = u"""
<?xpacket begin="\ufeff" id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
  <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <rdf:Description xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/" rdf:about="">
      <pdfaid:part>3</pdfaid:part>
      <pdfaid:conformance>B</pdfaid:conformance>
    </rdf:Description>
    <rdf:Description xmlns:dc="http://purl.org/dc/elements/1.1/" rdf:about="">
      <dc:title>
        <rdf:Alt>
          <rdf:li xml:lang="x-default">{title}</rdf:li>
        </rdf:Alt>
      </dc:title>
      <dc:creator>
        <rdf:Seq>
          <rdf:li>{author}</rdf:li>
        </rdf:Seq>
      </dc:creator>
      <dc:description>
        <rdf:Alt>
          <rdf:li xml:lang="x-default">{subject}</rdf:li>
        </rdf:Alt>
      </dc:description>
    </rdf:Description>
    <rdf:Description xmlns:pdf="http://ns.adobe.com/pdf/1.3/" rdf:about="">
      <pdf:Producer>{producer}</pdf:Producer>
    </rdf:Description>
    <rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" rdf:about="">
      <xmp:CreatorTool>{creator_tool}</xmp:CreatorTool>
      <xmp:CreateDate>{timestamp}</xmp:CreateDate>
      <xmp:ModifyDate>{timestamp}</xmp:ModifyDate>
    </rdf:Description>
    <rdf:Description xmlns:pdfaExtension="http://www.aiim.org/pdfa/ns/extension/" xmlns:pdfaSchema="http://www.aiim.org/pdfa/ns/schema#" xmlns:pdfaProperty="http://www.aiim.org/pdfa/ns/property#" rdf:about="">
      <pdfaExtension:schemas>
        <rdf:Bag>
          <rdf:li rdf:parseType="Resource">
            <pdfaSchema:schema>Factur-X PDFA Extension Schema</pdfaSchema:schema>
            <pdfaSchema:namespaceURI>{urn}</pdfaSchema:namespaceURI>
            <pdfaSchema:prefix>fx</pdfaSchema:prefix>
            <pdfaSchema:property>
              <rdf:Seq>
                <rdf:li rdf:parseType="Resource">
                  <pdfaProperty:name>DocumentFileName</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>The name of the embedded XML document</pdfaProperty:description>
                </rdf:li>
                <rdf:li rdf:parseType="Resource">
                  <pdfaProperty:name>DocumentType</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>The type of the hybrid document in capital letters, e.g. INVOICE or ORDER</pdfaProperty:description>
                </rdf:li>
                <rdf:li rdf:parseType="Resource">
                  <pdfaProperty:name>Version</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>The actual version of the standard applying to the embedded XML document</pdfaProperty:description>
                </rdf:li>
                <rdf:li rdf:parseType="Resource">
                  <pdfaProperty:name>ConformanceLevel</pdfaProperty:name>
                  <pdfaProperty:valueType>Text</pdfaProperty:valueType>
                  <pdfaProperty:category>external</pdfaProperty:category>
                  <pdfaProperty:description>The conformance level of the embedded XML document</pdfaProperty:description>
                </rdf:li>
              </rdf:Seq>
            </pdfaSchema:property>
          </rdf:li>
        </rdf:Bag>
      </pdfaExtension:schemas>
    </rdf:Description>
    <rdf:Description xmlns:fx="{urn}" rdf:about="">
      <fx:DocumentType>{documenttype}</fx:DocumentType>
      <fx:DocumentFileName>{xml_filename}</fx:DocumentFileName>
      <fx:Version>{version}</fx:Version>
      <fx:ConformanceLevel>{xmp_level}</fx:ConformanceLevel>
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>
<?xpacket end="w"?>
"""
    if flavor == 'order-x':
        documenttype = orderx_type.upper()
        xml_filename = ORDERX_FILENAME
        xmp_level = level.upper()
        urn = 'urn:factur-x:pdfa:CrossIndustryDocument:1p0#'
    else:
        documenttype = 'INVOICE'
        xml_filename = FACTURX_FILENAME
        xmp_level = FACTURX_LEVEL2xmp[level]
        urn = 'urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#'
    xml_str = xml_str.format(
        title=pdf_metadata.get('title', ''),
        author=pdf_metadata.get('author', ''),
        subject=pdf_metadata.get('subject', ''),
        producer='PyPDF4',
        creator_tool='factur-x python lib v%s by Alexis de Lattre' % __version__,
        timestamp=_get_metadata_timestamp(),
        urn=urn,
        documenttype=documenttype,
        xml_filename=xml_filename,
        version='1.0',
        xmp_level=xmp_level)
    xml_byte = xml_str.encode('utf-8')
    logger.debug('metadata XML:')
    logger.debug(xml_byte)
    return xml_byte


# def createByteObject(string):
#    string_to_encode = '\ufeff' + string
#    x = string_to_encode.encode('utf-16be')
#    return ByteStringObject(x)


def _filespec_additional_attachments(
        pdf_filestream, name_arrayobj_cdict, file_dict, filename):
    logger.debug('_filespec_additional_attachments filename=%s', filename)
    md5sum = hashlib.md5(file_dict['filedata']).hexdigest()
    md5sum_obj = createStringObject(md5sum)
    params_dict = DictionaryObject({
        NameObject('/CheckSum'): md5sum_obj,
        NameObject('/Size'): NameObject(str(len(file_dict['filedata']))),
        })
    # creation date and modification date are optional
    if isinstance(file_dict.get('modification_datetime'), datetime):
        mod_date_pdf = _get_pdf_timestamp(file_dict['modification_datetime'])
        params_dict[NameObject('/ModDate')] = createStringObject(mod_date_pdf)
    if isinstance(file_dict.get('creation_datetime'), datetime):
        creation_date_pdf = _get_pdf_timestamp(file_dict['creation_datetime'])
        params_dict[NameObject('/CreationDate')] = createStringObject(creation_date_pdf)
    file_entry = DecodedStreamObject()
    file_entry.setData(file_dict['filedata'])
    file_entry = file_entry.flateEncode()
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
    afrelationship = file_dict.get('afrelationship')
    if afrelationship not in ATTACHMENTS_AFRelationship:
        afrelationship = 'unspecified'
    filespec_dict = DictionaryObject({
        NameObject("/AFRelationship"): NameObject("/%s" % afrelationship.capitalize()),
        NameObject("/Desc"): createStringObject(file_dict.get('description', '')),
        NameObject("/Type"): NameObject("/Filespec"),
        NameObject("/F"): fname_obj,
        NameObject("/EF"): ef_dict,
        NameObject("/UF"): fname_obj,
        })
    filespec_obj = pdf_filestream._addObject(filespec_dict)
    name_arrayobj_cdict[fname_obj] = filespec_obj


def _facturx_update_metadata_add_attachment(
        pdf_filestream, xml_bytes, pdf_metadata, flavor, level,
        orderx_type=None, lang=None,
        output_intents=[], additional_attachments={},
        afrelationship='data'):
    '''This method is inspired from the code of the addAttachment()
    method of the PyPDF2 lib'''
    # The entry for the file
    # facturx_xml_str = facturx_xml_str.encode('utf-8')
    if flavor == 'order-x' and orderx_type not in ORDERX_TYPES:
        raise ValueError(
            'Wrong value for orderx_type (%s), must be in %s'
            % (orderx_type, ORDERX_TYPES))
    if afrelationship not in XML_AFRelationship:
        raise ValueError(
            "Wrong value for afrelationship (%s). Possible values: %s."
            % (afrelationship, XML_AFRelationship))
    md5sum = hashlib.md5(xml_bytes).hexdigest()
    md5sum_obj = createStringObject(md5sum)
    params_dict = DictionaryObject({
        NameObject('/CheckSum'): md5sum_obj,
        NameObject('/ModDate'): createStringObject(_get_pdf_timestamp()),
        NameObject('/Size'): NameObject(str(len(xml_bytes))),
        })
    file_entry = DecodedStreamObject()
    file_entry.setData(xml_bytes)  # here we integrate the file itself
    file_entry = file_entry.flateEncode()
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

    if flavor == 'order-x':
        xml_filename = ORDERX_FILENAME
        desc = 'Order-X XML file'
    else:
        xml_filename = FACTURX_FILENAME
        desc = 'Factur-X XML file'

    fname_obj = createStringObject(xml_filename)
    filespec_dict = DictionaryObject({
        NameObject("/AFRelationship"): NameObject("/%s" % afrelationship.capitalize()),
        NameObject("/Desc"): createStringObject(desc),
        NameObject("/Type"): NameObject("/Filespec"),
        NameObject("/F"): fname_obj,
        NameObject("/EF"): ef_dict,
        NameObject("/UF"): fname_obj,
        })
    filespec_obj = pdf_filestream._addObject(filespec_dict)
    name_arrayobj_cdict = {fname_obj: filespec_obj}
    for attach_filename, attach_dict in additional_attachments.items():
        _filespec_additional_attachments(
            pdf_filestream, name_arrayobj_cdict, attach_dict, attach_filename)
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
    metadata_xml_bytes = _prepare_pdf_metadata_xml(
        flavor, level, orderx_type, pdf_metadata)
    metadata_file_entry = DecodedStreamObject()
    metadata_file_entry.setData(metadata_xml_bytes)
    metadata_file_entry = metadata_file_entry.flateEncode()
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
    if lang:
        pdf_filestream._root_object.update({
            NameObject("/Lang"): createStringObject(lang.replace('_', '-')),
            })
    logger.debug('res_output_intents=%s', res_output_intents)
    if res_output_intents:
        pdf_filestream._root_object.update({
            NameObject("/OutputIntents"): ArrayObject(res_output_intents),
        })
    metadata_txt_dict = _prepare_pdf_metadata_txt(pdf_metadata)
    pdf_filestream.addMetadata(metadata_txt_dict)
    logger.info('%s file added to PDF document', xml_filename)


def _extract_base_info(facturx_xml_etree):
    namespaces = facturx_xml_etree.nsmap
    date_xpath = facturx_xml_etree.xpath(
        '//rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString',
        namespaces=namespaces)
    date = date_xpath[0].text
    date_format = date_xpath[0].attrib and date_xpath[0].attrib.get('format') or '102'
    format_map = {
        '102': '%Y%m%d',
        '203': '%Y%m%d%H%M',
        }
    date_dt = datetime.strptime(date, format_map.get(date_format, format_map['102']))
    number_xpath = facturx_xml_etree.xpath(
        '//rsm:ExchangedDocument/ram:ID', namespaces=namespaces)
    number = number_xpath[0].text
    seller_xpath = facturx_xml_etree.xpath(
        '//ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:Name',
        namespaces=namespaces)
    seller = seller_xpath[0].text
    buyer_xpath = facturx_xml_etree.xpath(
        '//ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:Name',
        namespaces=namespaces)
    buyer = buyer_xpath[0].text

    doc_type_xpath = facturx_xml_etree.xpath(
        '//rsm:ExchangedDocument/ram:TypeCode', namespaces=namespaces)
    doc_type = doc_type_xpath[0].text
    base_info = {
        'seller': seller,
        'buyer': buyer,
        'number': number,
        'date': date_dt,
        'doc_type': doc_type,
        }
    logger.debug('Extraction of base_info: %s', base_info)
    return base_info


def _base_info2pdf_metadata(base_info):
    doc_type_map = {
        '220': 'Order',
        '230': 'Order Change',
        '231': 'Order Response',
        '380': 'Invoice',
        '381': 'Refund',
        }
    doc_type_name = doc_type_map.get(base_info['doc_type'], 'Invoice')
    date_str = datetime.strftime(base_info['date'], '%Y-%m-%d')
    if base_info['doc_type'] == '231':
        title = '%s: Order Response on Order %s from %s' % (
            base_info['seller'], base_info['number'], base_info['buyer'])
        subject = 'Response of %s on %s to order %s from %s' % (
            base_info['seller'], date_str, base_info['number'], base_info['buyer'])
        doc_x = 'Order-X'
        author = base_info['seller']
    elif base_info['doc_type'] in ('220', '230'):
        title = '%s: %s %s' % (
            base_info['buyer'], doc_type_name, base_info['number'])
        subject = '%s %s issued by %s on %s' % (
            doc_type_name, base_info['number'], base_info['buyer'], date_str)
        doc_x = 'Order-X'
        author = base_info['buyer']
    else:
        title = '%s: %s %s' % (
            base_info['seller'], doc_type_name, base_info['number'])
        subject = '%s %s dated %s issued by %s' % (
            doc_type_name, base_info['number'], date_str, base_info['seller'])
        doc_x = 'Factur-X'
        author = base_info['seller']
    pdf_metadata = {
        'author': author,
        'keywords': '%s, %s' % (doc_type_name, doc_x),
        'title': title,
        'subject': subject,
        }
    logger.debug('Converted base_info to pdf_metadata: %s', pdf_metadata)
    return pdf_metadata


def get_facturx_level(facturx_xml_etree):
    return get_level(facturx_xml_etree)


def get_level(xml_etree):
    if not isinstance(xml_etree, type(etree.Element('pouet'))):
        raise ValueError('xml_etree must be an etree.Element() object')
    namespaces = xml_etree.nsmap
    # Factur-X and Order-X
    doc_id_xpath = xml_etree.xpath(
        "//rsm:ExchangedDocumentContext"
        "/ram:GuidelineSpecifiedDocumentContextParameter"
        "/ram:ID", namespaces=namespaces)
    if not doc_id_xpath:
        # ZUGFeRD 1.0
        doc_id_xpath = xml_etree.xpath(
            "//rsm:SpecifiedExchangedDocumentContext"
            "/ram:GuidelineSpecifiedDocumentContextParameter"
            "/ram:ID", namespaces=namespaces)
    if not doc_id_xpath:
        raise ValueError(
            "This XML is not a Factur-X nor Order-X XML because it misses the XML tag "
            "ExchangedDocumentContext/"
            "GuidelineSpecifiedDocumentContextParameter/ID. It is not a ZUGFeRD 1.0 "
            "XML either because it misses the XML tag "
            "SpecifiedExchangedDocumentContext/"
            "GuidelineSpecifiedDocumentContextParameter/ID.")
    doc_id = doc_id_xpath[0].text
    level = doc_id.split(':')[-1]
    possible_values = dict(FACTURX_LEVEL2xsd)
    possible_values.update(ORDERX_LEVEL2xsd)
    # ZUGFeRD 1.0 levels are the same as orderx
    if level not in possible_values:
        level = doc_id.split(':')[-2]
    if level not in possible_values:
        raise ValueError(
            "Invalid Factur-X/Order-X URN: '%s'" % doc_id)
    logger.info('Level is %s (autodetected)', level)
    return level


def get_facturx_flavor(facturx_xml_etree):
    logger.warning(
        'get_facturx_flavor() is deprecated. Use get_flavor() instead.')
    return get_flavor(facturx_xml_etree)


def get_flavor(xml_etree):
    if not isinstance(xml_etree, type(etree.Element('pouet'))):
        raise ValueError('xml_etree must be an etree.Element() object')
    logger.debug('First XML tag: %s', xml_etree.tag)
    if xml_etree.tag.endswith('CrossIndustryInvoice'):
        flavor = 'factur-x'
    elif xml_etree.tag.endswith('CrossIndustryDocument'):
        flavor = 'zugferd'
    elif xml_etree.tag.endswith('SCRDMCCBDACIOMessageStructure'):
        flavor = 'order-x'
    else:
        raise Exception(
            "Could not detect if the document is a Factur-X, ZUGFeRD 1.0 "
            "or Order-X document.")
    logger.info('Flavor is %s (autodetected)', flavor)
    return flavor


def get_orderx_type(xml_etree):
    if not isinstance(xml_etree, type(etree.Element('pouet'))):
        raise ValueError('xml_etree must be an etree.Element() object')
    namespaces = xml_etree.nsmap
    type_code_xpath = \
        "/rsm:SCRDMCCBDACIOMessageStructure/rsm:ExchangedDocument/ram:TypeCode"
    xpath_res = xml_etree.xpath(type_code_xpath, namespaces=namespaces)
    code = xpath_res and xpath_res[0].text and xpath_res[0].text.strip() or None
    if code not in ORDERX_code2type:
        raise Exception(
            "The TypeCode extracted from the XML is %s. "
            "This is not a valid Order-X TypeCode." % code)
    logger.info(
        'Order-X type is %s code %s (autodetected)', ORDERX_code2type[code], code)
    return ORDERX_code2type[code]


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
    except Exception:
        pass
    return output_intents


def generate_facturx_from_binary(
        pdf_file, xml, facturx_level='autodetect',
        check_xsd=True, pdf_metadata=None, lang=None, attachments=None):
    logger.warning(
        'generate_facturx_from_binary() is deprecated. '
        'Use generate_from_binary() instead.')
    return generate_from_binary(
        pdf_file, xml, flavor='factur-x', level=facturx_level,
        check_xsd=check_xsd, pdf_metadata=pdf_metadata, lang=lang,
        attachments=attachments)


def generate_from_binary(
        pdf_file, xml, flavor='autodetect', level='autodetect',
        orderx_type='autodetect',
        check_xsd=True, pdf_metadata=None, lang=None, attachments=None,
        afrelationship='data'):
    """
    Generate a Factur-X or Order-X PDF from a regular PDF and a factur-X
    or Order-X XML file. The method uses a binary as input (the regular PDF)
    and returns a binary as output (the Factur-X or Order-X PDF document).
    :param pdf_file: the regular PDF document as bytes
    :type pdf_file: bytes
    :param xml: the Factur-X or Order-X XML
    :type xml: bytes, string, file or etree object
    :param flavor: possible values: 'factur-x', 'order-x' or 'autodetect'
    :type flavor: string
    :param level: the level of the Factur-X or Order-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a very very small perf improvement.
    Possible values: minimum, basicwl, basic, en16931, extended for Factur-X
    basic, comfort, extended for Order-X
    :type level: string
    :param orderx_type: If generating an Order-X file (flavor='order-x'),
    specify the type of Order-X document. Default value: autodetect.
    Possible values: order, order_change, order_response, autodetect.
    :type orderx_type: string
    :param check_xsd: if enable, checks the Factur-X XML file against the XSD
    (XML Schema Definition). If this step has already been performed
    beforehand, you should disable this feature to avoid a double check
    and get a small performance improvement.
    :type check_xsd: boolean
    :param pdf_metadata: Specify the metadata of the generated PDF.
    If pdf_metadata is None (default value), this lib will generate some
    metadata in English by extracting relevant info from the Factur-X/Order-X XML.
    Here is an example for the pdf_metadata argument:
    pdf_metadata = {
        'author': 'Akretion',
        'keywords': 'Factur-X, Invoice',
        'title': 'Akretion: Invoice I1242',
        'subject':
          'Factur-X invoice I1242 dated 2017-08-17 issued by Akretion',
        }
    If you pass the pdf_metadata argument, you will not use the automatic
    generation based on the extraction of the Factur-X/Order-X XML file, which will
    bring a very small perf improvement.
    :type pdf_metadata: dict
    :param lang: Language identifier in RFC 3066 format to specify the
    natural language of the PDF document. Used by PDF readers for blind people.
    Example: en-US or fr-FR
    :type lang: string
    :param output_pdf_file: File Path to the output Factur-X/Order-X PDF file
    :type output_pdf_file: string
    :param attachments: Specify the other files that you want to
    embed in the PDF file. It is a dict where key is the filename and value
    is a dict. In this dict, keys are 'filepath' (value is the full file path)
    or 'filedata' (value is the encoded file),
    'description' (text description, optional),
    'modification_datetime' (modification date and time as datetime object, optional).
    'creation_datetime' (creation date and time as datetime object, optional),
    'afrelationship' (AFRelationship of the attachment.
                      Possible values: supplement, unspecified.
                      Default value: unspecified).
    :type attachments: dict
    :param afrelationship: Set the AFRelationship PDF property of the
    Factur-X/Order-X XML file.
    Possible value: data, source, alternative. Default value: data.
    :type afrelationship: string
    :return: The Factur-X or Order-X PDF file as bytes
    :rtype: bytes
    """

    if not isinstance(pdf_file, bytes):
        raise ValueError('pdf_invoice argument must be a string')
    result_pdf = False
    with NamedTemporaryFile(prefix='facturx-', suffix='.pdf') as f:
        f.write(pdf_file)
        generate_from_file(
            f, xml, flavor=flavor, level=level, orderx_type=orderx_type,
            check_xsd=check_xsd, pdf_metadata=pdf_metadata, lang=lang,
            attachments=attachments, afrelationship=afrelationship)
        f.seek(0)
        result_pdf = f.read()
        f.close()
    return result_pdf


def generate_facturx_from_file(
        pdf_file, facturx_xml, facturx_level='autodetect',
        check_xsd=True, pdf_metadata=None, output_pdf_file=None,
        additional_attachments=None, attachments=None, lang=None):
    logger.warning(
        'generate_facturx_from_file() is deprecated. '
        'Use generate_from_file() instead.')
    if additional_attachments:
        logger.warning(
            "The argument additional_attachments is not supported "
            "any more. Use the attachments arg instead.")
    return generate_from_file(
        pdf_file, facturx_xml, flavor='factur-x', level=facturx_level,
        check_xsd=check_xsd, pdf_metadata=pdf_metadata,
        output_pdf_file=output_pdf_file,
        attachments=attachments, lang=lang)


def generate_from_file(
        pdf_file, xml, flavor='autodetect', level='autodetect',
        orderx_type='autodetect',
        check_xsd=True, pdf_metadata=None, lang=None, output_pdf_file=None,
        attachments=None, afrelationship='data'):
    """
    Generate a Factur-X or Order-X PDF file from a regular PDF and a Factur-X
    or Order-X XML file. The method uses a file as input (regular PDF file)
    and re-writes the file (Factur-X or Order-X PDF file).
    :param pdf_file: the regular PDF file as file path
    (type string) or as file object
    :type pdf_file: string or file
    :param xml: the Factur-X or Order-X XML
    :type xml: bytes, string, file or etree object
    :param flavor: possible values: 'factur-x', 'order-x' or 'autodetect'
    :type flavor: string
    :param level: the level of the Factur-X or Order-X XML file. Default value
    is 'autodetect'. The only advantage to specifiy a particular value instead
    of using the autodetection is for a very very small perf improvement.
    Possible values: minimum, basicwl, basic, en16931, extended for Factur-X
    basic, comfort, extended for Order-X
    :type level: string
    :param orderx_type: If generating an Order-X file (flavor='order-x'),
    specify the type of Order-X document. Default value: autodetect.
    Possible values: order, order_change, order_response, autodetect.
    :type orderx_type: string
    :param check_xsd: if enable, checks the Factur-X XML file against the XSD
    (XML Schema Definition). If this step has already been performed
    beforehand, you should disable this feature to avoid a double check
    and get a small performance improvement.
    :type check_xsd: boolean
    :param pdf_metadata: Specify the metadata of the generated PDF.
    If pdf_metadata is None (default value), this lib will generate some
    metadata in English by extracting relevant info from the Factur-X/Order-X XML.
    Here is an example for the pdf_metadata argument:
    pdf_metadata = {
        'author': 'Akretion',
        'keywords': 'Factur-X, Invoice',
        'title': 'Akretion: Invoice I1242',
        'subject':
          'Factur-X invoice I1242 dated 2017-08-17 issued by Akretion',
        }
    If you pass the pdf_metadata argument, you will not use the automatic
    generation based on the extraction of the Factur-X/Order-X XML file, which will
    bring a very small perf improvement.
    :type pdf_metadata: dict
    :param lang: Language identifier in RFC 3066 format to specify the
    natural language of the PDF document. Used by PDF readers for blind people.
    Example: en-US or fr-FR
    :type lang: string
    :param output_pdf_file: File Path to the output Factur-X/Order-X PDF file
    :type output_pdf_file: string
    :param attachments: Specify the other files that you want to
    embed in the PDF file. It is a dict where key is the filename and value
    is a dict. In this dict, keys are 'filepath' (value is the full file path)
    or 'filedata' (value is the encoded file),
    'description' (text description, optional),
    'modification_datetime' (modification date and time as datetime object, optional).
    'creation_datetime' (creation date and time as datetime object, optional),
    'afrelationship' (AFRelationship of the attachment.
                      Possible values: supplement, unspecified.
                      Default value: unspecified).
    :type attachments: dict
    :param afrelationship: Set the AFRelationship PDF property of the
    Factur-X/Order-X XML file.
    Possible value: data, source, alternative. Default value: data.
    :type afrelationship: string
    :return: Returns True. This method re-writes the input PDF file,
    unless if the argument output_pdf_file is set.
    :rtype: bool
    """
    start_chrono = datetime.now()
    logger.debug(
        'generate_from_file with factur-x lib %s', __version__)
    logger.debug('1st arg pdf_file type=%s', type(pdf_file))
    logger.debug('2nd arg xml type=%s', type(xml))
    logger.debug('optional arg flavor=%s', flavor)
    logger.debug('optional arg level=%s', level)
    logger.debug('optional arg orderx_type=%s', orderx_type)
    logger.debug('optional arg check_xsd=%s', check_xsd)
    logger.debug('optional arg pdf_metadata=%s', pdf_metadata)
    logger.debug('optional arg lang=%s', lang)
    logger.debug('optional arg output_pdf_file=%s', output_pdf_file)
    logger.debug('optional arg attachments=%s', attachments)
    logger.debug('optional arg afrelationship=%s', afrelationship)
    if not pdf_file:
        raise ValueError('Missing pdf_file argument')
    if not xml:
        raise ValueError('Missing xml argument')
    if not isinstance(flavor, (str, unicode)):
        raise ValueError('flavor argument is a %s, must be a string' % type(flavor))
    if not isinstance(level, (str, unicode)):
        raise ValueError('level argument is a %s, must be a string' % type(level))
    if not isinstance(orderx_type, (str, unicode, type(None))):
        raise ValueError(
            'orderx_type argument is a %s, must be a string or None'
            % type(orderx_type))
    if not isinstance(check_xsd, bool):
        raise ValueError(
            'check_xsd argument is a %s, must be a boolean' % type(check_xsd))
    if not isinstance(pdf_metadata, (dict, type(None))):
        raise ValueError(
            'pdf_metadata argument is a %s, must be a dict or None'
            % type(pdf_metadata))
    if not isinstance(lang, (type(None), str, unicode)):
        raise ValueError(
            'lang argument is a %s, must be a string or None' % type(lang))
    if not isinstance(output_pdf_file, (type(None), str, unicode)):
        raise ValueError(
            'output_pdf_file argument is a %s, must be a string or None'
            % type(output_pdf_file))
    if not isinstance(attachments, (dict, type(None))):
        raise ValueError(
            'attachments argument is a %s, must be a dict or None' % type(attachments))
    if not isinstance(afrelationship, (str, unicode, type(None))):
        raise ValueError(
            'afrelationship argument is a %s, must be a string or None'
            % type(afrelationship))
    # Tolerance on arguments - reformatting
    flavor = flavor.lower()
    flavor_fix_mapping = {
        'orderx': 'order-x',
        'facturx': 'factur-x',
        }
    flavor = flavor_fix_mapping.get(flavor, flavor)
    level = level.lower().replace(' ', '')
    if orderx_type:
        orderx_type = orderx_type.lower().replace('-', '_').replace(' ', '_')
    if afrelationship:
        afrelationship = afrelationship.lower()
    else:
        afrelationship = 'data'
    if afrelationship not in XML_AFRelationship:
        logger.warning(
            "Wrong value for afrelationship (%s). Forcing it to 'data'.",
            afrelationship)
        afrelationship = 'data'

    if isinstance(pdf_file, (str, unicode)):
        file_type = 'path'
    else:
        file_type = 'file'
    xml_root = None
    if isinstance(xml, (str, bytes)):
        xml_bytes = xml
    elif isinstance(xml, unicode):
        xml_bytes = xml.encode('utf8')
    elif isinstance(xml, type(etree.Element('pouet'))):
        xml_root = xml
        xml_bytes = etree.tostring(
            xml_root, pretty_print=True, encoding='UTF-8',
            xml_declaration=True)
    elif isinstance(xml, file):
        xml.seek(0)
        xml_bytes = xml.read()
        # xml.close()
        # If xml is passed as file descriptor
        # I don't think we expect the lib to close it
    else:
        raise TypeError(
            "The second argument of the method generate_from_file must be "
            "either a string, an etree.Element() object or a file "
            "(it is a %s)." % type(xml))
    if attachments is None:
        attachments = {}
    if attachments:
        # I used list() to avoid the following error in Python3:
        # Error: dictionary changed size during iteration
        for filename in list(attachments.keys()):
            if filename in ALL_FILENAMES:
                logger.warning(
                    'You cannot provide as attachment a file named %s. '
                    'This file will NOT be attached.', filename)
                attachments.pop(filename)
        for fadict in attachments.values():
            if fadict.get('filepath') and not fadict.get('filedata'):
                with open(fadict['filepath'], 'rb') as fa:
                    fa.seek(0)
                    fadict['filedata'] = fa.read()
                    fa.close()

                # As explained here
                # https://stackoverflow.com/questions/237079/how-to-get-file-creation-modification-date-times-in-python
                # creation date is not easy to get.
                # So we only implement getting the modification date
                if not fadict.get('modification_datetime'):
                    mod_timestamp = os.path.getmtime(fadict['filepath'])
                    fadict['modification_datetime'] = datetime.fromtimestamp(
                        mod_timestamp)
                if fadict.get('afrelationship'):
                    fadict['afrelationship'] = fadict['afrelationship'].lower()
                if fadict.get('afrelationship') not in ATTACHMENTS_AFRelationship:
                    # set default value
                    fadict['afrelationship'] = 'unspecified'
    if flavor not in ('factur-x', 'order-x'):
        if xml_root is None:
            xml_root = etree.fromstring(xml_bytes)
        logger.debug('Flavor will be autodetected')
        flavor = get_flavor(xml_root)
    if (
            (flavor == 'factur-x' and level not in FACTURX_LEVEL2xsd) or
            (flavor == 'order-x' and level not in ORDERX_LEVEL2xsd)):
        if xml_root is None:
            xml_root = etree.fromstring(xml_bytes)
        logger.debug('level will be autodetected')
        level = get_level(xml_root)
    if (
            flavor == 'factur-x' and
            level in ('minimum', 'basicwl') and
            afrelationship in ('source', 'alternative')):
        logger.warning(
            "afrelationship switched from '%s' to 'data' because it must be 'data' "
            "for Factur-X profile '%s'.", afrelationship, level)
        afrelationship = 'data'
    if flavor == 'order-x' and orderx_type not in ORDERX_TYPES:
        if xml_root is None:
            xml_root = etree.fromstring(xml_bytes)
        orderx_type = get_orderx_type(xml_root)
    if check_xsd:
        xml_check_xsd(
            xml_bytes, flavor=flavor, level=level)
    if pdf_metadata is None:
        if xml_root is None:
            xml_root = etree.fromstring(xml_bytes)
        base_info = _extract_base_info(xml_root)
        pdf_metadata = _base_info2pdf_metadata(base_info)
    else:
        # clean-up pdf_metadata dict
        for key, value in pdf_metadata.items():
            if not isinstance(value, (str, unicode)):
                pdf_metadata[key] = ''
    original_pdf = PdfFileReader(pdf_file)
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
        new_pdf_filestream, xml_bytes, pdf_metadata, flavor, level,
        orderx_type=orderx_type, lang=lang,
        output_intents=output_intents,
        additional_attachments=attachments,
        afrelationship=afrelationship)
    if output_pdf_file:
        with open(output_pdf_file, 'wb') as output_f:
            new_pdf_filestream.write(output_f)
            output_f.close()
    else:
        if file_type == 'path':
            with open(pdf_file, 'wb') as f:
                new_pdf_filestream.write(f)
                f.close()
        elif file_type == 'file':
            new_pdf_filestream.write(pdf_file)
    end_chrono = datetime.now()
    logger.info(
        '%s PDF generated in %s seconds',
        flavor, (end_chrono - start_chrono).total_seconds())
    return True
