# Copyright 2026, Alexis de Lattre <alexis.delattre@akretion.com>
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

import base64
import datetime
import json
import logging
from io import IOBase

from lxml import etree

from .facturx import get_flavor, get_level, get_xml_namespaces, xml_check_xsd
from .generate_xml import (
    EN16931_ADDRESS_FIELDS,
    EN16931_CURRENCY_FIELDS,
    EN16931_FIELDS,
    EN16931_PARTY_FIELDS,
    FACTURX_DATE_FORMAT,
    UBL_DATE_FORMAT,
    BT_8toCII,
    BT_8toUBL,
)

logger = logging.getLogger("factur-x")


def parse_ubl_cii_xml(
    xml,
    flavor="autodetect",
    level="autodetect",
    float_as="string",
    date_as="date",
    bytes_as="bytes",
    check_xsd=True,
    check_schematron=False,
    saxon_server_url=None,
):
    if not xml:
        raise ValueError("xml argument has no value")
    xml_etree = None
    if isinstance(xml, (bytes, str)):
        try:
            xml_etree = etree.fromstring(xml)
        except Exception as err:
            raise Exception(
                f"The file to check is not a valid XML file. Error: {err}"
            ) from err
    elif isinstance(xml, type(etree.Element("pouet"))):
        xml_etree = xml
    elif isinstance(xml, IOBase):
        xml.seek(0)
        xml_bytes = xml.read()
        xml.close()
        try:
            xml_etree = etree.fromstring(xml_bytes)
        except Exception as err:
            raise Exception(
                f"The file to check is not a valid XML file. Error: {err}"
            ) from err
    else:
        raise ValueError("Wrong type for xml argument")
    if float_as not in ("string", "float"):
        raise ValueError("float_as argument has 2 possible values: 'string' or 'float'")
    if date_as not in ("string", "date"):
        raise ValueError("date_as argument has 2 possible values: 'string' or 'date'")
    if bytes_as not in ("bytes", "string"):  # string means base64 string
        raise ValueError("bytes_as argument has 2 possible values: 'bytes' or 'string'")
    if flavor in (
        "zugferd",
        "order-x",
        "orderx",
    ):
        raise ValueError("Parsing of ZUGFeRD 1.x and Order-X XML is not supported yet")
    if flavor == "autodetect":
        flavor = get_flavor(xml_etree)
    if flavor not in ("factur-x", "facturx", "ubl-2.1-invoice", "ubl-2.1-creditnote"):
        raise ValueError("Wrong flavor or bad autodetection.")
    if level == "autodetect":
        level = get_level(xml_etree, flavor)
    namespaces = get_xml_namespaces(flavor)
    if flavor in ("factur-x", "facturx"):
        date_format = FACTURX_DATE_FORMAT
    else:
        date_format = UBL_DATE_FORMAT
    if check_xsd:
        xml_check_xsd(xml_etree, flavor=flavor, level=level)
    data_dict = {}
    setup = {
        "namespaces": namespaces,
        "flavor": flavor,
        "float_as": float_as,
        "bytes_as": bytes_as,
        "date_as": date_as,
        "date_format": date_format,
        "currencies": {},
    }
    for field, field_props in EN16931_CURRENCY_FIELDS.items():
        value = _xpath_get_value(xml_etree, field, field_props, setup)
        if value:
            data_dict[field] = value
            setup["currencies"][field] = value

    for field, field_props in EN16931_FIELDS.items():
        if field in EN16931_CURRENCY_FIELDS:
            continue
        # Filter by level, to speed-up the code
        if (
            level == "basicwl"
            and (
                field_props.get("min_level") in ("extended", "en16931")
                or field.startswith("EXT-FR-FE-")
            )
        ) or (
            level == "en16931"
            and (
                field_props.get("min_level") == "extended"
                or field.startswith("EXT-FR-FE-")
            )
        ):
            continue
        value = _xpath_get_value(xml_etree, field, field_props, setup)
        if value:
            data_dict[field] = value
    _post_processing(data_dict, flavor)
    return data_dict


def parse_ubl_cii_xml_to_json(
    xml,
    flavor="autodetect",
    level="autodetect",
    check_xsd=True,
    check_schematron=False,
    saxon_server_url=None,
):
    data_dict = parse_ubl_cii_xml(
        xml,
        flavor=flavor,
        level=level,
        float_as="float",
        date_as="string",
        bytes_as="string",
        check_xsd=check_xsd,
        check_schematron=check_schematron,
        saxon_server_url=saxon_server_url,
    )
    json_res = json.dumps(data_dict, indent=4)
    return json_res


