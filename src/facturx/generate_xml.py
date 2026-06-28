# Copyright 2016-2026, Alexis de Lattre <alexis.delattre@akretion.com>
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

import datetime
import importlib.metadata
import logging

from lxml import etree, objectify
from stdnum.iban import is_valid as iban_is_valid

from .facturx import XML_NAMESPACES, xml_check_schematron, xml_check_xsd

FACTURX_DATE_FORMAT = "%Y%m%d"
UBL_DATE_FORMAT = "%Y-%m-%d"
LEVEL2BT_24 = {  # for both UBL and CII/FX
    "basicwl": "urn:factur-x.eu:1p0:basicwl",  # Factur-X only
    "en16931": "urn:cen.eu:en16931:2017",  # UBL and CII and Factur-X
    # extended is Factur-X only
    "extended": "urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:extended",
    # extended-ctc-fr is for UBL and CII
    "extended-ctc-fr": "urn:cen.eu:en16931:2017"
    "#conformant#urn.cpro.gouv.fr:1p0:extended-ctc-fr",
}
BT_8toCII = {
    "invoice": "5",
    "delivery": "29",
    "payment": "72",
}
BT_8toUBL = {
    "invoice": "3",
    "delivery": "35",
    "payment": "432",
}


VERSION = importlib.metadata.version("factur-x")
FORMAT = "%(asctime)s [%(levelname)s] %(message)s"
logging.basicConfig(format=FORMAT)
logger = logging.getLogger("factur-x")
logger.setLevel(logging.INFO)

EN6931_FIELDS = {
    "BT-1": {
        "required": True,
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:ID",
    },
    "BT-2": {
        "required": True,
        "format": "date",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/"
        "ram:IssueDateTime/udt:DateTimeString",
    },
    "BT-3": {
        "required": True,
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:TypeCode",
    },
    "BT-5": {
        "required": True,
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode",
    },
    "BT-9": {"format": "date"},
    "BT-11": {"min_level": "en16931"},
    "BT-11-0": {"min_level": "en16931"},
    "BT-14": {"min_level": "en16931"},
    "BT-15": {"min_level": "en16931"},
    "BT-17": {"min_level": "en16931"},
    "BT-18-00": {"min_level": "en16931", "format": "dict"},
    "BT-24": {"required": True},
    "BT-33": {"min_level": "en16931"},
    "BT-41": {"min_level": "en16931"},
    "BT-41-0": {"min_level": "en16931"},
    "BT-42": {"min_level": "en16931"},
    "BT-43": {"min_level": "en16931"},
    "BT-45": {"min_level": "en16931"},
    "BT-56": {"min_level": "en16931"},
    "BT-56-0": {"min_level": "en16931"},
    "BT-57": {"min_level": "en16931"},
    "BT-58": {"min_level": "en16931"},
    "BT-73": {"format": "date"},
    "BT-74": {"format": "date"},
    "BT-83": {"format": "date"},
    "BT-85": {"min_level": "en16931"},
    "BT-86": {"min_level": "en16931"},
    "BT-26": {"format": "date"},
    "BT-29": {"format": "dict"},
    "BG-1": {"format": "list"},
    "BG-24": {"format": "list", "min_level": "en16931"},
    "BG-25": {"format": "list", "min_level": "en16931"},
    "BT-82": {
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction"
        "/ram:ApplicableHeaderTradeSettlement"
        "/ram:SpecifiedTradeSettlementPaymentMeans/ram:Information",
    },
}


def _cii_date_to_string(date):
    if not isinstance(date, datetime.date):
        raise ValueError("The date argument must be a python date object")
    date_str = date.strftime(FACTURX_DATE_FORMAT)
    return date_str


def _ubl_date_to_string(date):
    if not isinstance(date, datetime.date):
        raise ValueError("The date argument must be a python date object")
    date_str = date.strftime(UBL_DATE_FORMAT)
    return date_str


def _check_data_dict(data_dict, flavor, level):
    for field, props in EN6931_FIELDS.items():
        value = data_dict.get(field)
        if props.get("required"):
            if not value:
                raise ValueError(f"No value for required field {field}.")
        instance_map = {
            "date": datetime.date,
            "list": list,
            "dict": dict,
            "string": str,
        }
        field_format = props.get("format", "string")
        instance_format = instance_map[field_format]
        if not (isinstance(value, instance_format) or value in (False, None)):
            raise ValueError(
                f"Field {field} should be in format '{field_format}' "
                f"but its type is '{type(value).__name__}'"
            )
        if (
            field in data_dict
            and props.get("min_level")
            and (
                (props["min_level"] == "extended" and level in ("basicwl", "en16931"))
                or (props["min_level"] == "en16931" and level == "basicwl")
            )
        ):
            logger.warning(
                f"field {field} removed from data_dict because level is {level} "
                f"and minimum level for {field} is {props['min_level']}"
            )
            data_dict.pop(field)
    if level in ("basicwl", "en16931"):
        fields_to_remove = []
        for field in data_dict.keys():
            if field.startswith("EXT-FR-FE-"):
                fields_to_remove.append(field)
        for field_to_remove in fields_to_remove:
            logger.warning(
                f"field {field_to_remove} removed from data_dict because "
                f"level is {level} and minimum level for EXT-FR-FE-xx fields "
                "is 'extended'"
            )
            data_dict.pop(field_to_remove)
    # check periods
    if (
        data_dict.get("BT-73")
        and data_dict.get("BT-74")
        and data_dict["BT-73"] > data_dict["BT-74"]
    ):
        raise ValueError(
            f"BT-73 ({data_dict['BT-73']}) must be before or identical "
            f"to BT-74 ({data_dict['BT-74']})."
        )
    for line_dict in data_dict.get("BG-25") or []:
        if (
            line_dict.get("BT-134")
            and line_dict.get("BT-135")
            and line_dict["BT-134"] > line_dict["BT-135"]
        ):
            raise ValueError(
                f"BT-134 ({line_dict['BT-134']}) must be before or identical "
                f"to BT-135 ({line_dict['BT-135']})."
            )
    # special treatment for BT-8
    if data_dict.get("BT-8") and data_dict["BT-8"] in BT_8toUBL:
        if flavor == "ubl-2.1":
            data_dict["BT-8"] = BT_8toUBL[data_dict["BT-8"]]
        else:
            data_dict["BT-8"] = BT_8toCII[data_dict["BT-8"]]


def _cii_generate_party_block(node_name, namespaces, **kwargs):
    if not node_name:
        raise ValueError("node_name arg is required")
    if not kwargs.get("name"):
        return
    tax_schemes = {}
    if kwargs.get("tax_id"):
        tax_schemes["VA"] = kwargs["tax_id"]
    if kwargs.get("local_tax_id"):
        tax_schemes["FC"] = kwargs["local_tax_id"]
    RAM = namespaces["ram"]
    generate_node_method = getattr(RAM, node_name)
    return generate_node_method(
        *[
            RAM.ID(privateid)
            for schemeid, privateid in (kwargs.get("identifiers") or {}).items()
            if not schemeid
        ],
        *[
            RAM.GlobalID(globalid, schemeID=schemeid)
            for schemeid, globalid in (kwargs.get("identifiers") or {}).items()
            if schemeid
        ],
        RAM.Name(kwargs["name"]),
        *[
            RAM.Description(kwargs["legal_form"])
            for _ in [1]
            if kwargs.get("legal_form")
        ],
        *[RAM.RoleCode(kwargs["role_code"]) for _ in [1] if kwargs.get("role_code")],
        *[
            RAM.SpecifiedLegalOrganization(
                *[
                    RAM.ID(
                        kwargs["legal_org_id"], schemeID=kwargs["legal_org_schemeid"]
                    )
                    for _ in [1]
                    if kwargs.get("legal_org_id") and kwargs.get("legal_org_schemeid")
                ],
                *[
                    RAM.TradingBusinessName(kwargs["biz_name"])
                    for _ in [1]
                    if kwargs.get("biz_name")
                ],
            )
            for _ in [1]
            if (kwargs.get("legal_org_id") and kwargs.get("legal_org_schemeid"))
            or kwargs.get("biz_name")
        ],
        *[
            RAM.DefinedTradeContact(
                *[
                    RAM.PersonName(kwargs["contact_name"])
                    for _ in [1]
                    if kwargs.get("contact_name")
                ],
                *[
                    RAM.DepartmentName(kwargs["contact_department_name"])
                    for _ in [1]
                    if kwargs.get("contact_department_name")
                ],
                *[
                    RAM.TypeCode(kwargs["contact_type_code"])
                    for _ in [1]
                    if kwargs.get("contact_type_code")
                ],
                *[
                    RAM.TelephoneUniversalCommunication(
                        RAM.CompleteNumber(kwargs["contact_phone"])
                    )
                    for _ in [1]
                    if kwargs.get("contact_phone")
                ],
                *[
                    RAM.EmailURIUniversalCommunication(
                        RAM.URIID(kwargs["contact_email"])
                    )
                    for _ in [1]
                    if kwargs.get("contact_email")
                ],
            )
            for _ in [1]
            if kwargs.get("contact_name")
            or kwargs.get("contact_department_name")
            or kwargs.get("contact_type_code")
            or kwargs.get("contact_phone")
            or kwargs.get("contact_email")
        ],
        *[
            RAM.PostalTradeAddress(
                *[
                    RAM.PostcodeCode(kwargs["postcode"])
                    for _ in [1]
                    if kwargs.get("postcode")
                ],
                *[
                    RAM.LineOne(kwargs["addr_line1"])
                    for _ in [1]
                    if kwargs.get("addr_line1")
                ],
                *[
                    RAM.LineTwo(kwargs["addr_line2"])
                    for _ in [1]
                    if kwargs.get("addr_line2")
                ],
                *[
                    RAM.LineThree(kwargs["addr_line3"])
                    for _ in [1]
                    if kwargs.get("addr_line3")
                ],
                *[RAM.CityName(kwargs["city"]) for _ in [1] if kwargs.get("city")],
                RAM.CountryID(kwargs["country_code"]),
                *[
                    RAM.CountrySubDivisionName(kwargs["country_subdivision_name"])
                    for _ in [1]
                    if kwargs.get("country_subdivision_name")
                ],
            )
            for _ in [1]
            if kwargs.get("country_code")
        ],
        *[
            RAM.URIUniversalCommunication(
                RAM.URIID(
                    kwargs["universal_comm_id"],
                    schemeID=kwargs["universal_comm_schemeid"],
                )
            )
            for _ in [1]
            if kwargs.get("universal_comm_id") and kwargs.get("universal_comm_schemeid")
        ],
        *[
            RAM.SpecifiedTaxRegistration(RAM.ID(ident, schemeID=schemeID))
            for schemeID, ident in tax_schemes.items()
        ],
    )


def _cii_generate_additionnal_referenced_doc(data_dict, namespaces):
    res = []
    RAM = namespaces["ram"]
    refdocs = []
    for entry in data_dict.get("BG-24") or []:
        if entry.get("BT-122"):
            refdocs.append(
                {
                    "type_code": "916",
                    "id": entry["BT-122"],
                    "uriid": entry.get("BT-124"),
                    "name": entry.get("BT-123"),
                    "bin": entry.get("BT-125"),
                    "mimecode": entry.get("BT-125-1"),
                    "filename": entry.get("BT-125-2"),
                }
            )
    if data_dict.get("BT-17"):
        refdocs.append({"id": data_dict["BT-17"], "type_code": "50"})
    for ref_type_code, value in (data_dict.get("BT-18-00") or {}).items():
        refdocs.append(
            {
                "type_code": "130",
                "id": value,
                "ref_type_code": ref_type_code,
            }
        )
    for refdoc in refdocs:
        res.append(
            RAM.AdditionalReferencedDocument(
                RAM.IssuerAssignedID(refdoc["id"]),
                *[RAM.URIID(refdoc["uriid"]) for _ in [1] if refdoc.get("uriid")],
                RAM.TypeCode(refdoc["type_code"]),
                *[
                    RAM.ReferenceTypeCode(refdoc["ref_type_code"])
                    for _ in [1]
                    if refdoc.get("ref_type_code")
                ],
                *[RAM.Name(refdoc["name"]) for _ in [1] if refdoc.get("name")],
                *[
                    RAM.AttachmentBinaryObject(
                        refdoc["bin"],
                        mimeCode=refdoc["mimecode"],
                        filename=refdoc["filename"],
                    )
                    for _ in [1]
                    if refdoc.get("bin")
                    and refdoc.get("mimecode")
                    and refdoc.get("filename")
                ],
            )
        )
    return res


def _cii_generate_single_allowance_charge(namespaces, type, indicator, **kwargs):
    RAM = namespaces["ram"]
    UDT = namespaces["udt"]
    if type not in ("global", "line"):
        raise ValueError("Wrong value for type argument")
    if type == "global" and not kwargs.get("tax_categ"):
        raise ValueError("A global allowance charge must have a tax_categ named arg")
    elif type == "line" and "tax_categ" in kwargs:
        raise ValueError(
            "A line-level allowance charge must not have a tax_categ named arg"
        )
    if indicator not in ("false", "true"):
        raise ValueError("Wrong value for indicator argument")
    return RAM.SpecifiedTradeAllowanceCharge(
        RAM.ChargeIndicator(UDT.Indicator(indicator)),
        *[
            RAM.CalculationPercent(kwargs["percent"])
            for _ in [1]
            if kwargs.get("percent")
        ],
        *[
            RAM.BasisAmount(kwargs["base_amount"])
            for _ in [1]
            if kwargs.get("base_amount")
        ],
        RAM.ActualAmount(kwargs["amount"]),
        *[
            RAM.ReasonCode(kwargs["reason_code"])
            for _ in [1]
            if kwargs.get("reason_code")
        ],
        *[RAM.Reason(kwargs["reason"]) for _ in [1] if kwargs.get("reason")],
        *[
            RAM.CategoryTradeTax(
                RAM.TypeCode("VAT"),
                RAM.CategoryCode(kwargs["tax_categ"]),
                *[
                    RAM.RateApplicablePercent(kwargs["tax_rate"])
                    for _ in [1]
                    if kwargs.get("tax_rate")
                ],
            )
            for _ in [1]
            if type == "global"
        ],
    )


def _cii_generate_single_invoice_line(namespaces, line_dict):
    if not isinstance(line_dict, dict):
        raise ValueError("BG-25 must be a list of dicts")
    # BT-127 is 0..1 in EN16931 but 0..n in extended
    # so we accept it both as a string and a list
    if line_dict.get("BT-127") and not isinstance("BT-127", list):
        line_dict["BT-127"] = [line_dict["BT-127"]]
    RAM = namespaces["ram"]
    UDT = namespaces["udt"]
    return RAM.IncludedSupplyChainTradeLineItem(
        RAM.AssociatedDocumentLineDocument(
            RAM.LineID(line_dict["BT-126"]),
            *[
                RAM.IncludedNote(RAM.Content(note))
                for note in (line_dict.get("BT-127") or [])
            ],
        ),
        RAM.SpecifiedTradeProduct(
            *[
                RAM.GlobalID(line_dict["BT-157"], schemeID=line_dict["BT-157-1"])
                for _ in [1]
                if line_dict.get("BT-157") and line_dict.get("BT-157-1")
            ],
            *[
                RAM.SellerAssignedID(line_dict["BT-155"])
                for _ in [1]
                if line_dict.get("BT-155")
            ],
            *[
                RAM.BuyerAssignedID(line_dict["BT-156"])
                for _ in [1]
                if line_dict.get("BT-156")
            ],
            RAM.Name(line_dict["BT-153"]),
            *[
                RAM.Description(line_dict["BT-154"])
                for _ in [1]
                if line_dict.get("BT-154")
            ],
            *[
                RAM.ApplicableProductCharacteristic(
                    RAM.Description(attrib),
                    RAM.Value(value),
                )
                for attrib, value in (line_dict.get("BG-32") or {}).items()
            ],
            *[
                RAM.DesignatedProductClassification(
                    RAM.ClassCode(
                        value,
                        {
                            key: val
                            for key, val in [
                                ("listID", listID),
                                ("listVersionID", listVersionID),
                            ]
                            if val
                        },
                    )
                )
                for (listID, listVersionID), value in (
                    line_dict.get("BT-158-00") or {}
                ).items()
                if listVersionID
            ],
            *[
                RAM.OriginTradeCountry(RAM.ID(line_dict["BT-159"]))
                for _ in [1]
                if line_dict.get("BT-159")
            ],
        ),
        RAM.SpecifiedLineTradeAgreement(
            *[
                RAM.SellerOrderReferencedDocument(
                    *[
                        RAM.IssuerAssignedID(line_dict["EXT-FR-FE-144"])
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-144")
                    ],
                    *[
                        RAM.LineID(line_dict["EXT-FR-FE-145"])
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-145")
                    ],
                )
                for _ in [1]
                if line_dict.get("EXT-FR-FE-144") or line_dict.get("EXT-FR-FE-145")
            ],
            *[
                RAM.BuyerOrderReferencedDocument(
                    *[
                        RAM.IssuerAssignedID(line_dict["EXT-FR-FE-135"])
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-135")
                    ],
                    *[
                        RAM.LineID(line_dict["BT-132"])
                        for _ in [1]
                        if line_dict.get("BT-132")
                    ],
                )
                for _ in [1]
                if line_dict.get("EXT-FR-FE-135") or line_dict.get("BT-132")
            ],
            *[
                RAM.GrossPriceProductTradePrice(
                    *[
                        RAM.ChargeAmount(line_dict["BT-148"])
                        for _ in [1]
                        if line_dict.get("BT-148")
                    ],
                    *[
                        RAM.BasisQuantity(
                            line_dict["BT-149-1"], unitCode=line_dict["BT-150-1"]
                        )
                        for _ in [1]
                        if line_dict.get("BT-149-1") and line_dict.get("BT-150-1")
                    ],
                    *[
                        RAM.AppliedTradeAllowanceCharge(
                            RAM.ChargeIndicator(UDT.Indicator("false")),
                            RAM.ActualAmount(line_dict["BT-147"]),
                        )
                        for _ in [1]
                        if line_dict.get("BT-147")
                    ],
                )
                for _ in [1]
                if line_dict.get("BT-148")
                or (line_dict.get("BT-149-1") and line_dict.get("BT-150-1"))
                or line_dict.get("BT-147")
            ],
            RAM.NetPriceProductTradePrice(
                RAM.ChargeAmount(line_dict["BT-146"]),
                *[
                    RAM.BasisQuantity(
                        line_dict["BT-149"],
                        unitCode=line_dict["BT-150"],
                    )
                    for _ in [1]
                    if line_dict.get("BT-149") and line_dict.get("BT-150")
                ],
            ),
        ),
        RAM.SpecifiedLineTradeDelivery(
            RAM.BilledQuantity(line_dict["BT-129"], unitCode=line_dict["BT-130"])
        ),
        RAM.SpecifiedLineTradeSettlement(
            RAM.ApplicableTradeTax(
                RAM.TypeCode("VAT"),
                RAM.CategoryCode(line_dict["BT-151"]),
                *[
                    RAM.RateApplicablePercent(line_dict["BT-152"])
                    for _ in [1]
                    if line_dict.get("BT-152")
                ],
            ),
            *[
                RAM.BillingSpecifiedPeriod(
                    *[
                        RAM.StartDateTime(
                            UDT.DateTimeString(
                                _cii_date_to_string(line_dict["BT-134"]), format="102"
                            )
                        )
                        for _ in [1]
                        if line_dict.get("BT-134")
                    ],
                    *[
                        RAM.EndDateTime(
                            UDT.DateTimeString(
                                _cii_date_to_string(line_dict["BT-135"]), format="102"
                            )
                        )
                        for _ in [1]
                        if line_dict.get("BT-135")
                    ],
                )
                for _ in [1]
                if line_dict.get("BT-134") or line_dict.get("BT-135")
            ],
            *[
                _cii_generate_single_allowance_charge(
                    namespaces,
                    "line",
                    "false",
                    amount=charge["BT-136"],
                    reason_code=charge.get("BT-140"),
                    reason=charge.get("BT-139"),
                    percent=charge.get("BT-138"),
                    base_amount=charge.get("BT-137"),
                )
                for charge in (line_dict.get("BG-27") or [])
            ],
            *[
                _cii_generate_single_allowance_charge(
                    namespaces,
                    "line",
                    "true",
                    amount=charge["BT-141"],
                    reason_code=charge.get("BT-145"),
                    reason=charge.get("BT-144"),
                    percent=charge.get("BT-143"),
                    base_amount=charge.get("BT-142"),
                )
                for charge in (line_dict.get("BG-28") or [])
            ],
            RAM.SpecifiedTradeSettlementLineMonetarySummation(
                RAM.LineTotalAmount(line_dict["BT-131"]),
            ),
            *[
                RAM.AdditionalReferencedDocument(
                    RAM.IssuerAssignedID(value),
                    RAM.TypeCode("130"),
                    *[
                        RAM.ReferenceTypeCode(ref_type_code)
                        for _ in [1]
                        if ref_type_code
                    ],
                )
                for ref_type_code, value in (line_dict.get("BT-128-00") or {}).items()
            ],
            *[
                RAM.ReceivableSpecifiedTradeAccountingAccount(
                    RAM.ID(line_dict["BT-133"])
                )
                for _ in [1]
                if line_dict.get("BT-133")
            ],
        ),
    )