def _get_xpaths(field, field_props, flavor):
    props = dict(field_props)
    if flavor in ("factur-x", "facturx"):
        xpath = props.get("cii_xpath")
    elif flavor == "ubl-2.1-invoice":
        xpath = props.get("ubl_xpath")
    elif flavor == "ubl-2.1-creditnote":
        if props.get("ubl_creditnote_xpath"):
            xpath = props["ubl_creditnote_xpath"]
        else:
            xpath = props.get("ubl_xpath")
    else:
        raise
    if isinstance(xpath, str):
        raw_xpaths = [xpath]
    elif isinstance(xpath, list):
        raw_xpaths = xpath
    elif xpath is None:
        raw_xpaths = []
    else:
        raise
    xpaths = []
    for raw_xpath in raw_xpaths:
        if not raw_xpath:
            continue
        xpath_ok = raw_xpath
        if flavor == "ubl-2.1-invoice":
            if raw_xpath.startswith("/Invoice/"):
                xpath_ok = f"/default:Invoice/{raw_xpath[9:]}"
        elif flavor == "ubl-2.1-creditnote":
            if raw_xpath.startswith("/CreditNote/"):
                xpath_ok = f"/default:CreditNote/{raw_xpath[12:]}"
            elif raw_xpath.startswith("/Invoice/"):
                xpath_ok = f"/default:CreditNote/{raw_xpath[9:]}"
        xpaths.append(xpath_ok)
    return xpaths


def _xpath_get_value(node, field, field_props, setup):
    xpaths = _get_xpaths(field, field_props, setup["flavor"])
    address_fields = list(EN16931_ADDRESS_FIELDS.keys())
    if len(xpaths) == 1 and xpaths[0] == "NONE":  # used for UBL BG-1
        assert not field_props.get("format")
        return node.text
    if field_props.get("format", "string").endswith("_dict"):
        values = {}
    else:
        values = []
    for xpath in xpaths:
        if "%(" in xpath and ")s" in xpath:
            try:
                xpath = xpath % setup["currencies"]
            except Exception as err:
                logger.info(
                    f"Could not generate final xpath for field {field} "
                    f"from {xpath} with values {setup['currencies']}."
                    f"Error: {err}"
                )
                continue
        xpath_res = node.xpath(xpath, namespaces=setup["namespaces"])
        for xpath_entry in xpath_res:
            if isinstance(xpath_entry, str):  # for attributes
                # I call str to avoid having a type
                # <class 'lxml.etree._ElementUnicodeResult'>
                values.append(str(xpath_entry))
            elif field_props.get("format") == "list" and isinstance(
                field_props.get("fields"), dict
            ):
                cres = {}
                for cfield, cfield_props in field_props["fields"].items():
                    cvalue = _xpath_get_value(xpath_entry, cfield, cfield_props, setup)
                    if cvalue:
                        cres[cfield] = cvalue
                if cres:
                    values.append(cres)
            elif field_props.get("format") == "party_dict":
                party_res = {}
                for pfield, pfield_props in EN16931_PARTY_FIELDS.items():
                    # small hack for delivery block in UBL,
                    # which is not a regular party block
                    pfield_props_copy = dict(pfield_props)
                    if field in ("BG-13", "EXT-FR-FE-BG-10") and setup[
                        "flavor"
                    ].startswith("ubl-2.1-"):
                        if pfield == "name":
                            pfield_props_copy["ubl_xpath"] = (
                                "cac:DeliveryParty/cac:PartyName/cbc:Name"
                            )
                        elif pfield == "identifiers":
                            pfield_props_copy["ubl_xpath"] = (
                                "cac:DeliveryLocation/cbc:ID"
                            )
                        elif pfield in address_fields:
                            pfield_props_copy["ubl_xpath"] = (
                                f"cac:DeliveryLocation/cac:Address/{pfield_props['ubl_xpath'][18:]}"
                            )
                        else:
                            continue
                    pvalue = _xpath_get_value(
                        xpath_entry, pfield, pfield_props_copy, setup
                    )
                    if pvalue:
                        party_res[pfield] = pvalue
                values = party_res
            elif field_props.get("format") == "schemeID_dict" or (
                field_props.get("format") == "schemeID_ReferenceTypeCode_dict"
                and setup["flavor"].startswith("ubl-2.1-")
            ):
                if xpath_entry.text:
                    if xpath_entry.attrib and xpath_entry.attrib.get("schemeID"):
                        values[xpath_entry.attrib["schemeID"]] = xpath_entry.text
                    else:
                        values[None] = xpath_entry.text
            elif field_props.get(
                "format"
            ) == "schemeID_ReferenceTypeCode_dict" and not setup["flavor"].startswith(
                "ubl-2.1-"
            ):
                issuer_id = xpath_entry.findtext(
                    "ram:IssuerAssignedID", namespaces=setup["namespaces"]
                )
                ref_type_code = xpath_entry.findtext(
                    "ram:ReferenceTypeCode", namespaces=setup["namespaces"]
                )
                if issuer_id:
                    values[ref_type_code] = issuer_id
            elif field_props.get("format") == "listID_listVersionID_dict":
                # listID is required, listVersionID is optional
                if (
                    xpath_entry.text
                    and xpath_entry.attrib
                    and xpath_entry.attrib.get("listID")
                ):
                    listID = xpath_entry.attrib["listID"]
                    listVersionID = xpath_entry.attrib.get("listVersionID")
                    values[(listID, listVersionID)] = xpath_entry.text
            elif xpath_entry.text:
                value = xpath_entry.text and xpath_entry.text.strip()
                if field_props.get("format") == "date":
                    value = datetime.datetime.strptime(
                        value, setup["date_format"]
                    ).date()
                    if setup["date_as"] == "string":
                        value = value.strftime("%Y-%m-%d")  # format for JSON
                elif (
                    field_props.get("format")
                    in ("price", "qty", "percent", "monetary_BT-5", "monetary_BT-6")
                    and setup["float_as"] == "float"
                ):
                    value = float(value)
                elif (
                    field_props.get("format") == "bytes"
                    and setup["bytes_as"] == "bytes"
                ):
                    value = base64.b64decode(value)
                if value:
                    values.append(value)
    if not values:
        values = None
    elif (
        len(values) == 1
        and field_props.get("format") != "list"
        and not field_props.get("format", "string").endswith("_dict")
    ):
        values = values[0]
    logger.info(f"Value for {field} is {values}")
    return values