def generate_cii_xml(
    data_dict, level="autodetect", check_xsd=True, check_schematron="base"
):
    # in data_dict, the key names use ID CII and not ID Modèle AFNOR FE
    # because we don't want France-specific stuff
    if not isinstance(data_dict, dict):
        raise ValueError("data_dict arg must be a dict")
    if level == "autodetect":
        if not data_dict.get("BT-24"):
            raise ValueError("level='autodetect' requires a 'BT-24' key in data_dict'")
        for level_option, bt_24 in LEVEL2BT_24.items():
            if bt_24 == data_dict["BT-24"]:
                level = level_option
        if level == "autodetect":
            raise ValueError(
                "Autodetection of level failed because the value of "
                f"data_dict['BT-24'] ({data_dict['BT-24']}) is invalid"
            )
    elif level in LEVEL2BT_24:
        bt_24 = LEVEL2BT_24[level]
        if data_dict.get("BT-24") and data_dict["BT-24"] != bt_24:
            logger.warning(
                f"Overwriting 'BT-24' in data_dict for level '{level}': "
                f"initial value '{data_dict['BT-24']}' -> new value '{bt_24}'"
            )
        data_dict["BT-24"] = bt_24
    else:
        raise ValueError(
            "level arg has 5 possible values for CII/Factur-X: "
            "'basicwl', 'en16931', 'extended', 'extended-ctc-fr' and 'autodetect'"
        )

    _check_data_dict(data_dict, "factur-x", level)
    FX_NAMESPACES = XML_NAMESPACES["factur-x"]
    RSM = objectify.ElementMaker(
        namespace=FX_NAMESPACES["rsm"], nsmap=FX_NAMESPACES, annotate=False
    )
    RAM = objectify.ElementMaker(namespace=FX_NAMESPACES["ram"], annotate=False)
    UDT = objectify.ElementMaker(namespace=FX_NAMESPACES["udt"], annotate=False)
    QDT = objectify.ElementMaker(namespace=FX_NAMESPACES["qdt"], annotate=False)
    namespaces = {
        "ram": RAM,
        "rsm": RSM,
        "udt": UDT,
        "qdt": QDT,
    }

    xml_root = RSM.CrossIndustryInvoice(
        RSM.ExchangedDocumentContext(
            *[
                RAM.BusinessProcessSpecifiedDocumentContextParameter(
                    RAM.ID(data_dict["BT-23"])
                )
                for _ in [1]
                if data_dict.get("BT-23")
            ],
            RAM.GuidelineSpecifiedDocumentContextParameter(RAM.ID(data_dict["BT-24"])),
        ),
        RSM.ExchangedDocument(
            RAM.ID(data_dict["BT-1"]),
            RAM.TypeCode(data_dict["BT-3"]),
            RAM.IssueDateTime(
                UDT.DateTimeString(
                    _cii_date_to_string(data_dict["BT-2"]), format="102"
                ),
            ),
            *[
                RAM.IncludedNote(
                    RAM.Content(note["BT-22"]),
                    *[RAM.SubjectCode(note["BT-21"]) for _ in [1] if note.get("BT-21")],
                )
                for note in (data_dict.get("BG-1") or [])
            ],
        ),
        RSM.SupplyChainTradeTransaction(
            *[
                _cii_generate_single_invoice_line(namespaces, iline)
                for iline in (data_dict.get("BG-25") or [])
            ],
            RAM.ApplicableHeaderTradeAgreement(
                *[
                    RAM.BuyerReference(data_dict["BT-10"])
                    for _ in [1]
                    if data_dict.get("BT-10")
                ],
                # SELLER  BG-4
                _cii_generate_party_block(
                    "SellerTradeParty",
                    namespaces,
                    identifiers=data_dict.get("BT-29"),
                    name=data_dict["BT-27"],
                    legal_form=data_dict.get("BT-33"),
                    legal_org_id=data_dict.get("BT-30"),
                    legal_org_schemeid=data_dict.get("BT-30-1"),
                    biz_name=data_dict.get("BT-28"),
                    contact_name=data_dict.get("BT-41"),
                    contact_department_name=data_dict.get("BT-41-0"),
                    contact_phone=data_dict.get("BT-42"),
                    contact_email=data_dict.get("BT-43"),
                    country_code=data_dict["BT-40"],
                    country_subdivision_name=data_dict.get("BT-39"),
                    postcode=data_dict.get("BT-38"),
                    city=data_dict.get("BT-37"),
                    addr_line1=data_dict.get("BT-35"),
                    addr_line2=data_dict.get("BT-36"),
                    addr_line3=data_dict.get("BT-162"),
                    universal_comm_id=data_dict.get("BT-34"),
                    universal_comm_schemeid=data_dict.get("BT-34-1"),
                    tax_id=data_dict.get("BT-31"),
                    local_tax_id=data_dict.get("BT-32"),
                ),
                # BUYER  BG-7
                _cii_generate_party_block(
                    "BuyerTradeParty",
                    namespaces,
                    identifiers=data_dict.get("BT-46"),
                    name=data_dict["BT-44"],
                    legal_org_id=data_dict.get("BT-47"),
                    legal_org_schemeid=data_dict.get("BT-47-1"),
                    biz_name=data_dict.get("BT-45"),
                    contact_name=data_dict.get("BT-56"),
                    contact_department_name=data_dict.get("BT-56-0"),
                    contact_phone=data_dict.get("BT-57"),
                    contact_email=data_dict.get("BT-58"),
                    country_code=data_dict["BT-55"],
                    country_subdivision_name=data_dict.get("BT-54"),
                    postcode=data_dict.get("BT-53"),
                    city=data_dict.get("BT-52"),
                    addr_line1=data_dict.get("BT-50"),
                    addr_line2=data_dict.get("BT-51"),
                    addr_line3=data_dict.get("BT-163"),
                    universal_comm_id=data_dict.get("BT-49"),
                    universal_comm_schemeid=data_dict.get("BT-49-1"),
                    tax_id=data_dict.get("BT-48"),
                ),
                # Sales Agent  EXT-FR-FE-BG-03
                _cii_generate_party_block(
                    "SalesAgentTradeParty",
                    namespaces,
                    identifiers=data_dict.get("EXT-FR-FE-69"),
                    name=data_dict.get("EXT-FR-FE-66"),
                    role_code=data_dict.get("EXT-FR-FE-67"),
                    legal_org_id=data_dict.get("EXT-FR-FE-71"),
                    legal_org_schemeid=data_dict.get("EXT-FR-FE-72"),
                    biz_name=data_dict.get("EXT-FR-FE-68"),
                    contact_name=data_dict.get("EXT-FR-FE-86"),
                    contact_phone=data_dict.get("EXT-FR-FE-87"),
                    contact_email=data_dict.get("EXT-FR-FE-88"),
                    country_code=data_dict.get("EXT-FR-FE-84"),
                    country_subdivision_name=data_dict.get("EXT-FR-FE-83"),
                    postcode=data_dict.get("EXT-FR-FE-81"),
                    city=data_dict.get("EXT-FR-FE-82"),
                    addr_line1=data_dict.get("EXT-FR-FE-78"),
                    addr_line2=data_dict.get("EXT-FR-FE-79"),
                    addr_line3=data_dict.get("EXT-FR-FE-80"),
                    universal_comm_id=data_dict.get("EXT-FR-FE-75"),
                    universal_comm_schemeid=data_dict.get("EXT-FR-FE-76"),
                    tax_id=data_dict.get("EXT-FR-FE-73"),
                ),
                # Seller Tax Representative  BG-11
                _cii_generate_party_block(
                    "SellerTaxRepresentativeTradeParty",
                    namespaces,
                    name=data_dict.get("BT-62"),
                    country_code=data_dict.get("BT-69"),
                    country_subdivision_name=data_dict.get("BT-68"),
                    postcode=data_dict.get("BT-67"),
                    city=data_dict.get("BT-66"),
                    addr_line1=data_dict.get("BT-64"),
                    addr_line2=data_dict.get("BT-65"),
                    addr_line3=data_dict.get("BT-164"),
                    tax_id=data_dict.get("BT-63"),
                ),
                *[
                    RAM.SellerOrderReferencedDocument(
                        RAM.IssuerAssignedID(data_dict["BT-14"])
                    )
                    for _ in [1]
                    if data_dict.get("BT-14")
                ],
                *[
                    RAM.BuyerOrderReferencedDocument(
                        RAM.IssuerAssignedID(data_dict["BT-13"])
                    )
                    for _ in [1]
                    if data_dict.get("BT-13")
                ],
                *[
                    RAM.ContractReferencedDocument(
                        RAM.IssuerAssignedID(data_dict["BT-12"])
                    )
                    for _ in [1]
                    if data_dict.get("BT-12")
                ],
                *[
                    node
                    for node in _cii_generate_additionnal_referenced_doc(
                        data_dict, namespaces
                    )
                ],
                # Buyer Agent  EXT-FR-FE-BG-01
                _cii_generate_party_block(
                    "BuyerAgentTradeParty",
                    namespaces,
                    identifiers=data_dict.get("EXT-FR-FE-06"),
                    name=data_dict.get("EXT-FR-FE-03"),
                    role_code=data_dict.get("EXT-FR-FE-04"),
                    legal_org_id=data_dict.get("EXT-FR-FE-08"),
                    legal_org_schemeid=data_dict.get("EXT-FR-FE-09"),
                    biz_name=data_dict.get("EXT-FR-FE-05"),
                    contact_name=data_dict.get("EXT-FR-FE-23"),
                    contact_phone=data_dict.get("EXT-FR-FE-24"),
                    contact_email=data_dict.get("EXT-FR-FE-25"),
                    country_code=data_dict.get("EXT-FR-FE-21"),
                    country_subdivision_name=data_dict.get("EXT-FR-FE-20"),
                    postcode=data_dict.get("EXT-FR-FE-18"),
                    city=data_dict.get("EXT-FR-FE-19"),
                    addr_line1=data_dict.get("EXT-FR-FE-15"),
                    addr_line2=data_dict.get("EXT-FR-FE-16"),
                    addr_line3=data_dict.get("EXT-FR-FE-17"),
                    universal_comm_id=data_dict.get("EXT-FR-FE-12"),
                    universal_comm_schemeid=data_dict.get("EXT-FR-FE-13"),
                    tax_id=data_dict.get("EXT-FR-FE-10"),
                ),
                *[
                    RAM.SpecifiedProcuringProject(
                        RAM.ID(data_dict["BT-11"]),
                        *[
                            RAM.Name(data_dict["BT-11-0"])
                            for _ in [1]
                            if data_dict.get("BT-11-0")
                        ],
                    )
                    for _ in [1]
                    if data_dict.get("BT-11")
                ],
            ),
            RAM.ApplicableHeaderTradeDelivery(
                _cii_generate_party_block(
                    "ShipToTradeParty",
                    namespaces,
                    identifiers=data_dict.get("BT-71"),
                    name=data_dict.get("BT-70"),
                    country_code=data_dict.get("BT-80"),
                    country_subdivision_name=data_dict.get("BT-79"),
                    postcode=data_dict.get("BT-78"),
                    city=data_dict.get("BT-77"),
                    addr_line1=data_dict.get("BT-75"),
                    addr_line2=data_dict.get("BT-76"),
                    addr_line3=data_dict.get("BT-165"),
                ),
                *[
                    RAM.ActualDeliverySupplyChainEvent(
                        RAM.OccurrenceDateTime(
                            UDT.DateTimeString(
                                _cii_date_to_string(data_dict["BT-72"]), format="102"
                            )
                        )
                    )
                    for _ in [1]
                    if data_dict.get("BT-72")
                ],
                *[
                    RAM.DespatchAdviceReferencedDocument(
                        RAM.IssuerAssignedID(data_dict["BT-16"])
                    )
                    for _ in [1]
                    if data_dict.get("BT-16")
                ],
                *[
                    RAM.ReceivingAdviceReferencedDocument(
                        RAM.IssuerAssignedID(data_dict["BT-15"])
                    )
                    for _ in [1]
                    if data_dict.get("BT-15")
                ],
            ),
            RAM.ApplicableHeaderTradeSettlement(
                *[
                    RAM.CreditorReferenceID(data_dict["BT-90"])
                    for _ in [1]
                    if data_dict.get("BT-90")
                ],
                *[
                    RAM.PaymentReference(_cii_date_to_string(data_dict["BT-83"]))
                    for _ in [1]
                    if data_dict.get("BT-83")
                ],
                *[
                    RAM.TaxCurrencyCode(data_dict["BT-6"])
                    for _ in [1]
                    if data_dict.get("BT-6")
                ],
                RAM.InvoiceCurrencyCode(data_dict["BT-5"]),
                # Invoicer  EXT-FR-FE-BG-05
                _cii_generate_party_block(
                    "InvoicerTradeParty",
                    namespaces,
                    identifiers=data_dict.get("EXT-FR-FE-115"),
                    name=data_dict.get("EXT-FR-FE-112"),
                    role_code=data_dict.get("EXT-FR-FE-113"),
                    legal_org_id=data_dict.get("EXT-FR-FE-117"),
                    legal_org_schemeid=data_dict.get("EXT-FR-FE-118"),
                    biz_name=data_dict.get("EXT-FR-FE-114"),
                    contact_name=data_dict.get("EXT-FR-FE-132"),
                    contact_phone=data_dict.get("EXT-FR-FE-133"),
                    contact_email=data_dict.get("EXT-FR-FE-134"),
                    country_code=data_dict.get("EXT-FR-FE-130"),
                    country_subdivision_name=data_dict.get("EXT-FR-FE-129"),
                    postcode=data_dict.get("EXT-FR-FE-128"),
                    city=data_dict.get("EXT-FR-FE-127"),
                    addr_line1=data_dict.get("EXT-FR-FE-124"),
                    addr_line2=data_dict.get("EXT-FR-FE-125"),
                    addr_line3=data_dict.get("EXT-FR-FE-126"),
                    universal_comm_id=data_dict.get("EXT-FR-FE-121"),
                    universal_comm_schemeid=data_dict.get("EXT-FR-FE-122"),
                    tax_id=data_dict.get("EXT-FR-FE-119"),
                ),
                # Invoicee  EXT-FR-FE-BG-04
                _cii_generate_party_block(
                    "InvoiceeTradeParty",
                    namespaces,
                    identifiers=data_dict.get("EXT-FR-FE-92"),
                    name=data_dict.get("EXT-FR-FE-89"),
                    role_code=data_dict.get("EXT-FR-FE-90"),
                    legal_org_id=data_dict.get("EXT-FR-FE-94"),
                    legal_org_schemeid=data_dict.get("EXT-FR-FE-95"),
                    biz_name=data_dict.get("EXT-FR-FE-91"),
                    contact_name=data_dict.get("EXT-FR-FE-109"),
                    contact_phone=data_dict.get("EXT-FR-FE-110"),
                    contact_email=data_dict.get("EXT-FR-FE-111"),
                    country_code=data_dict.get("EXT-FR-FE-107"),
                    country_subdivision_name=data_dict.get("EXT-FR-FE-106"),
                    postcode=data_dict.get("EXT-FR-FE-105"),
                    city=data_dict.get("EXT-FR-FE-104"),
                    addr_line1=data_dict.get("EXT-FR-FE-101"),
                    addr_line2=data_dict.get("EXT-FR-FE-102"),
                    addr_line3=data_dict.get("EXT-FR-FE-103"),
                    universal_comm_id=data_dict.get("EXT-FR-FE-98"),
                    universal_comm_schemeid=data_dict.get("EXT-FR-FE-99"),
                    tax_id=data_dict.get("EXT-FR-FE-96"),
                ),
                # Payee (Basic WL)  BG-10
                _cii_generate_party_block(
                    "PayeeTradeParty",
                    namespaces,
                    identifiers=data_dict.get("BT-60"),
                    name=data_dict.get("BT-59"),
                    role_code=data_dict.get("EXT-FR-FE-26"),
                    legal_org_id=data_dict.get("BT-61"),
                    legal_org_schemeid=data_dict.get("BT-61-1"),
                    contact_name=data_dict.get("EXT-FR-FE-40"),
                    contact_phone=data_dict.get("EXT-FR-FE-41"),
                    contact_email=data_dict.get("EXT-FR-FE-42"),
                    country_code=data_dict.get("EXT-FR-FE-38"),
                    country_subdivision_name=data_dict.get("EXT-FR-FE-37"),
                    postcode=data_dict.get("EXT-FR-FE-36"),
                    city=data_dict.get("EXT-FR-FE-35"),
                    addr_line1=data_dict.get("EXT-FR-FE-32"),
                    addr_line2=data_dict.get("EXT-FR-FE-33"),
                    addr_line3=data_dict.get("EXT-FR-FE-34"),
                    universal_comm_id=data_dict.get("EXT-FR-FE-29"),
                    universal_comm_schemeid=data_dict.get("EXT-FR-FE-30"),
                    tax_id=data_dict.get("EXT-FR-FE-27"),
                ),
                # Payer  EXT-FR-FE-BG-02
                _cii_generate_party_block(
                    "PayerTradeParty",
                    namespaces,
                    identifiers=data_dict.get("EXT-FR-FE-46"),
                    name=data_dict.get("EXT-FR-FE-43"),
                    role_code=data_dict.get("EXT-FR-FE-44"),
                    legal_org_id=data_dict.get("EXT-FR-FE-48"),
                    legal_org_schemeid=data_dict.get("EXT-FR-FE-49"),
                    biz_name=data_dict.get("EXT-FR-FE-45"),
                    contact_name=data_dict.get("EXT-FR-FE-63"),
                    contact_phone=data_dict.get("EXT-FR-FE-64"),
                    contact_email=data_dict.get("EXT-FR-FE-65"),
                    country_code=data_dict.get("EXT-FR-FE-61"),
                    country_subdivision_name=data_dict.get("EXT-FR-FE-60"),
                    postcode=data_dict.get("EXT-FR-FE-59"),
                    city=data_dict.get("EXT-FR-FE-58"),
                    addr_line1=data_dict.get("EXT-FR-FE-55"),
                    addr_line2=data_dict.get("EXT-FR-FE-56"),
                    addr_line3=data_dict.get("EXT-FR-FE-57"),
                    universal_comm_id=data_dict.get("EXT-FR-FE-52"),
                    universal_comm_schemeid=data_dict.get("EXT-FR-FE-53"),
                    tax_id=data_dict.get("EXT-FR-FE-50"),
                ),
                *[
                    RAM.SpecifiedTradeSettlementPaymentMeans(
                        RAM.TypeCode(data_dict["BT-81"]),
                        *[
                            RAM.Information(data_dict["BT-82"])
                            for _ in [1]
                            if data_dict.get("BT-82")
                        ],
                        *[
                            RAM.ApplicableTradeSettlementFinancialCard(
                                RAM.ID(data_dict["BT-87"]),
                                *[
                                    RAM.CardholderName(data_dict["BT-88"])
                                    for _ in [1]
                                    if data_dict.get("BT-88")
                                ],
                            )
                            for _ in [1]
                            if data_dict.get("BT-87")
                        ],
                        *[
                            RAM.PayerPartyDebtorFinancialAccount(
                                RAM.IBANID(data_dict["BT-91"])
                            )
                            for _ in [1]
                            if data_dict.get("BT-91")
                        ],
                        *[
                            RAM.PayeePartyCreditorFinancialAccount(
                                *[
                                    RAM.IBANID(data_dict["BT-84"])
                                    for _ in [1]
                                    if data_dict.get("BT-84")
                                    and iban_is_valid(data_dict["BT-84"])
                                ],
                                *[
                                    RAM.AccountName(data_dict["BT-85"])
                                    for _ in [1]
                                    if data_dict.get("BT-85")
                                ],
                                *[
                                    RAM.ProprietaryID(data_dict["BT-84"])
                                    for _ in [1]
                                    if data_dict.get("BT-84")
                                    and not iban_is_valid(data_dict["BT-84"])
                                ],
                            )
                            for _ in [1]
                            if data_dict.get("BT-84")
                        ],
                        *[
                            RAM.PayeeSpecifiedCreditorFinancialInstitution(
                                RAM.BICID(data_dict["BT-86"])
                            )
                            for _ in [1]
                            if data_dict.get("BT-86")
                        ],
                    )
                    for _ in [1]
                    if data_dict.get("BT-81")
                ],
                *[
                    RAM.ApplicableTradeTax(
                        RAM.CalculatedAmount(tax_dict["BT-117"]),
                        RAM.TypeCode("VAT"),
                        *[
                            RAM.ExemptionReason(tax_dict["BT-120"])
                            for _ in [1]
                            if tax_dict.get("BT-120")
                        ],
                        RAM.BasisAmount(tax_dict["BT-116"]),
                        RAM.CategoryCode(tax_dict["BT-118"]),
                        *[
                            RAM.ExemptionReasonCode(tax_dict["BT-121"])
                            for _ in [1]
                            if tax_dict.get("BT-121")
                        ],
                        *[
                            RAM.TaxPointDate(
                                UDT.DateString(
                                    _cii_date_to_string(data_dict["BT-7"]), format="102"
                                )
                            )
                            for _ in [1]
                            if tax_dict.get("BT-7")
                        ],  # not used in France
                        *[
                            RAM.DueDateTypeCode(data_dict["BT-8"])
                            for _ in [1]
                            if data_dict.get("BT-8")
                        ],
                        *[
                            RAM.RateApplicablePercent(tax_dict["BT-119"])
                            for _ in [1]
                            if tax_dict.get("BT-119")
                        ],
                    )
                    for tax_dict in data_dict["BG-23"]
                ],
                *[
                    RAM.BillingSpecifiedPeriod(
                        *[
                            RAM.StartDateTime(
                                UDT.DateTimeString(
                                    _cii_date_to_string(data_dict["BT-73"]),
                                    format="102",
                                )
                            )
                            for _ in [1]
                            if data_dict.get("BT-73")
                        ],
                        *[
                            RAM.EndDateTime(
                                UDT.DateTimeString(
                                    _cii_date_to_string(data_dict["BT-74"]),
                                    format="102",
                                )
                            )
                            for _ in [1]
                            if data_dict.get("BT-74")
                        ],
                    )
                    for _ in [1]
                    if data_dict.get("BT-73") or data_dict.get("BT-74")
                ],
                *[
                    _cii_generate_single_allowance_charge(
                        namespaces,
                        "global",
                        "false",
                        amount=charge["BT-92"],
                        reason_code=charge.get("BT-98"),
                        reason=charge.get("BT-97"),
                        percent=charge.get("BT-94"),
                        base_amount=charge.get("BT-93"),
                        tax_categ=charge["BT-95"],
                        tax_rate=charge.get("BT-96"),
                    )
                    for charge in (data_dict.get("BG-20") or [])
                ],
                *[
                    _cii_generate_single_allowance_charge(
                        namespaces,
                        "global",
                        "true",
                        amount=charge["BT-99"],
                        reason_code=charge.get("BT-105"),
                        reason=charge.get("BT-104"),
                        percent=charge.get("BT-101"),
                        base_amount=charge.get("BT-100"),
                        tax_categ=charge["BT-102"],
                        tax_rate=charge.get("BT-103"),
                    )
                    for charge in (data_dict.get("BG-21") or [])
                ],
                *[
                    RAM.SpecifiedTradePaymentTerms(
                        *[
                            RAM.Description(data_dict["BT-20"])
                            for _ in [1]
                            if data_dict.get("BT-20")
                        ],
                        *[
                            RAM.DueDateDateTime(
                                UDT.DateTimeString(
                                    _cii_date_to_string(data_dict["BT-9"]), format="102"
                                )
                            )
                            for _ in [1]
                            if data_dict.get("BT-9")
                        ],
                        *[
                            RAM.DirectDebitMandateID(data_dict["BT-89"])
                            for _ in [1]
                            if data_dict.get("BT-89")
                        ],
                    )
                    for _ in [1]
                    if data_dict.get("BT-20")
                    or data_dict.get("BT-9")
                    or data_dict.get("BT-89")
                ],
                RAM.SpecifiedTradeSettlementHeaderMonetarySummation(
                    RAM.LineTotalAmount(data_dict["BT-106"]),
                    *[
                        RAM.ChargeTotalAmount(data_dict["BT-108"])
                        for _ in [1]
                        if data_dict.get("BT-108")
                    ],
                    *[
                        RAM.AllowanceTotalAmount(data_dict["BT-107"])
                        for _ in [1]
                        if data_dict.get("BT-107")
                    ],
                    RAM.TaxBasisTotalAmount(data_dict["BT-109"]),
                    *[
                        RAM.TaxTotalAmount(
                            data_dict["BT-110"], currencyID=data_dict["BT-110-1"]
                        )
                        for _ in [1]
                        if data_dict.get("BT-110") and data_dict.get("BT-110-1")
                    ],
                    RAM.TaxTotalAmount(
                        data_dict["BT-111"], currencyID=data_dict["BT-111-1"]
                    ),
                    *[
                        RAM.RoundingAmount(data_dict["BT-114"])
                        for _ in [1]
                        if data_dict.get("BT-114")
                    ],
                    RAM.GrandTotalAmount(data_dict["BT-112"]),
                    *[
                        RAM.TotalPrepaidAmount(data_dict["BT-113"])
                        for _ in [1]
                        if data_dict.get("BT-113")
                    ],
                    RAM.DuePayableAmount(data_dict["BT-115"]),
                ),
                *[
                    RAM.InvoiceReferencedDocument(
                        RAM.IssuerAssignedID(previnv["BT-25"]),
                        *[
                            RAM.FormattedIssueDateTime(
                                QDT.DateTimeString(
                                    _cii_date_to_string(previnv["BT-26"]), format="102"
                                )
                            )
                            for _ in [1]
                            if previnv.get("BT-26")
                        ],
                    )
                    for previnv in (data_dict.get("BG-3") or [])
                ],
                *[
                    RAM.ReceivableSpecifiedTradeAccountingAccount(
                        RAM.ID(data_dict["BT-19"])
                    )
                    for _ in [1]
                    if data_dict.get("BT-19")
                ],
            ),
        ),
    )
    xml_bytes = etree.tostring(
        xml_root, pretty_print=True, xml_declaration=True, encoding="UTF-8"
    )
    if check_xsd:
        xml_check_xsd(xml_root, flavor="factur-x", level=level)
    if check_schematron:
        xml_check_schematron(
            xml_bytes, flavor="factur-x", level=level, check_option=check_schematron
        )
    return xml_bytes