def _post_processing(data_dict, flavor):
    if data_dict.get("BT-8"):
        if flavor in ("factur-x", "facturx"):
            value2name = {value: key for key, value in BT_8toCII.items()}
            if isinstance(data_dict["BT-8"], list):
                if len(set(data_dict["BT-8"])) > 1:
                    logger.warning(
                        "BT-8 in CII has several different values "
                        f"({', '.join(data_dict['BT-8'])}). This should never happen."
                    )
                data_dict["BT-8"] = data_dict["BT-8"][0]
        else:
            value2name = {value: key for key, value in BT_8toUBL.items()}
        if data_dict["BT-8"] in value2name:
            data_dict["BT-8"] = value2name[data_dict["BT-8"]]
        else:
            logger.warning(f"BT-8 in {flavor} has a wrong value '{data_dict['BT-8']}'")
    if (
        data_dict.get("BT-7")
        and flavor in ("factur-x", "facturx")
        and isinstance(data_dict["BT-7"], list)
    ):
        if len(set(data_dict["BT-7"])) > 1:
            logger.warning(
                "BT-7 in CII has several different values "
                f"({', '.join(data_dict['BT-7'])}). This should never happen."
            )
        data_dict["BT-7"] = data_dict["BT-7"][0]
    if flavor in ("ubl-2.1-invoice", "ubl-2.1-creditnote"):
        if data_dict.get("BG-1") and isinstance(data_dict["BG-1"], list):
            for note_dict in data_dict["BG-1"]:
                if (
                    note_dict.get("BT-22")
                    and note_dict["BT-22"].startswith("#")
                    and len(note_dict["BT-22"]) >= 5
                ):
                    note_dict["BT-21"] = note_dict["BT-22"][1:4]
                    note_dict["BT-22"] = note_dict["BT-22"][5:]
        for line in data_dict.get("BG-25") or []:
            if line.get("BT-127-00") and isinstance(line["BT-127-00"], list):
                for note_dict in line["BT-127-00"]:
                    if (
                        note_dict.get("BT-127")
                        and note_dict["BT-127"].startswith("#")
                        and len(note_dict["BT-127"]) >= 5
                    ):
                        note_dict["EXT-FR-FE-183"] = note_dict["BT-127"][1:4]
                        note_dict["BT-127"] = note_dict["BT-127"][5:]