def _ubl_generate_party(node_name, namespaces, **kwargs):
    if not node_name:
        raise ValueError("node_name arg is required")
    if not kwargs.get("name") and not kwargs.get("biz_name"):
        return
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    tax_schemes = {}
    if kwargs.get("tax_id"):
        tax_schemes["VAT"] = kwargs["tax_id"]
    if kwargs.get("local_tax_id"):
        tax_schemes["LOC"] = kwargs["local_tax_id"]
    generate_node_method = getattr(CAC, node_name)
    return generate_node_method(
        *[
            CBC.EndpointID(
                kwargs["universal_comm_id"], schemeID=kwargs["universal_comm_schemeid"]
            )
            for _ in [1]
            if kwargs.get("universal_comm_id") and kwargs.get("universal_comm_schemeid")
        ],
        *[
            CAC.PartyIdentification(
                CBC.ID(
                    ident, {key: val for key, val in [("schemeID", schemeid)] if val}
                )
            )
            for schemeid, ident in (kwargs.get("identifiers") or {}).items()
        ],
        *[
            CAC.PartyName(CBC.Name(kwargs["biz_name"]))
            for _ in [1]
            if kwargs.get("biz_name")
        ],
        _ubl_generate_address("PostalAddress", namespaces, **kwargs),
        *[
            CAC.PartyTaxScheme(
                CBC.CompanyID(ident),
                CAC.TaxScheme(CBC.ID(scheme)),
            )
            for scheme, ident in tax_schemes.items()
        ],
        *[
            CAC.PartyLegalEntity(
                *[
                    CBC.RegistrationName(kwargs["name"])
                    for _ in [1]
                    if kwargs.get("name")
                ],
                *[
                    CBC.CompanyID(
                        kwargs["legal_org_id"], schemeID=kwargs["legal_org_schemeid"]
                    )
                    for _ in [1]
                    if kwargs.get("legal_org_id") and kwargs.get("legal_org_schemeid")
                ],
                *[
                    CBC.CompanyLegalForm(kwargs["legal_form"])
                    for _ in [1]
                    if kwargs.get("legal_form")
                ],
            )
            for _ in [1]
            if kwargs.get("name")
            or (kwargs.get("legal_org_id") and kwargs.get("legal_org_schemeid"))
            or kwargs.get("legal_form")
        ],
        *[
            CAC.Contact(
                *[
                    CBC.Name(kwargs["contact_name"])
                    for _ in [1]
                    if kwargs.get("contact_name")
                ],
                *[
                    CBC.Telephone(kwargs["contact_phone"])
                    for _ in [1]
                    if kwargs.get("contact_phone")
                ],
                *[
                    CBC.ElectronicMail(kwargs["contact_email"])
                    for _ in [1]
                    if kwargs.get("contact_email")
                ],
            )
            for _ in [1]
            if kwargs.get("contact_name")
            or kwargs.get("contact_department_name")
            or kwargs.get("contact_type_code")
            or kwargs.get("contact_phone")
            or kwargs.get("contact_email")
        ],
    )


def _ubl_generate_location(node_name, namespaces, **kwargs):
    if not node_name:
        raise ValueError("node_name arg is required")
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    if not kwargs.get("country_code") and not kwargs.get("identifiers"):
        return
    generate_node_method = getattr(CAC, node_name)
    return generate_node_method(
        *[
            CBC.ID(ident, {key: val for key, val in [("schemeID", schemeid)] if val})
            for schemeid, ident in (kwargs.get("identifiers") or {}).items()
        ],
        _ubl_generate_address("Address", namespaces, **kwargs),
    )


def _ubl_generate_address(node_name, namespaces, **kwargs):
    if not node_name:
        raise ValueError("node_name arg is required")
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    if not kwargs.get("country_code"):
        return
    generate_node_method = getattr(CAC, node_name)
    return generate_node_method(
        *[
            CBC.StreetName(kwargs["addr_line1"])
            for _ in [1]
            if kwargs.get("addr_line1")
        ],
        *[
            CBC.AdditionalStreetName(kwargs["addr_line2"])
            for _ in [1]
            if kwargs.get("addr_line2")
        ],
        *[CBC.CityName(kwargs["city"]) for _ in [1] if kwargs.get("city")],
        *[CBC.PostalZone(kwargs["postcode"]) for _ in [1] if kwargs.get("postcode")],
        *[
            CBC.CountrySubentity(kwargs["country_subdivision_name"])
            for _ in [1]
            if kwargs.get("country_subdivision_name")
        ],
        *[
            CAC.AddressLine(CBC.Line(kwargs["addr_line3"]))
            for _ in [1]
            if kwargs.get("addr_line3")
        ],
        CAC.Country(CBC.IdentificationCode(kwargs["country_code"])),
    )


def _ubl_generate_additional_doc_ref(data_dict, namespaces):
    res = []
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    refdocs = []
    for entry in data_dict.get("BG-24") or []:
        if entry.get("BT-122"):
            refdocs.append(
                {
                    "type_code": "916",
                    "id": entry["BT-122"],
                    "uri": entry.get("BT-124"),
                    "description": entry.get("BT-123"),
                    "bin": entry.get("BT-125"),
                    "mimecode": entry.get("BT-125-1"),
                    "filename": entry.get("BT-125-2"),
                }
            )
    for schemeid, value in (data_dict.get("BT-18-00") or {}).items():
        refdocs.append(
            {
                "type_code": "130",
                "id": value,
                "schemeid": schemeid,
            }
        )
    for refdoc in refdocs:
        res.append(
            CAC.AdditionalDocumentReference(
                CBC.ID(
                    refdoc["id"],
                    {
                        key: val
                        for key, val in [("schemeID", refdoc.get("schemeid"))]
                        if val
                    },
                ),
                *[
                    CBC.DocumentTypeCode(refdoc["type_code"])
                    for _ in [1]
                    if refdoc.get("type_code")
                ],
                *[
                    CBC.DocumentDescription(refdoc["description"])
                    for _ in [1]
                    if refdoc.get("description")
                ],
                *[
                    CAC.Attachment(
                        *[
                            CBC.EmbeddedDocumentBinaryObject(
                                refdoc["bin"],
                                mimeCode=refdoc["mimecode"],
                                filename=refdoc["filename"],
                            )
                            for _ in [1]
                            if refdoc.get("bin")
                            and refdoc.get("mimecode")
                            and refdoc.get("filename")
                        ],
                        *[
                            CAC.ExternalReference(CBC.URI(refdoc["uri"]))
                            for _ in [1]
                            if refdoc.get("uri")
                        ],
                    )
                    for _ in [1]
                    if (
                        refdoc.get("bin")
                        and refdoc.get("mimecode")
                        and refdoc.get("filename")
                    )
                    or refdoc.get("uri")
                ],
            )
        )
    return res


def _ubl_generate_single_allowance_charge(namespaces, type, indicator, **kwargs):
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    if type not in ("global", "line"):
        raise ValueError("Wrong value for type argument")
    if type == "global" and not kwargs.get("tax_categ"):
        raise ValueError("A global allowance charge must have a tax_categ named arg")
    elif type == "line" and "tax_categ" in kwargs:
        raise ValueError(
            "A line-level allowance charge must not have a tax_categ named arg"
        )
    if indicator not in ("false", "true"):
        raise ValueError("Wrong value for indicator argument")
    return CAC.AllowanceCharge(
        CBC.ChargeIndicator(indicator),
        *[
            CBC.AllowanceChargeReasonCode(kwargs["reason_code"])
            for _ in [1]
            if kwargs.get("reason_code")
        ],
        *[
            CBC.AllowanceChargeReason(kwargs["reason"])
            for _ in [1]
            if kwargs.get("reason")
        ],
        *[
            CBC.MultiplierFactorNumeric(kwargs["percent"])
            for _ in [1]
            if kwargs.get("percent")
        ],
        CBC.Amount(kwargs["amount"], currencyID=kwargs["currency_code"]),
        *[
            CBC.BaseAmount(kwargs["base_amount"], currencyID=kwargs["currency_code"])
            for _ in [1]
            if kwargs.get("base_amount")
        ],
        *[
            CAC.TaxCategory(
                CBC.ID(kwargs["tax_categ"]),
                *[
                    CBC.Percent(kwargs["tax_rate"])
                    for _ in [1]
                    if kwargs.get("tax_rate")
                ],
                CAC.TaxScheme(CBC.ID("VAT")),
            )
            for _ in [1]
            if type == "global"
        ],
    )


def _ubl_generate_single_invoice_line(namespaces, line_dict, invoice_currency):
    if not isinstance(line_dict, dict):
        raise ValueError("BG-25 must be a list of dicts")
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    # BT-127 is 0..1 in EN16931 but 0..n in extended
    # so we accept it both as a string and a list
    if line_dict.get("BT-127") and not isinstance("BT-127", list):
        line_dict["BT-127"] = [line_dict["BT-127"]]
    return CAC.InvoiceLine(
        CBC.ID(line_dict["BT-126"]),
        *[CBC.Note(note) for note in (line_dict.get("BT-127") or [])],
        CBC.InvoicedQuantity(line_dict["BT-129"], unitCode=line_dict["BT-130"]),
        CBC.LineExtensionAmount(line_dict["BT-131"], currencyID=invoice_currency),
        *[
            CBC.AccountingCost(line_dict["BT-133"])
            for _ in [1]
            if line_dict.get("BT-133")
        ],
        *[
            CAC.InvoicePeriod(
                *[
                    CBC.StartDate(_ubl_date_to_string(line_dict["BT-134"]))
                    for _ in [1]
                    if line_dict.get("BT-134")
                ],
                *[
                    CBC.EndDate(_ubl_date_to_string(line_dict["BT-135"]))
                    for _ in [1]
                    if line_dict.get("BT-135")
                ],
            )
            for _ in [1]
            if line_dict.get("BT-134") or line_dict.get("BT-135")
        ],
        *[
            CAC.OrderLineReference(CBC.LineID(line_dict["BT-132"]))
            for _ in [1]
            if line_dict.get("BT-132")
        ],
        *[
            CAC.DocumentReference(
                CBC.ID(
                    value,
                    {key: val for key, val in [("schemeID", schemeid)] if schemeid},
                ),
                CBC.DocumentTypeCode("130"),
            )
            for schemeid, value in (line_dict.get("BT-128-00") or {}).items()
        ],
        *[
            _ubl_generate_single_allowance_charge(
                namespaces,
                "line",
                "false",
                currency_code=invoice_currency,
                amount=charge["BT-136"],
                reason_code=charge.get("BT-140"),
                reason=charge.get("BT-139"),
                percent=charge.get("BT-138"),
                base_amount=charge.get("BT-137"),
            )
            for charge in (line_dict.get("BG-27") or [])
        ],
        *[
            _ubl_generate_single_allowance_charge(
                namespaces,
                "line",
                "true",
                currency_code=invoice_currency,
                amount=charge["BT-141"],
                reason_code=charge.get("BT-145"),
                reason=charge.get("BT-144"),
                percent=charge.get("BT-143"),
                base_amount=charge.get("BT-142"),
            )
            for charge in (line_dict.get("BG-28") or [])
        ],
        CAC.Item(
            *[
                CBC.Description(line_dict["BT-154"])
                for _ in [1]
                if line_dict.get("BT-154")
            ],
            CBC.Name(line_dict["BT-153"]),
            *[
                CAC.BuyersItemIdentification(CBC.ID(line_dict["BT-156"]))
                for _ in [1]
                if line_dict.get("BT-156")
            ],
            *[
                CAC.SellersItemIdentification(CBC.ID(line_dict["BT-155"]))
                for _ in [1]
                if line_dict.get("BT-155")
            ],
            *[
                CAC.StandardItemIdentification(
                    CBC.ID(line_dict["BT-157"], schemeID=line_dict["BT-157-1"])
                )
                for _ in [1]
                if line_dict.get("BT-157") and line_dict.get("BT-157-1")
            ],
            *[
                CAC.OriginCountry(CBC.IdentificationCode(line_dict["BT-159"]))
                for _ in [1]
                if line_dict.get("BT-159")
            ],
            *[
                CAC.CommodityClassification(
                    CBC.ItemClassificationCode(
                        value,
                        {
                            key: val
                            for key, val in [
                                ("listID", listID),
                                ("listVersionID", listVersionID),
                            ]
                            if val
                        },
                    )
                )
                for (listID, listVersionID), value in (
                    line_dict.get("BT-158-00") or {}
                ).items()
            ],
            CAC.ClassifiedTaxCategory(
                CBC.ID(line_dict["BT-151"]),
                *[
                    CBC.Percent(line_dict["BT-152"])
                    for _ in [1]
                    if line_dict.get("BT-152")
                ],
                CAC.TaxScheme(CBC.ID("VAT")),
            ),
            *[
                CAC.AdditionalItemProperty(
                    CBC.Name(attrib),
                    CBC.Value(value),
                )
                for attrib, value in (line_dict.get("BG-32") or {}).items()
            ],
        ),  # close Item
        CAC.Price(
            CBC.PriceAmount(line_dict["BT-146"], currencyID=invoice_currency),
            *[
                CBC.BaseQuantity(line_dict["BT-149"], unitCode=line_dict["BT-150"])
                for _ in [1]
                if line_dict.get("BT-149") and line_dict.get("BT-150")
            ],
            *[
                CAC.AllowanceCharge(
                    CBC.ChargeIndicator("false"),
                    CBC.Amount(line_dict["BT-147"], currencyID=invoice_currency),
                    *[
                        CBC.BaseAmount(line_dict["BT-148"], currencyID=invoice_currency)
                        for _ in [1]
                        if line_dict.get("BT-148")
                    ],
                )
                for _ in [1]
                if line_dict.get("BT-147")
            ],
        ),
    )


def generate_ubl_xml(
    data_dict, level="autodetect", check_xsd=True, check_schematron="base"
):
    if not isinstance(data_dict, dict):
        raise ValueError("data_dict must be a dict")
    if level == "autodetect":
        if not data_dict.get("BT-24"):
            raise ValueError("level='autodetect' requires a 'BT-24' key in data_dict'")
        for level_option, bt_24 in LEVEL2BT_24.items():
            if level in ("en16931", "extended-ctc-fr") and bt_24 == data_dict["BT-24"]:
                level = level_option
        if level == "autodetect":
            raise ValueError(
                f"Autodetection of level failed because the value of "
                f"data_dict['BT-24'] (f{data_dict['BT-24']}) is invalid"
            )
    elif level in ("en16931", "extended-ctc-fr"):
        bt_24 = LEVEL2BT_24[level]
        if data_dict.get("BT-24") and data_dict["BT-24"] != bt_24:
            logger.warning(
                f"Overwriting 'BT-24' in data_dict for level '{level}': "
                f"initial value '{data_dict['BT-24']}' -> new value '{bt_24}'"
            )
        data_dict["BT-24"] = bt_24
    else:
        raise ValueError(
            "level arg has 3 possible values for UBL: "
            "'en16931', 'extended-ctc-fr' and 'autodetect'"
        )

    _check_data_dict(data_dict, "ubl-2.1", level=level)

    if data_dict.get("BT-90"):
        if data_dict.get("BT-59"):  # if PayeeParty
            if not data_dict.get("BT-60"):
                data_dict["BT-60"] = {"SEPA": data_dict["BT-90"]}
            else:
                data_dict["BT-60"]["SEPA"] = data_dict["BT-90"]
        else:  # add to seller block
            if not data_dict.get("BT-29"):
                data_dict["BT-29"] = {"SEPA": data_dict["BT-90"]}
            else:
                data_dict["BT-29"]["SEPA"] = data_dict["BT-90"]

    UBL_NAMESPACES = {
        None: "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
        "cac": "urn:oasis:names:specification:ubl:schema:xsd:"
        "CommonAggregateComponents-2",
        "cbc": "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "ccts": "urn:un:unece:uncefact:documentation:2",
        "qdt": "urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2",
        "udt": "urn:oasis:names:specification:ubl:schema:xsd:UnqualifiedDataTypes-2",
    }

    CAC = objectify.ElementMaker(
        namespace=UBL_NAMESPACES["cac"], nsmap=UBL_NAMESPACES, annotate=False
    )
    CBC = objectify.ElementMaker(
        namespace=UBL_NAMESPACES["cbc"], nsmap=UBL_NAMESPACES, annotate=False
    )
    DEFAULT = objectify.ElementMaker(
        namespace=UBL_NAMESPACES[None], nsmap=UBL_NAMESPACES, annotate=False
    )
    namespaces = {
        "cac": CAC,
        "cbc": CBC,
    }

    xml_root = DEFAULT.Invoice(
        CBC.UBLVersionID("2.1"),
        CBC.CustomizationID(data_dict["BT-24"]),
        *[CBC.ProfileID(data_dict["BT-23"]) for _ in [1] if data_dict.get("BT-23")],
        CBC.ID(data_dict["BT-1"]),
        CBC.IssueDate(_ubl_date_to_string(data_dict["BT-2"])),
        *[
            CBC.DueDate(_ubl_date_to_string(data_dict["BT-9"]))
            for _ in [1]
            if data_dict.get("BT-9")
        ],
        CBC.InvoiceTypeCode(data_dict["BT-3"]),
        *[
            CBC.Note(
                note_dict.get("BT-21")
                and f"#{note_dict['BT-21']}#{note_dict['BT-22']}"
                or note_dict["BT-22"]
            )
            for note_dict in (data_dict.get("BG-1") or [])
        ],
        *[
            CBC.TaxPointDate(_ubl_date_to_string(data_dict["BT-7"]))
            for _ in [1]
            if data_dict.get("BT-7")
        ],  # not used in France
        CBC.DocumentCurrencyCode(data_dict["BT-5"]),
        *[CBC.TaxCurrencyCode(data_dict["BT-6"]) for _ in [1] if data_dict.get("BT-6")],
        *[
            CBC.AccountingCost(data_dict["BT-19"])
            for _ in [1]
            if data_dict.get("BT-19")
        ],
        *[
            CBC.BuyerReference(data_dict["BT-10"])
            for _ in [1]
            if data_dict.get("BT-10")
        ],
        *[
            CAC.InvoicePeriod(
                *[
                    CBC.StartDate(_ubl_date_to_string(data_dict["BT-73"]))
                    for _ in [1]
                    if data_dict.get("BT-73")
                ],
                *[
                    CBC.EndDate(_ubl_date_to_string(data_dict["BT-74"]))
                    for _ in [1]
                    if data_dict.get("BT-74")
                ],
                *[
                    CBC.DescriptionCode(data_dict["BT-8"])
                    for _ in [1]
                    if data_dict.get("BT-8")
                ],
            )
            for _ in [1]
            if data_dict.get("BT-73") or data_dict.get("BT-74") or data_dict.get("BT-8")
        ],
        *[
            CAC.OrderReference(
                *[CBC.ID(data_dict["BT-13"]) for _ in [1] if data_dict.get("BT-13")],
                *[
                    CBC.SalesOrderID(data_dict["BT-14"])
                    for _ in [1]
                    if data_dict.get("BT-14")
                ],
            )
            for _ in [1]
            if data_dict.get("BT-13") or data_dict.get("BT-14")
        ],
        *[
            CAC.BillingReference(
                CAC.InvoiceDocumentReference(
                    CBC.ID(previnv["BT-25"]),
                    *[
                        CBC.IssueDate(_ubl_date_to_string(previnv["BT-26"]))
                        for _ in [1]
                        if previnv.get("BT-26")
                    ],
                )
            )
            for previnv in (data_dict.get("BG-3") or [])
        ],
        *[
            CAC.DespatchDocumentReference(CBC.ID(data_dict["BT-16"]))
            for _ in [1]
            if data_dict.get("BT-16")
        ],
        *[
            CAC.ReceiptDocumentReference(CBC.ID(data_dict["BT-15"]))
            for _ in [1]
            if data_dict.get("BT-15")
        ],
        *[
            CAC.OriginatorDocumentReference(CBC.ID(data_dict["BT-17"]))
            for _ in [1]
            if data_dict.get("BT-17")
        ],
        *[
            CAC.ContractDocumentReference(CBC.ID(data_dict["BT-12"]))
            for _ in [1]
            if data_dict.get("BT-12")
        ],
        *_ubl_generate_additional_doc_ref(data_dict, namespaces),
        *[
            CAC.ProjectReference(CBC.ID(data_dict["BT-11"]))
            for _ in [1]
            if data_dict.get("BT-11")
        ],
        # SELLER  BG-4
        CAC.AccountingSupplierParty(
            _ubl_generate_party(
                "Party",
                namespaces,
                identifiers=data_dict.get("BT-29"),
                name=data_dict["BT-27"],
                legal_form=data_dict.get("BT-33"),
                legal_org_id=data_dict.get("BT-30"),
                legal_org_schemeid=data_dict.get("BT-30-1"),
                biz_name=data_dict.get("BT-28"),
                contact_name=data_dict.get("BT-41"),
                contact_phone=data_dict.get("BT-42"),
                contact_email=data_dict.get("BT-43"),
                country_code=data_dict["BT-40"],
                country_subdivision_name=data_dict.get("BT-39"),
                postcode=data_dict.get("BT-38"),
                city=data_dict.get("BT-37"),
                addr_line1=data_dict.get("BT-35"),
                addr_line2=data_dict.get("BT-36"),
                addr_line3=data_dict.get("BT-162"),
                universal_comm_id=data_dict.get("BT-34"),
                universal_comm_schemeid=data_dict.get("BT-34-1"),
                tax_id=data_dict.get("BT-31"),
                local_tax_id=data_dict.get("BT-32"),
            ),
        ),
        # BUYER  BG-7
        CAC.AccountingCustomerParty(
            _ubl_generate_party(
                "Party",
                namespaces,
                identifiers=data_dict.get("BT-46"),
                name=data_dict["BT-44"],
                legal_org_id=data_dict.get("BT-47"),
                legal_org_schemeid=data_dict.get("BT-47-1"),
                biz_name=data_dict.get("BT-45"),
                contact_name=data_dict.get("BT-56"),
                contact_phone=data_dict.get("BT-57"),
                contact_email=data_dict.get("BT-58"),
                country_code=data_dict["BT-55"],
                country_subdivision_name=data_dict.get("BT-54"),
                postcode=data_dict.get("BT-53"),
                city=data_dict.get("BT-52"),
                addr_line1=data_dict.get("BT-50"),
                addr_line2=data_dict.get("BT-51"),
                addr_line3=data_dict.get("BT-163"),
                universal_comm_id=data_dict.get("BT-49"),
                universal_comm_schemeid=data_dict.get("BT-49-1"),
                tax_id=data_dict.get("BT-48"),
            ),
        ),
        # Payee  BG-10
        _ubl_generate_party(
            "PayeeParty",
            namespaces,
            identifiers=data_dict.get("BT-60"),
            name=data_dict.get("BT-59"),
            role_code=data_dict.get("EXT-FR-FE-26"),
            legal_org_id=data_dict.get("BT-61"),
            legal_org_schemeid=data_dict.get("BT-61-1"),
            contact_name=data_dict.get("EXT-FR-FE-40"),
            contact_phone=data_dict.get("EXT-FR-FE-41"),
            contact_email=data_dict.get("EXT-FR-FE-42"),
            country_code=data_dict.get("EXT-FR-FE-38"),
            country_subdivision_name=data_dict.get("EXT-FR-FE-37"),
            postcode=data_dict.get("EXT-FR-FE-36"),
            city=data_dict.get("EXT-FR-FE-35"),
            addr_line1=data_dict.get("EXT-FR-FE-32"),
            addr_line2=data_dict.get("EXT-FR-FE-33"),
            addr_line3=data_dict.get("EXT-FR-FE-34"),
            universal_comm_id=data_dict.get("EXT-FR-FE-29"),
            universal_comm_schemeid=data_dict.get("EXT-FR-FE-30"),
            tax_id=data_dict.get("EXT-FR-FE-27"),
        ),
        # Seller Tax Representative  BG-11
        _ubl_generate_party(
            "TaxRepresentativeParty",
            namespaces,
            biz_name=data_dict.get("BT-62"),
            country_code=data_dict.get("BT-69"),
            country_subdivision_name=data_dict.get("BT-68"),
            postcode=data_dict.get("BT-67"),
            city=data_dict.get("BT-66"),
            addr_line1=data_dict.get("BT-64"),
            addr_line2=data_dict.get("BT-65"),
            addr_line3=data_dict.get("BT-164"),
            tax_id=data_dict.get("BT-63"),
        ),
        *[
            CAC.Delivery(
                *[
                    CBC.ActualDeliveryDate(_ubl_date_to_string(data_dict["BT-72"]))
                    for _ in [1]
                    if data_dict.get("BT-72")
                ],
                _ubl_generate_location(
                    "DeliveryLocation",
                    namespaces,
                    identifiers=data_dict.get("BT-71"),
                    country_code=data_dict.get("BT-80"),
                    country_subdivision_name=data_dict.get("BT-79"),
                    postcode=data_dict.get("BT-78"),
                    city=data_dict.get("BT-77"),
                    addr_line1=data_dict.get("BT-75"),
                    addr_line2=data_dict.get("BT-76"),
                    addr_line3=data_dict.get("BT-165"),
                ),
                _ubl_generate_party(
                    "DeliveryParty", namespaces, biz_name=data_dict.get("BT-70")
                ),
            )
            for _ in [1]
            if data_dict.get("BT-72")
            or data_dict.get("BT-70")
            or data_dict.get("BT-80")
            or data_dict.get("BT-71")
        ],
        *[
            CAC.PaymentMeans(
                *[
                    CBC.PaymentMeansCode(
                        data_dict["BT-81"],
                        {
                            key: val
                            for key, val in [("name", data_dict.get("BT-82"))]
                            if val
                        },
                    )
                    for _ in [1]
                ],
                *[
                    CBC.PaymentID(data_dict["BT-83"])
                    for _ in [1]
                    if data_dict.get("BT-83")
                ],
                *[
                    CAC.CardAccount(
                        CBC.PrimaryAccountNumberID(data_dict["BT-87"]),
                        CBC.NetworkID(data_dict["BT-87-1"]),
                        *[
                            CBC.HolderName(data_dict["BT-88"])
                            for _ in [1]
                            if data_dict.get("BT-88")
                        ],
                    )
                    for _ in [1]
                    if data_dict.get("BT-87") and data_dict.get("BT-87-1")
                ],
                *[
                    CAC.PayeeFinancialAccount(
                        CBC.ID(data_dict["BT-84"]),
                        *[
                            CBC.Name(data_dict["BT-85"])
                            for _ in [1]
                            if data_dict.get("BT-85")
                        ],
                        *[
                            CAC.FinancialInstitutionBranch(CBC.ID(data_dict["BT-86"]))
                            for _ in [1]
                            if data_dict.get("BT-86")
                        ],
                    )
                    for _ in [1]
                    if data_dict.get("BT-84")
                ],
                *[
                    CAC.PaymentMandate(
                        *[
                            CBC.ID(data_dict["BT-89"])
                            for _ in [1]
                            if data_dict.get("BT-89")
                        ],
                        CAC.PayerFinancialAccount(CBC.ID(data_dict["BT-91"])),
                    )
                    for _ in [1]
                    if data_dict.get("BT-91")
                ],
            )
            for _ in [1]
            if data_dict.get("BT-81")
        ],
        *[
            CAC.PaymentTerms(CBC.Note(data_dict["BT-20"]))
            for _ in [1]
            if data_dict.get("BT-20")
        ],
        *[
            _ubl_generate_single_allowance_charge(
                namespaces,
                "global",
                "false",
                currency_code=data_dict["BT-5"],
                amount=charge["BT-92"],
                reason_code=charge.get("BT-98"),
                reason=charge.get("BT-97"),
                percent=charge.get("BT-94"),
                base_amount=charge.get("BT-93"),
                tax_categ=charge["BT-95"],
                tax_rate=charge.get("BT-96"),
            )
            for charge in (data_dict.get("BG-20") or [])
        ],
        *[
            _ubl_generate_single_allowance_charge(
                namespaces,
                "global",
                "true",
                currency_code=data_dict["BT-5"],
                amount=charge["BT-99"],
                reason_code=charge.get("BT-105"),
                reason=charge.get("BT-104"),
                percent=charge.get("BT-101"),
                base_amount=charge.get("BT-100"),
                tax_categ=charge["BT-102"],
                tax_rate=charge.get("BT-103"),
            )
            for charge in (data_dict.get("BG-21") or [])
        ],
        *[
            CAC.TaxTotal(
                CBC.TaxAmount(data_dict["BT-110"], currencyID=data_dict["BT-110-1"])
            )
            for _ in [1]
            if data_dict.get("BT-110") and data_dict.get("BT-110-1")
        ],
        CAC.TaxTotal(
            CBC.TaxAmount(data_dict["BT-111"], currencyID=data_dict["BT-111-1"]),
            *[
                CAC.TaxSubtotal(
                    CBC.TaxableAmount(
                        tax_dict["BT-116"], currencyID=tax_dict["BT-116-1"]
                    ),  # TODO BT-5 or BT-6
                    CBC.TaxAmount(
                        tax_dict["BT-117"], currencyID=tax_dict["BT-117-1"]
                    ),  # TODO BT-5 or BT-6
                    CAC.TaxCategory(
                        CBC.ID(tax_dict["BT-118"]),
                        *[
                            CBC.Percent(tax_dict["BT-119"])
                            for _ in [1]
                            if tax_dict.get("BT-119")
                        ],
                        *[
                            CBC.TaxExemptionReasonCode(tax_dict["BT-121"])
                            for _ in [1]
                            if tax_dict.get("BT-121")
                        ],
                        *[
                            CBC.TaxExemptionReason(tax_dict["BT-120"])
                            for _ in [1]
                            if tax_dict.get("BT-120")
                        ],
                        CAC.TaxScheme(CBC.ID("VAT")),
                    ),
                )
                for tax_dict in data_dict["BG-23"]
            ],
        ),
        CAC.LegalMonetaryTotal(
            CBC.LineExtensionAmount(data_dict["BT-106"], currencyID=data_dict["BT-5"]),
            CBC.TaxExclusiveAmount(data_dict["BT-109"], currencyID=data_dict["BT-5"]),
            CBC.TaxInclusiveAmount(data_dict["BT-112"], currencyID=data_dict["BT-5"]),
            *[
                CBC.AllowanceTotalAmount(
                    data_dict["BT-107"], currencyID=data_dict["BT-5"]
                )
                for _ in [1]
                if data_dict.get("BT-107")
            ],
            *[
                CBC.ChargeTotalAmount(data_dict["BT-108"], currencyID=data_dict["BT-5"])
                for _ in [1]
                if data_dict.get("BT-108")
            ],
            *[
                CBC.PrepaidAmount(data_dict["BT-113"], currencyID=data_dict["BT-5"])
                for _ in [1]
                if data_dict.get("BT-113")
            ],
            *[
                CBC.PayableRoundingAmount(data_dict["BT-114"], currencyID="EUR")
                for _ in [1]
                if data_dict.get("BT-114")
            ],
            CBC.PayableAmount(data_dict["BT-115"], currencyID=data_dict["BT-5"]),
        ),
        *[
            _ubl_generate_single_invoice_line(namespaces, iline, data_dict["BT-5"])
            for iline in (data_dict.get("BG-25") or [])
        ],
    )  # Close Invoice
    xml_bytes = etree.tostring(
        xml_root, pretty_print=True, xml_declaration=True, encoding="UTF-8"
    )
    if check_xsd:
        xml_check_xsd(xml_root, flavor="ubl-2.1")
    if check_schematron:
        xml_check_schematron(
            xml_bytes, flavor="ubl-2.1", level=level, check_option=check_schematron
        )
    return xml_bytes


def generate_xml(
    data_dict,
    flavor="factur-x",
    level="autodetect",
    check_xsd=True,
    check_schematron="base",
):
    if flavor not in ("factur-x", "facturx", "ubl-2.1"):
        raise ValueError("Wrong value for flavor argument")
    if flavor in ("ubl-2.1"):
        return generate_ubl_xml(
            data_dict,
            level=level,
            check_xsd=check_xsd,
            check_schematron=check_schematron,
        )
    else:
        return generate_cii_xml(
            data_dict,
            level=level,
            check_xsd=check_xsd,
            check_schematron=check_schematron,
        )
