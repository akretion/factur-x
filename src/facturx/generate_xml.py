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

import base64
import datetime
import importlib.metadata
import logging

from iso4217 import Currency
from lxml import etree, objectify
from stdnum.iban import is_valid as iban_is_valid

from .facturx import get_xml_namespaces, xml_check_schematron, xml_check_xsd

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
FLAVOR2LEVELS = {
    "ubl-2.1": ["en16931", "extended-ctc-fr"],
    "factur-x": list(LEVEL2BT_24.keys()),
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
CREDIT_NOTE_TYPE_CODES = (
    "81",
    "83",
    "261",
    "262",
    "296",
    "308",
    "381",
    "396",
    "420",
    "458",
    "502",
    "503",
    "532",
)


VERSION = importlib.metadata.version("factur-x")
logger = logging.getLogger("factur-x")

EN16931_CURRENCY_FIELDS = {
    "BT-5": {
        "label": "Invoice Currency Code",
        "required": True,
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode",
        "ubl_xpath": "/Invoice/cbc:DocumentCurrencyCode",
    },
    "BT-6": {
        "label": "VAT Accounting Currency Code",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode",
        "ubl_xpath": "/Invoice/cbc:TaxCurrencyCode",
    },
}

EN16931_CHARGE_GLOBAL_FIELDS = {
    "amount": {
        "label": "Allowance/Charge Amount",
        "format": "monetary_BT-5",
        "cii_xpath": "ram:ActualAmount",
        "ubl_xpath": "cbc:Amount",
    },
    "base_amount": {
        "label": "Allowance/Charge Base Amount",
        "format": "monetary_BT-5",
        "cii_xpath": "ram:BasisAmount",
        "ubl_xpath": "cbc:BaseAmount",
    },
    "rate": {
        "label": "Allowance/Charge Rate",
        "format": "percent",
        "cii_xpath": "ram:CalculationPercent",
        "ubl_xpath": "cbc:MultiplierFactorNumeric",
    },
    "reason": {
        "label": "Allowance/Charge Reason",
        "cii_xpath": "ram:Reason",
        "ubl_xpath": "cbc:AllowanceChargeReason",
    },
    "reason_code": {  # charge: UNTDID 7161 / allowance: UNTDID 5189
        "label": "Allowance/Charge Reason Code",
        "cii_xpath": "ram:ReasonCode[not(@listID)]",
        "ubl_xpath": "cbc:AllowanceChargeReasonCode[not(@listID)]",
    },
    "non_vat_tax_code": {  # warning: only difference with reason_code is listID
        # only for charges
        "label": "Allowance/Charge non-VAT Tax Code",
        "min_level": "extended",
        "cii_xpath": "ram:ReasonCode[@listID='5153']",
        "ubl_xpath": "cbc:AllowanceChargeReasonCode[@listID='5153']",
    },
    "vat_category_code": {
        "label": "Document Level Allowance/Charge VAT Category Code",
        "cii_xpath": "ram:CategoryTradeTax/ram:CategoryCode",
        "ubl_xpath": "cac:TaxCategory/cbc:ID",
    },
    "vat_rate": {
        "label": "Document Level Allowance/Charge VAT Rate",
        "format": "percent",
        "cii_xpath": "ram:CategoryTradeTax/ram:RateApplicablePercent",
        "ubl_xpath": "cac:TaxCategory/cbc:Percent",
    },
    "vat_exemption": {  # only for global
        "label": "Document Level Allowance/Charge VAT Exemption Reason",
        "min_level": "extended",
        "cii_xpath": "ram:CategoryTradeTax/ram:ExemptionReason",
        "ubl_xpath": "cac:TaxCategory/cbc:TaxExemptionReason",
    },
    "vat_exemption_code": {
        "label": "Document Level Allowance/Charge VAT Exemption Reason Code",
        "min_level": "extended",
        "cii_xpath": "ram:CategoryTradeTax/ram:ExemptionReasonCode",
        "ubl_xpath": "cac:TaxCategory/cbc:TaxExemptionReasonCode",
    },
}
EN16931_ALLOWANCE_GLOBAL_FIELDS = {
    key: value
    for key, value in EN16931_CHARGE_GLOBAL_FIELDS.items()
    if key != "non_vat_tax_code"
}
EN16931_CHARGE_LINE_FIELDS = {
    key: value
    for key, value in EN16931_CHARGE_GLOBAL_FIELDS.items()
    if not key.startswith("vat_")
}
EN16931_ALLOWANCE_LINE_FIELDS = {
    key: value
    for key, value in EN16931_ALLOWANCE_GLOBAL_FIELDS.items()
    if not key.startswith("vat_")
}

EN16931_FIELDS = {
    "BT-1": {
        "label": "Invoice Number",
        "required": True,
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:ID",
        "ubl_xpath": "/Invoice/cbc:ID",
    },
    "BT-2": {
        "label": "Invoice Issue Date",
        "required": True,
        "format": "date",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/"
        "ram:IssueDateTime/udt:DateTimeString",
        "ubl_xpath": "/Invoice/cbc:IssueDate",
    },
    "BT-3": {
        "label": "Invoice Type Code",
        "required": True,
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:TypeCode",
        "ubl_xpath": "/Invoice/cbc:InvoiceTypeCode",
        "ubl_creditnote_xpath": "/CreditNote/cbc:CreditNoteTypeCode",
    },
    "BT-7": {
        "label": "VAT Point Date",
        "format": "date",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:TaxPointDate/udt:DateString",
        # Warning: cii_xpath is in BG-23, so it will be a list if the invoice has
        # several different VAT taxes
        "ubl_xpath": "/Invoice/cbc:TaxPointDate",
    },
    "BT-8": {
        "label": "VAT Point Date Code",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax/ram:DueDateTypeCode",
        # Warning: cii_xpath is in BG-23, so it will be a list if the invoice has
        # several different VAT taxes
        "ubl_xpath": "/Invoice/cac:InvoicePeriod/cbc:DescriptionCode",
    },
    "BT-9": {
        "label": "Payment Due Date",
        "format": "date",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms/"
        "ram:DueDateDateTime/udt:DateTimeString",
        "ubl_xpath": "/Invoice/cbc:DueDate",
        "ubl_creditnote_xpath": "/CreditNote/cac:PaymentMeans/cbc:PaymentDueDate",
    },
    "BT-10": {
        "label": "Buyer Reference",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:BuyerReference",
        "ubl_xpath": "/Invoice/cbc:BuyerReference",
    },
    "BT-11": {
        "label": "Project Reference",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:SpecifiedProcuringProject/ram:ID",
        "ubl_xpath": "/Invoice/cac:ProjectReference/cbc:ID",
        "ubl_creditnote_xpath": "/CreditNote/"
        "cac:AdditionalDocumentReference[cbc:DocumentTypeCode='50']/cbc:ID",
    },
    "BT-11-0": {
        "label": "Project Name",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:SpecifiedProcuringProject/ram:Name",
        # Doesn't exist in UBL !
    },
    "BT-12": {
        "label": "Contract Reference",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:ContractReferencedDocument/"
        "ram:IssuerAssignedID",
        "ubl_xpath": "/Invoice/cac:ContractDocumentReference/cbc:ID",
    },
    "BT-13": {
        "label": "Purchase Order Reference",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument/"
        "ram:IssuerAssignedID",
        "ubl_xpath": "/Invoice/cac:OrderReference/cbc:ID",
    },
    "BT-14": {
        "label": "Sales Order Reference",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:SellerOrderReferencedDocument/"
        "ram:IssuerAssignedID",
        "ubl_xpath": "/Invoice/cac:OrderReference/cbc:SalesOrderID",
    },
    "BT-15": {
        "label": "Receiving Advice Reference",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeDelivery/ram:ReceivingAdviceReferencedDocument/"
        "ram:IssuerAssignedID",
        "ubl_xpath": "/Invoice/cac:ReceiptDocumentReference/cbc:ID",
    },
    "BT-16": {
        "label": "Despatch advice reference",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeDelivery/ram:DespatchAdviceReferencedDocument/"
        "ram:IssuerAssignedID",
        "ubl_xpath": "/Invoice/cac:DespatchDocumentReference/cbc:ID",
    },
    "BT-17": {  # I don't name the field BT-17-00 because there is no child fields
        "label": "Tender or Lot Reference",
        "min_level": "en16931",
        "format": "list",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction"
        "/ram:ApplicableHeaderTradeAgreement/"
        "ram:AdditionalReferencedDocument[ram:TypeCode='50']/ram:IssuerAssignedID",
        "ubl_xpath": "/Invoice/cac:OriginatorDocumentReference/cbc:ID",
        # In CII extended, it is 0..n, but in UBL extended it is 0..1 like in en16931
        # => when generating in UBL, only the first element of the list will be taken
    },
    "BT-18": {
        "min_level": "en16931",
        # BT-18 has the same format as BT-128: it uses schemeID in UBL and
        # ram:IssuerAssignedID + ram:ReferenceTypeCode in CII
        # Warning : 0..1 in en16931 0..n in extended
        "format": "schemeID_ReferenceTypeCode_dict",
        # key is from UNTDID 1153
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction"
        "/ram:ApplicableHeaderTradeAgreement/"
        "ram:AdditionalReferencedDocument[ram:TypeCode='130']",
        "ubl_xpath": "/Invoice/"
        "cac:AdditionalDocumentReference[cbc:DocumentTypeCode='130']/cbc:ID",
    },
    "BT-19": {
        "label": "Buyer Accounting Reference",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:ReceivableSpecifiedTradeAccountingAccount/ram:ID",
        "ubl_xpath": "/Invoice/cbc:AccountingCost",
    },
    "BT-20": {
        "label": "Payment Terms",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms/"
        "ram:Description",
        "ubl_xpath": "/Invoice/cac:PaymentTerms/cbc:Note",
    },
    "BT-23": {
        "label": "Business Process Type",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/"
        "ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID",
        "ubl_xpath": "/Invoice/cbc:ProfileID",
    },
    "BT-24": {
        "label": "Specification Identifier",
        "required": True,
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/"
        "ram:GuidelineSpecifiedDocumentContextParameter/ram:ID",
        "ubl_xpath": "/Invoice/cbc:CustomizationID",
    },
    "BT-72": {
        "label": "Actual Delivery Date",
        "format": "date",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeDelivery/ram:ActualDeliverySupplyChainEvent/"
        "ram:OccurrenceDateTime/udt:DateTimeString",
        "ubl_xpath": "/Invoice/cac:Delivery/cbc:ActualDeliveryDate",
    },
    "BT-73": {
        "label": "Invoicing Period Start Date",
        "format": "date",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod/"
        "ram:StartDateTime/udt:DateTimeString",
        "ubl_xpath": "/Invoice/cac:InvoicePeriod/cbc:StartDate",
    },
    "BT-74": {
        "label": "Invoicing Period End Date",
        "format": "date",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod/"
        "ram:EndDateTime/udt:DateTimeString",
        "ubl_xpath": "/Invoice/cac:InvoicePeriod/cbc:EndDate",
    },
    "BT-81": {
        "label": "Payment Means Type Code",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/"
        "ram:TypeCode",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cbc:PaymentMeansCode",
    },
    "BT-82": {
        "label": "Payment Means Label",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/"
        "ram:Information",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cbc:PaymentMeansCode/@name",
    },
    "BT-83": {
        "label": "Remittance Information",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:PaymentReference",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cbc:PaymentID",
    },
    "BT-84": {
        "label": "Payment Account Identifier",
        "cii_xpath": [  # BT-84 + BT-84-0
            "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
            "ram:ApplicableHeaderTradeSettlement/"
            "ram:SpecifiedTradeSettlementPaymentMeans/"
            "ram:PayeePartyCreditorFinancialAccount/ram:IBANID",
            "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
            "ram:ApplicableHeaderTradeSettlement/"
            "ram:SpecifiedTradeSettlementPaymentMeans/"
            "ram:PayeePartyCreditorFinancialAccount/ram:ProprietaryID",
        ],
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID",
    },
    "BT-85": {
        "label": "Payment Account Name",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/"
        "ram:PayeePartyCreditorFinancialAccount/ram:AccountName",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:Name",
    },
    "BT-86": {
        "label": "Payment Service Provider Identifier",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/"
        "ram:PayeeSpecifiedCreditorFinancialInstitution/ram:BICID",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cac:PayeeFinancialAccount/"
        "cac:FinancialInstitutionBranch/cbc:ID",
    },
    "BT-87": {
        "label": "Payment Card Primary Account Number",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/"
        "ram:ApplicableTradeSettlementFinancialCard/ram:ID",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cac:CardAccount/"
        "cbc:PrimaryAccountNumberID",
    },
    "BT-88": {
        "label": "Payment Card Holder Name",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/"
        "ram:ApplicableTradeSettlementFinancialCard/ram:CardholderName",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cac:CardAccount/cbc:HolderName",
    },
    "BT-89": {
        "label": "Mandate Reference Identifier",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradePaymentTerms/"
        "ram:DirectDebitMandateID",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cac:PaymentMandate/cbc:ID",
    },
    "BT-90": {
        "label": "SEPA Creditor Identifier",  # ICS
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:CreditorReferenceID",
        "ubl_xpath": [
            "/Invoice/cac:PayeeParty/cac:PartyIdentification/cbc:ID[@schemeID='SEPA']",
            "/Invoice/cac:AccountingSupplierParty/cac:Party/"
            "cac:PartyIdentification/cbc:ID[@schemeID='SEPA']",
        ],
    },
    "BT-91": {
        "label": "Debited Account Identifier",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/"
        "ram:PayerPartyDebtorFinancialAccount/ram:IBANID",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cac:PaymentMandate/"
        "cac:PayerFinancialAccount/cbc:ID",
    },
    "BT-106": {
        "label": "Sum of Invoice Line Net Amount",
        "format": "monetary_BT-5",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:LineTotalAmount",
        "ubl_xpath": "/Invoice/cac:LegalMonetaryTotal/cbc:LineExtensionAmount",
    },
    "BT-107": {
        "label": "Sum of Allowances on Document Level",
        "format": "monetary_BT-5",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:AllowanceTotalAmount",
        "ubl_xpath": "/Invoice/cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount",
    },
    "BT-108": {
        "label": "Sum of Charges on Document Level",
        "format": "monetary_BT-5",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:ChargeTotalAmount",
        "ubl_xpath": "/Invoice/cac:LegalMonetaryTotal/cbc:ChargeTotalAmount",
    },
    "BT-109": {
        "label": "Invoice Total Amount without VAT",
        "required": True,
        "format": "monetary_BT-5",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount",
        "ubl_xpath": "/Invoice/cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount",
    },
    "BT-110": {
        "label": "Invoice Total VAT Amount",
        "format": "monetary_BT-5",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/"
        "ram:TaxTotalAmount[@currencyID='%(BT-5)s']",
        "ubl_xpath": "/Invoice/cac:TaxTotal/cbc:TaxAmount[@currencyID='%(BT-5)s']",
    },
    "BT-111": {
        "label": "Invoice Total VAT amount in Accounting Currency",
        "format": "monetary_BT-6",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/"
        "ram:TaxTotalAmount[@currencyID='%(BT-6)s']",
        "ubl_xpath": "/Invoice/cac:TaxTotal/cbc:TaxAmount[@currencyID='%(BT-6)s']",
    },
    "BT-112": {
        "label": "Invoice Total Amount with VAT",
        "required": True,
        "format": "monetary_BT-5",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount",
        "ubl_xpath": "/Invoice/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount",
    },
    "BT-113": {
        "label": "Paid Amount",
        "format": "monetary_BT-5",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TotalPrepaidAmount",
        "ubl_xpath": "/Invoice/cac:LegalMonetaryTotal/cbc:PrepaidAmount",
    },
    "BT-114": {
        "label": "Rounding Amount",
        "format": "monetary_BT-5",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:RoundingAmount",
        "ubl_xpath": "/Invoice/cac:LegalMonetaryTotal/cbc:PayableRoundingAmount",
    },
    "BT-115": {
        "label": "Amount due for payment",
        "required": True,
        "format": "monetary_BT-5",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:DuePayableAmount",
        "ubl_xpath": "/Invoice/cac:LegalMonetaryTotal/cbc:PayableAmount",
    },
    "EXT-FR-FE-185": {
        "label": "Incoterms Code",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:ApplicableTradeDeliveryTerms/"
        "ram:DeliveryTypeCode",
        "ubl_xpath": "/Invoice/cac:DeliveryTerms/cbc:ID",
    },
    "EXT-FR-FE-186": {
        "label": "Incoterms Location Name",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:ApplicableTradeDeliveryTerms/"
        "ram:RelevantTradeLocation/ram:Name",
        "ubl_xpath": "/Invoice/cac:DeliveryTerms/cac:DeliveryLocation/cbc:Name",
    },
    "BG-1": {
        "label": "Invoice Notes",
        "format": "list",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/"
        "ram:IncludedNote",
        "ubl_xpath": "/Invoice/cbc:Note",
        "fields": {
            "BT-21": {
                "label": "Invoice Note Subject Code",
                "cii_xpath": "ram:SubjectCode",
                "ubl_xpath": "UBL_NOTE_SUBJECT",  # special treatment
            },
            "BT-22": {
                "label": "Invoice Note",
                "cii_xpath": "ram:Content",
                "ubl_xpath": "UBL_NOTE_CONTENT",  # special treatment
            },
        },
    },
    "BG-3": {
        "label": "Preceding Invoice Reference",
        "format": "list",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:InvoiceReferencedDocument",
        "ubl_xpath": "/Invoice/cac:BillingReference",
        "fields": {
            "BT-25": {
                "label": "Preceding Invoice Reference",
                "cii_xpath": "ram:IssuerAssignedID",
                "ubl_xpath": "cac:InvoiceDocumentReference/cbc:ID",
            },
            "BT-26": {
                "label": "Preceding Invoice Issue Date",
                "format": "date",
                "cii_xpath": "ram:FormattedIssueDateTime/qdt:DateTimeString",
                "ubl_xpath": "cac:InvoiceDocumentReference/cbc:IssueDate",
            },
            "EXT-FR-FE-02": {
                "label": "Preceding Invoice Type Code",
                "cii_xpath": "ram:TypeCode",
                "ubl_xpath": "cac:InvoiceDocumentReference/cbc:DocumentTypeCode",
            },
        },
    },
    "BG-4": {
        "label": "Seller",
        "format": "party_dict",
        "party_dict_blacklist": ["role_code"],
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty",
        "ubl_xpath": "/Invoice/cac:AccountingSupplierParty/cac:Party",
    },
    "BG-7": {
        "label": "Buyer",
        "format": "party_dict",
        "party_dict_blacklist": ["legal_info", "role_code", "tax_identifier"],
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty",
        "ubl_xpath": "/Invoice/cac:AccountingCustomerParty/cac:Party",
    },
    "BG-10": {
        "label": "Payee",
        "format": "party_dict",
        "party_dict_whitelist": [
            "name",
            "identifiers",
            "legal_identifier",
            "legal_identifier_schemeid",
        ],
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty",
        "ubl_xpath": "/Invoice/cac:PayeeParty",
    },
    "BG-11": {
        "label": "Seller Tax Representative",
        "party_dict_whitelist": ["name", "address", "vat_identifier"],
        "format": "party_dict",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:SellerTaxRepresentativeTradeParty",
        "ubl_xpath": "/Invoice/cac:TaxRepresentativeParty",
    },
    "BG-13": {
        "label": "Delivery Information",
        "format": "party_dict",
        "party_dict_whitelist": ["identifiers", "name", "address"],
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty",
        "ubl_xpath": "/Invoice/cac:Delivery",
    },
    # Extended party blocks
    "EXT-FR-FE-BG-01": {
        "label": "Buyer Agent",
        "format": "party_dict",
        "party_dict_blacklist": ["legal_info", "tax_identifier"],
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:BuyerAgentTradeParty",
        "ubl_xpath": "/Invoice/cac:AccountingCustomerParty/cac:Party/cac:AgentParty",
    },
    "EXT-FR-FE-BG-02": {
        "label": "Payer",
        "format": "party_dict",
        "party_dict_blacklist": ["legal_info", "tax_identifier"],
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:PayerTradeParty",
        "ubl_xpath": "/Invoice/cac:PaymentMeans/cac:PaymentMandate/cac:PayerParty",
    },
    "EXT-FR-FE-BG-03": {
        "label": "Sales Agent",
        "format": "party_dict",
        "party_dict_blacklist": ["legal_info", "tax_identifier"],
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeAgreement/ram:SalesAgentTradeParty",
        "ubl_xpath": "/Invoice/cac:AccountingSupplierParty/cac:Party/cac:AgentParty",
    },
    "EXT-FR-FE-BG-04": {
        "label": "Invoicee Trade Party",
        "format": "party_dict",
        "party_dict_blacklist": ["legal_info", "tax_identifier"],
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:InvoiceeTradeParty",
        "ubl_xpath": "/Invoice/cac:AccountingCustomerParty/cac:Party/"
        "cac:ServiceProviderParty/cac:Party",
    },
    "EXT-FR-FE-BG-05": {
        "label": "Invoicer Trade Party",
        "format": "party_dict",
        "party_dict_blacklist": ["legal_info", "tax_identifier"],
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:InvoicerTradeParty",
        "ubl_xpath": "/Invoice/cac:AccountingSupplierParty/cac:Party/"
        "cac:ServiceProviderParty/cac:Party",
    },
    "BG-20": {
        "label": "Document Level Allowances",  # Remises au niveau doc
        "format": "list",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='false']",
        "ubl_xpath": "/Invoice/cac:AllowanceCharge[cbc:ChargeIndicator='false']",
        "fields": EN16931_ALLOWANCE_GLOBAL_FIELDS,
    },
    "BG-21": {
        "label": "Document Level Charges",  # Charges/frais au niveau doc
        "format": "list",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/"
        "ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']",
        "ubl_xpath": "/Invoice/cac:AllowanceCharge[cbc:ChargeIndicator='true']",
        "fields": EN16931_CHARGE_GLOBAL_FIELDS,
    },
    "BG-23": {
        "label": "VAT Breakdown",
        "format": "list",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax",
        "ubl_xpath": "/Invoice/cac:TaxTotal/cac:TaxSubtotal",
        "fields": {
            "BT-116": {
                "label": "VAT Taxable Amount",
                "format": "monetary_BT-5",
                "cii_xpath": "ram:BasisAmount",
                "ubl_xpath": "cbc:TaxableAmount",
            },
            "BT-117": {
                "label": "VAT Category Tax Amount",
                "format": "monetary_BT-5",
                "cii_xpath": "ram:CalculatedAmount",
                "ubl_xpath": "cbc:TaxAmount",
            },
            "BT-118": {
                "label": "VAT Category Code",
                "cii_xpath": "ram:CategoryCode",
                "ubl_xpath": "cac:TaxCategory/cbc:ID",
            },
            "BT-119": {
                "label": "VAT Rate",
                "format": "percent",
                "cii_xpath": "ram:RateApplicablePercent",
                "ubl_xpath": "cac:TaxCategory/cbc:Percent",
            },
            "BT-120": {
                "label": "VAT Exemption Reason Text",
                "cii_xpath": "ram:ExemptionReason",
                "ubl_xpath": "cac:TaxCategory/cbc:TaxExemptionReason",
            },
            "BT-121": {
                "label": "VAT Exemption Reason Code",
                "cii_xpath": "ram:ExemptionReasonCode",
                "ubl_xpath": "cac:TaxCategory/cbc:TaxExemptionReasonCode",
            },
        },
    },
    "BG-24": {
        "label": "Additional Supporting Documents",
        "format": "list",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction"
        "/ram:ApplicableHeaderTradeAgreement/"
        "ram:AdditionalReferencedDocument[ram:TypeCode='916']",
        "ubl_xpath": "/Invoice/"
        "cac:AdditionalDocumentReference[not(cbc:DocumentTypeCode)]",
        "fields": {
            "BT-122": {
                "label": "Supporting Document Reference",
                "cii_xpath": "ram:IssuerAssignedID",
                "ubl_xpath": "cbc:ID",
            },
            "BT-123": {
                "label": "Supporting Document Description",
                "cii_xpath": "ram:Name",
                "ubl_xpath": "cbc:DocumentDescription",
            },
            "BT-124": {
                "label": "External Document Location",
                "cii_xpath": "ram:URIID",
                "ubl_xpath": "cac:Attachment/cac:ExternalReference/cbc:URI",
            },
            "BT-125": {
                "label": "Attachment Document",  # NOT in base64 any more
                "format": "bytes",
                "cii_xpath": "ram:AttachmentBinaryObject",
                "ubl_xpath": "cac:Attachment/cbc:EmbeddedDocumentBinaryObject",
            },
            "BT-125-1": {
                "label": "Attachment Document MIME Code",
                "cii_xpath": "ram:AttachmentBinaryObject/@mimeCode",
                "ubl_xpath": "cac:Attachment/"
                "cbc:EmbeddedDocumentBinaryObject/@mimeCode",
            },
            "BT-125-2": {
                "label": "Attachment Document Filename",
                "cii_xpath": "ram:AttachmentBinaryObject/@filename",
                "ubl_xpath": "cac:Attachment/"
                "cbc:EmbeddedDocumentBinaryObject/@filename",
            },
        },
    },
    "BG-25": {
        "label": "Invoice Lines",
        "format": "list",
        "min_level": "en16931",
        "cii_xpath": "/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/"
        "ram:IncludedSupplyChainTradeLineItem",
        "ubl_xpath": "/Invoice/cac:InvoiceLine",
        "ubl_creditnote_xpath": "/CreditNote/cac:CreditNoteLine",
        "fields": {
            "BT-126": {
                "label": "Invoice Line Identifier",
                "required": True,
                "cii_xpath": "ram:AssociatedDocumentLineDocument/ram:LineID",
                "ubl_xpath": "cbc:ID",
            },
            "BT-127-00": {  # warning: in extended profile, it is a list ! (0..n)
                "label": "Invoice Line Notes",
                "format": "list",
                "cii_xpath": "ram:AssociatedDocumentLineDocument/ram:IncludedNote",
                "ubl_xpath": "cbc:Note",
                "fields": {
                    "EXT-FR-FE-183": {
                        "label": "Invoice Line Note Subject Code",
                        "cii_xpath": "ram:SubjectCode",
                        "ubl_xpath": "UBL_NOTE_SUBJECT",  # special treatment
                    },
                    "BT-127": {
                        "label": "Invoice Line Note",
                        "cii_xpath": "ram:Content",
                        "ubl_xpath": "UBL_NOTE_CONTENT",  # special treatment
                    },
                },
            },
            "BT-128": {
                "min_level": "en16931",
                # BT-128 has the same format as BT-18: it uses schemeID in UBL and
                # ram:IssuerAssignedID + ram:ReferenceTypeCode in CII
                # Warning : 0..1 in en16931 0..n in extended
                "format": "schemeID_ReferenceTypeCode_dict",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:AdditionalReferencedDocument[ram:TypeCode='130']",
                "ubl_xpath": "cac:DocumentReference[cbc:DocumentTypeCode='130']/cbc:ID",
            },
            "BT-129": {
                "label": "Invoiced Quantity",
                "format": "qty",
                "required": True,
                "cii_xpath": "ram:SpecifiedLineTradeDelivery/ram:BilledQuantity",
                "ubl_xpath": "cbc:InvoicedQuantity",
                "ubl_creditnote_xpath": "cbc:CreditedQuantity",
            },
            "BT-130": {
                "label": "Invoiced Quantity Unit of Measure",
                "required": True,
                "cii_xpath": "ram:SpecifiedLineTradeDelivery/"
                "ram:BilledQuantity/@unitCode",
                "ubl_xpath": "cbc:InvoicedQuantity/@unitCode",
                "ubl_creditnote_xpath": "cbc:CreditedQuantity/@unitCode",
            },
            "BT-131": {
                "label": "Invoice Line Net Amount",
                "format": "monetary_BT-5",
                "required": True,
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount",
                "ubl_xpath": "cbc:LineExtensionAmount",
            },
            "BT-132": {
                "label": "Referenced Purchase Order Line Reference",
                "cii_xpath": "ram:SpecifiedLineTradeAgreement/"
                "ram:BuyerOrderReferencedDocument/ram:LineID",
                "ubl_xpath": "cac:OrderLineReference/cbc:LineID",
            },
            "BT-133": {
                "label": "Invoice Line Buyer Accounting Reference",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:ReceivableSpecifiedTradeAccountingAccount/ram:ID",
                "ubl_xpath": "cbc:AccountingCost",
            },
            "BT-134": {
                "label": "Invoice Line Period Start Date",
                "format": "date",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString",
                "ubl_xpath": "cac:InvoicePeriod/cbc:StartDate",
            },
            "BT-135": {
                "label": "Invoice Line Period End Date",
                "format": "date",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString",
                "ubl_xpath": "cac:InvoicePeriod/cbc:EndDate",
            },
            "BT-146": {
                "label": "Invoice Line Item Net Price",
                "format": "price",
                "required": True,
                "cii_xpath": "ram:SpecifiedLineTradeAgreement/"
                "ram:NetPriceProductTradePrice/ram:ChargeAmount",
                "ubl_xpath": "cac:Price/cbc:PriceAmount",
            },
            "BT-147-00": {
                "label": "List of Item Price Discounts",
                "format": "list",
                "cii_xpath": "ram:SpecifiedLineTradeAgreement/"
                "ram:GrossPriceProductTradePrice/"
                "ram:AppliedTradeAllowanceCharge[ram:ChargeIndicator/"
                "udt:Indicator='false']",
                "ubl_xpath": "cac:Price/"
                "cac:AllowanceCharge[cbc:ChargeIndicator='false']",
                "fields": {
                    "BT-147": {
                        "label": "Item Price Discount",
                        "format": "price",
                        "cii_xpath": "ram:ActualAmount",
                        "ubl_xpath": "cbc:Amount",
                    },
                    "EXT-FR-FE-195": {
                        "label": "Item Price Discount Reason",
                        "cii_xpath": "ram:Reason",
                        "ubl_xpath": "cbc:AllowanceChargeReason",
                    },
                    "EXT-FR-FE-196": {  # from UNTDID 5189
                        "label": "Item Price Discount Reason Code",
                        "cii_xpath": "ram:ReasonCode",
                        "ubl_xpath": "cbc:AllowanceChargeReasonCode",
                    },
                },
                # UBL extended : 0..1 vs CII extended 0..n
            },
            "BT-148": {
                "label": "Invoice Line Item Gross Price",
                "format": "price",
                "cii_xpath": "ram:SpecifiedLineTradeAgreement/"
                "ram:GrossPriceProductTradePrice/ram:ChargeAmount",
                "ubl_xpath": "cac:Price/cac:AllowanceCharge/cbc:BaseAmount",
            },
            "BT-149": {
                "label": "Invoice Line Item Price Base Quantity",
                "format": "qty",
                "cii_xpath": "ram:SpecifiedLineTradeAgreement/"
                "ram:NetPriceProductTradePrice/ram:BasisQuantity",
                "ubl_xpath": "cac:Price/cbc:BaseQuantity",
            },
            # BT-150 = BT-150-1 = BT-130 (unitCode)
            "BT-151": {
                "label": "Invoice Line VAT Category Code",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:ApplicableTradeTax/ram:CategoryCode",
                "ubl_xpath": "cac:Item/cac:ClassifiedTaxCategory/cbc:ID",
            },
            "BT-152": {
                "label": "Invoice Line VAT Rate",
                "format": "percent",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:ApplicableTradeTax/ram:RateApplicablePercent",
                "ubl_xpath": "cac:Item/cac:ClassifiedTaxCategory/cbc:Percent",
            },
            "BT-153": {
                "label": "Invoice Line Item Name",
                "required": True,
                "cii_xpath": "ram:SpecifiedTradeProduct/ram:Name",
                "ubl_xpath": "cac:Item/cbc:Name",
            },
            "BT-154": {
                "label": "Invoice Line Item Description",
                "cii_xpath": "ram:SpecifiedTradeProduct/ram:Description",
                "ubl_xpath": "cac:Item/cbc:Description",
            },
            "BT-155": {
                "label": "Item Seller's Identifier",
                "cii_xpath": "ram:SpecifiedTradeProduct/ram:SellerAssignedID",
                "ubl_xpath": "cac:Item/cac:SellersItemIdentification/cbc:ID",
            },
            "BT-156": {
                "label": "Item Buyer's Identifier",
                "cii_xpath": "ram:SpecifiedTradeProduct/ram:BuyerAssignedID",
                "ubl_xpath": "cac:Item/cac:BuyersItemIdentification/cbc:ID",
            },
            # I don't use format=schemeID_dict for BT-157 because
            # it is 0..1 and not 0..n
            "BT-157": {
                "label": "Item Standard Identifier",
                "cii_xpath": "ram:SpecifiedTradeProduct/ram:GlobalID",
                "ubl_xpath": "cac:Item/cac:StandardItemIdentification/cbc:ID",
            },
            "BT-157-1": {
                "label": "Item Standard Identifier - Scheme ID",
                "cii_xpath": "ram:SpecifiedTradeProduct/ram:GlobalID/@schemeID",
                "ubl_xpath": "cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID",
            },
            "BT-158": {
                "label": "Item Classification",
                "format": "listID_listVersionID_dict",
                "cii_xpath": "ram:SpecifiedTradeProduct/"
                "ram:DesignatedProductClassification/ram:ClassCode",
                "ubl_xpath": "cac:Item/cac:CommodityClassification/"
                "cbc:ItemClassificationCode",
            },
            "BT-159": {
                "label": "Item Country of Origin",
                "cii_xpath": "ram:SpecifiedTradeProduct/ram:OriginTradeCountry/ram:ID",
                "ubl_xpath": "cac:Item/cac:OriginCountry/cbc:IdentificationCode",
            },
            "EXT-FR-FE-135": {
                "label": "Purchased Order Reference at Invoice Line",
                "cii_xpath": "ram:SpecifiedLineTradeAgreement/"
                "ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID",
                "ubl_xpath": "cac:OrderLineReference/cac:OrderReference/cbc:ID",
            },
            "EXT-FR-FE-136": {
                "label": "Preceding Invoice Reference at Invoice Line",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:InvoiceReferencedDocument/ram:IssuerAssignedID",
                "ubl_xpath": "cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID",
            },
            "EXT-FR-FE-137": {
                "label": "Preceding Invoice Type Code at Invoice Line",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:InvoiceReferencedDocument/ram:TypeCode",
                "ubl_xpath": "cac:BillingReference/cac:InvoiceDocumentReference/"
                "cbc:DocumentTypeCode",
            },
            "EXT-FR-FE-138": {
                "label": "Preceding Invoice Date at Invoice Line",
                "format": "date",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:InvoiceReferencedDocument/ram:FormattedIssueDateTime/"
                "qdt:DateTimeString",
                "ubl_xpath": "cac:BillingReference/cac:InvoiceDocumentReference/"
                "cbc:IssueDate",
            },
            "EXT-FR-FE-139": {
                "label": "Preceding Invoice Line Reference",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:InvoiceReferencedDocument/ram:LineID",
                "ubl_xpath": "cac:BillingReference/cac:BillingReferenceLine/cbc:ID",
            },
            "EXT-FR-FE-140": {
                "label": "Despatch Advice Reference at Invoice Line",
                "cii_xpath": "ram:SpecifiedLineTradeDelivery/"
                "ram:DespatchAdviceReferencedDocument/ram:IssuerAssignedID",
                "ubl_xpath": "cac:DespatchLineReference/cac:DocumentReference/cbc:ID",
            },
            "EXT-FR-FE-141": {
                "label": "Despatch Advice Line Reference",
                "cii_xpath": "ram:SpecifiedLineTradeDelivery/"
                "ram:DespatchAdviceReferencedDocument/ram:LineID",
                "ubl_xpath": "cac:DespatchLineReference/cbc:LineID",
            },
            "EXT-FR-FE-144": {
                "label": "Sale Order Reference at Invoice Line",
                "cii_xpath": "ram:SpecifiedLineTradeAgreement/"
                "ram:SellerOrderReferencedDocument/ram:IssuerAssignedID",
                "ubl_xpath": "cac:OrderLineReference/cac:OrderReference/"
                "cbc:SalesOrderID",
            },
            "EXT-FR-FE-145": {
                "label": "Sales Order Line Reference at Invoice Line",
                "cii_xpath": "ram:SpecifiedLineTradeAgreement/"
                "ram:SellerOrderReferencedDocument/ram:LineID",
                "ubl_xpath": "cac:OrderLineReference/cbc:SalesOrderLineID",
            },
            "BG-27": {
                "label": "Invoice Line Allowances",  # Remise de ligne
                "format": "list",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/"
                "udt:Indicator='false']",
                "ubl_xpath": "cac:AllowanceCharge[cbc:ChargeIndicator='false']",
                "fields": EN16931_ALLOWANCE_LINE_FIELDS,
            },
            "BG-28": {
                "label": "Invoice Line Charges",  # Charges/Frais de ligne
                "format": "list",
                "cii_xpath": "ram:SpecifiedLineTradeSettlement/"
                "ram:SpecifiedTradeAllowanceCharge[ram:ChargeIndicator/udt:Indicator='true']",
                "ubl_xpath": "cac:AllowanceCharge[cbc:ChargeIndicator='true']",
                "fields": EN16931_CHARGE_LINE_FIELDS,
            },
            "BG-32": {
                "label": "Invoice Line Item Attributes",
                "format": "list",
                "cii_xpath": "ram:SpecifiedTradeProduct/"
                "ram:ApplicableProductCharacteristic",
                "ubl_xpath": "cac:Item/cac:AdditionalItemProperty",
                "fields": {
                    "BT-160": {
                        "label": "Item Attribute Name",
                        "cii_xpath": "ram:Description",
                        "ubl_xpath": "cbc:Name",
                    },
                    "BT-161": {
                        "label": "Item Attribute Value",
                        "cii_xpath": "ram:Value",
                        "ubl_xpath": "cbc:Value",
                    },
                },
            },
            "EXT-FR-FE-BG-10": {
                "label": "Delivery Party at Invoice Line",
                "format": "party_dict",
                "party_dict_whitelist": ["identifiers", "name", "address"],
                "cii_xpath": "ram:SpecifiedLineTradeDelivery/ram:ShipToTradeParty",
                "ubl_xpath": "cac:Delivery",
            },
        },
    },
}

EN16931_FIELDS.update(EN16931_CURRENCY_FIELDS)

EN16931_ADDRESS_FIELDS = {
    "country_code": {
        "label": "Country ISO Code",
        "cii_xpath": "ram:PostalTradeAddress/ram:CountryID",
        "ubl_xpath": "cac:PostalAddress/cac:Country/cbc:IdentificationCode",
        "required": True,
    },
    "city": {
        "label": "City",
        "cii_xpath": "ram:PostalTradeAddress/ram:CityName",
        "ubl_xpath": "cac:PostalAddress/cbc:CityName",
    },
    "postcode": {
        "label": "Postal Code",
        "cii_xpath": "ram:PostalTradeAddress/ram:PostcodeCode",
        "ubl_xpath": "cac:PostalAddress/cbc:PostalZone",
    },
    "addr_l1": {
        "label": "Address Line 1",
        "cii_xpath": "ram:PostalTradeAddress/ram:LineOne",
        "ubl_xpath": "cac:PostalAddress/cbc:StreetName",
    },
    "addr_l2": {
        "label": "Address Line 2",
        "cii_xpath": "ram:PostalTradeAddress/ram:LineTwo",
        "ubl_xpath": "cac:PostalAddress/cbc:AdditionalStreetName",
    },
    "addr_l3": {
        "label": "Address Line 3",
        "min_level": "extended",
        "cii_xpath": "ram:PostalTradeAddress/ram:LineThree",
        "ubl_xpath": "cac:PostalAddress/cac:AddressLine/cbc:Line",
    },
    "country_subdivision": {
        "label": "Country Subdivision Name",
        "cii_xpath": "ram:PostalTradeAddress/ram:CountrySubDivisionName",
        "ubl_xpath": "cac:PostalAddress/cbc:CountrySubentity",
    },
}


EN16931_PARTY_FIELDS = {
    "name": {
        "label": "Legal Name",
        "cii_xpath": "ram:Name",
        "ubl_xpath": "cac:PartyLegalEntity/cbc:RegistrationName",
    },
    "identifiers": {
        "label": "Party Identifiers",
        "format": "schemeID_dict",  # note that I only use schemeID_dict format
        # for 0..n fields and not for 0..1 fields
        "cii_xpath": ["ram:GlobalID", "ram:ID"],
        "ubl_xpath": "cac:PartyIdentification/cbc:ID",
    },
    "legal_identifier": {
        "label": "Party Legal Identifier",
        "cii_xpath": "ram:SpecifiedLegalOrganization/ram:ID",
        "ubl_xpath": "cac:PartyLegalEntity/cbc:CompanyID",
    },
    "legal_identifier_schemeid": {
        "label": "Party Legal Identifier - Scheme ID",
        "cii_xpath": "ram:SpecifiedLegalOrganization/ram:ID/@schemeID",
        "ubl_xpath": "cac:PartyLegalEntity/cbc:CompanyID/@schemeID",
    },
    "vat_identifier": {  # in extended level, it is written as 0..2, I don't know why
        "label": "VAT Identification Number",
        "cii_xpath": "ram:SpecifiedTaxRegistration/ram:ID[@schemeID='VA']",
        "ubl_xpath": "cac:PartyTaxScheme[cac:TaxScheme/cbc:ID='VAT']/cbc:CompanyID",
    },
    "tax_identifier": {  # in extended level, it is written as 0..2, I don't know why
        "label": "Tax Identification",
        "min_level": "en16931",
        "cii_xpath": "ram:SpecifiedTaxRegistration/ram:ID[@schemeID='FC']",
        "ubl_xpath": "cac:PartyTaxScheme[cac:TaxScheme/cbc:ID='LOC']/cbc:CompanyID",
    },
    # no need for tax_identifier schemeID, because its value is fixed
    "legal_info": {
        "label": "Additional Legal Information",
        "min_level": "en16931",
        "cii_xpath": "ram:Description",
        "ubl_xpath": "cac:PartyLegalEntity/cbc:CompanyLegalForm",
    },
    "biz_name": {
        "label": "Trading Name",
        "cii_xpath": "ram:SpecifiedLegalOrganization/ram:TradingBusinessName",
        "ubl_xpath": "cac:PartyName/cbc:Name",
    },
    "einvoicing_addr": {
        "label": "eInvoicing Address",
        "cii_xpath": "ram:URIUniversalCommunication/ram:URIID",
        "ubl_xpath": "cbc:EndpointID",
    },
    "einvoicing_addr_schemeid": {
        "label": "eInvoicing Address - Scheme ID",
        "cii_xpath": "ram:URIUniversalCommunication/ram:URIID/@schemeID",
        "ubl_xpath": "cbc:EndpointID/@schemeID",
    },
    "role_code": {
        "label": "Role Code",
        "min_level": "extended",
        "cii_xpath": "ram:RoleCode",
        "ubl_xpath": "cbc:IndustryClassificationCode",
    },
    # CONTACT
    "contacts": {
        "label": "Contacts",
        "format": "list",
        "min_level": "en16931",
        "cii_xpath": "ram:DefinedTradeContact",
        "ubl_xpath": "cac:Contact",
        "fields": {
            "name": {
                "label": "Contact Name",
                "cii_xpath": ["ram:PersonName", "ram:DepartmentName"],
                "ubl_xpath": "cbc:Name",
            },
            "phone": {
                "label": "Contact Phone Number",
                "cii_xpath": "ram:TelephoneUniversalCommunication/ram:CompleteNumber",
                "ubl_xpath": "cbc:Telephone",
            },
            "email": {
                "label": "Contact E-Mail Address",
                "cii_xpath": "ram:EmailURIUniversalCommunication/ram:URIID",
                "ubl_xpath": "cbc:ElectronicMail",
            },
            "type_code": {
                "label": "Contact Type Code",
                "cii_xpath": "ram:TypeCode",
                # doesn't exist in UBL
            },
        },
    },
}

EN16931_PARTY_FIELDS.update(EN16931_ADDRESS_FIELDS)


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


def _get_currency_precision(currency_field, currency_code):
    if not currency_code:
        return "none"
    try:
        currency = Currency(currency_code.strip().upper())
    except Exception as err:
        raise ValueError(
            f"Currency {currency_code} declared in {currency_field} "
            f"is not supported by the iso4217 lib. Error: {err}"
        ) from err
    prec = currency.exponent
    logger.debug(
        f"Decimal precision of {currency_field} currency {currency_code} = {prec}"
    )
    return prec


def preprocess_data_dict(
    data_dict, flavor, level, fields_dict=None, decimal_precision_dict=None
):
    if not isinstance(data_dict, dict):
        raise ValueError("data_dict arg must be a dict")
    assert flavor in ("ubl-2.1", "factur-x")
    instance_map = {
        "date": datetime.date,
        "list": list,
        "string": str,
        "monetary_BT-5": str,
        "monetary_BT-6": str,
        "price": str,
        "qty": str,
        "percent": str,
        "bytes": bytes,
        "party_dict": dict,
        "schemeID_dict": dict,
        "listID_listVersionID_dict": dict,
        "schemeID_ReferenceTypeCode_dict": dict,
    }
    if decimal_precision_dict is None:
        # decimal_precision_dict is None for the initial call of this method
        # (not for the "recursive" calls that enter in the sub-dicts
        if level == "autodetect":
            if not data_dict.get("BT-24"):
                raise ValueError(
                    "level='autodetect' requires a key 'BT-24' in data_dict"
                )
            for level_option, bt_24 in LEVEL2BT_24.items():
                if (
                    level_option in FLAVOR2LEVELS[flavor]
                    and bt_24 == data_dict["BT-24"]
                ):
                    level = level_option
            if level == "autodetect":
                raise ValueError(
                    "Autodetection of level failed because the value of "
                    f"data_dict['BT-24'] ({data_dict['BT-24']}) is invalid "
                    f"for flavor {flavor}"
                )
        elif level in FLAVOR2LEVELS[flavor]:
            bt_24 = LEVEL2BT_24[level]
            if data_dict.get("BT-24") and data_dict["BT-24"] != bt_24:
                logger.warning(
                    f"Overwriting 'BT-24' in data_dict for level '{level}': "
                    f"initial value '{data_dict['BT-24']}' -> new value '{bt_24}'"
                )
            data_dict["BT-24"] = bt_24
        else:
            raise ValueError(
                f"For flavor '{flavor}', allowed level values are: "
                f"{', '.join(FLAVOR2LEVELS[flavor])} and autodetect"
            )

        if not data_dict.get("BT-5"):
            raise ValueError("Missing key BT-5 in data_dict")
        decimal_precision_dict = {
            # for price, even if XP_Z12-012_Annexe_A_2026_V1.4_VF.xlsx says
            # 19,6 for BT-146/147/148, the PDF spec says in section 4.4.1 that
            # the precision of prices is 4 decimals
            "price": 4,
            "qty": 4,
            "percent": 2,
            "monetary_BT-5": _get_currency_precision("BT-5", data_dict["BT-5"]),
            "monetary_BT-6": _get_currency_precision("BT-6", data_dict.get("BT-6")),
        }
    addr_fields_list = list(EN16931_ADDRESS_FIELDS.keys())
    if fields_dict is None:
        fields_dict = EN16931_FIELDS
    for field, props in fields_dict.items():
        if field not in data_dict:
            if props.get("required"):
                raise ValueError(f"Required field {field} is not in data_dictxxxx.")
            continue
        value = data_dict[field]
        if props.get("required") and not isinstance(value, (int, float)) and not value:
            raise ValueError(f"No value for required field {field}.")

        field_format = props.get("format", "string")
        assert field_format in instance_map
        # to make it easier when data_dict is generated from a JSON,
        # we do format conversion below
        # date fields: we also accept date as string,
        # and we convert it to python date objects
        if value and field_format == "date" and isinstance(value, str):
            try:
                value = datetime.date.fromisoformat(value)
            except Exception as err:
                raise ValueError(
                    f"Field {field} is a date field. Its value ({value}) has "
                    f"been set as a string, but not in the format YYYY-MM-DD"
                ) from err
        # bytes fields: we also accept as base64-encoded string
        # and we convert it to raw bytes
        elif value and field_format == "bytes" and isinstance(value, str):
            value = base64.b64decode(value)
        elif value and field_format in (
            "schemeID_dict",
            "schemeID_ReferenceTypeCode_dict",
        ):
            # if the key of the dict is "null" (due to json conversion),
            # convert it to None
            value = {
                schemeID != "null" and schemeID or None: val
                for schemeID, val in value.items()
            }
        elif value and field_format == "listID_listVersionID_dict":
            # same as previous elif, but for the 2 levels of dict
            value = {
                listID != "null" and listID or None: {
                    listVersionID != "null" and listVersionID or None: val
                    for listVersionID, val in listVersionID_val_dict.items()
                }
                for listID, listVersionID_val_dict in value.items()
            }
        # monetary/qty/price/percent fields: we also accept float
        # and we convert it to string
        elif field_format in decimal_precision_dict:
            if isinstance(value, (int, float)):
                prec = decimal_precision_dict[field_format]
                if not isinstance(prec, int):
                    if field_format == "monetary_BT-6":
                        raise ValueError(
                            f"Field {field} (value {value}) is a monetary field "
                            f"in BT-6 currency, but BT-6 is not defined in data_dict"
                        )
                    else:
                        raise ValueError("Should never happen")
                if field_format.startswith("monetary"):
                    value = f"{value:.{prec}f}"
                elif field_format == "price":
                    value_rounded = round(value, prec)
                    value_str = str(value_rounded)
                    if "." in value_str:
                        value_decimals = len(value_str.split(".")[1])
                    else:
                        value_decimals = 0
                    if prec < decimal_precision_dict["monetary_BT-5"]:
                        raise ValueError(
                            f"Price decimal precision ({prec}) should never be "
                            f"superior to the decimal precision of the BT-5 currency "
                            f"({decimal_precision_dict['monetary_BT-5']})"
                        )
                    if value_decimals <= decimal_precision_dict["monetary_BT-5"]:
                        price_prec = decimal_precision_dict["monetary_BT-5"]
                    elif value_decimals >= prec:
                        price_prec = prec
                    else:
                        price_prec = value_decimals
                    value = f"{value:.{price_prec}f}"
                else:
                    value = f"{round(value, prec):g}"
            elif isinstance(value, str):
                try:
                    float(value)
                except Exception as err:
                    raise ValueError(
                        f"Value of field {field} ({value}) is not a valid "
                        f"float string. Error: {err}"
                    ) from err
        # end of value re-writing
        data_dict[field] = value

        instance_format = instance_map[field_format]
        if not isinstance(value, instance_format) and value not in (False, None):
            raise ValueError(
                f"Field {field} should be in format '{field_format}' "
                f"but its type is '{type(value).__name__}'"
            )
        # fields that exists in CII but not in UBL (BT-11-0, ...)
        # I haven't found so far fields that exist in UBL but not in CII
        if (
            flavor == "ubl-2.1"
            and props.get("cii_xpath")
            and not props.get("ubl_xpath")
        ):
            data_dict.pop(field)
        min_level = props.get("min_level")
        if not min_level and field.startswith("EXT-FR-FE-"):
            min_level = "extended"
        if (
            field in data_dict
            and min_level
            and (
                (min_level == "extended" and level in ("basicwl", "en16931"))
                or (min_level == "en16931" and level == "basicwl")
            )
        ):
            logger.warning(
                f"field {field} removed from data_dict because level is {level} "
                f"and minimum level for {field} is {min_level}"
            )
            data_dict.pop(field)
            continue
        if (
            props.get("format") == "party_dict"
            and value
            and (props.get("party_dict_whitelist") or props.get("party_dict_blacklist"))
        ):
            tmp_dict = None
            if props.get("party_dict_whitelist"):
                whitelist = props["party_dict_whitelist"]
                if "address" in whitelist:
                    whitelist += addr_fields_list
                    whitelist.remove("address")
                tmp_dict = {key: val for key, val in value.items() if key in whitelist}
            elif props.get("party_dict_blacklist"):
                blacklist = props["party_dict_blacklist"]
                if "address" in blacklist:
                    blacklist += addr_fields_list
                    blacklist.remove("address")
                # biz_name is basicwl in BG-4 and en16931 in bg-7
                if level == "basicwl" and field == "BG-7":
                    blacklist.append("biz_name")
                tmp_dict = {
                    key: val for key, val in value.items() if key not in blacklist
                }
            if tmp_dict is not None:
                data_dict[field] = {
                    key: val
                    for key, val in tmp_dict.items()
                    if (
                        EN16931_PARTY_FIELDS[key].get("min_level")
                        and (
                            (
                                EN16931_PARTY_FIELDS[key].get("min_level") == "extended"
                                and level == "extended"
                            )
                            or (
                                EN16931_PARTY_FIELDS[key].get("min_level") == "en16931"
                                and level in ("extended", "en16931")
                            )
                        )
                        or not EN16931_PARTY_FIELDS[key].get("min_level")
                    )
                }
        if (
            props.get("format") == "list"
            and props.get("fields")
            and isinstance(props["fields"], dict)
            and data_dict.get(field)
            and isinstance(data_dict[field], list)
        ):
            for entry in data_dict[field]:
                preprocess_data_dict(
                    entry,
                    flavor,
                    level,
                    fields_dict=props["fields"],
                    decimal_precision_dict=decimal_precision_dict,
                )
    # check BT-18 in en16931
    if level == "en16931" and data_dict.get("BT-18") and len(data_dict["BT-18"]) > 1:
        logger.warning(
            "In profile EN16931, BT-18 can have only one entry. "
            "Keeping only the first one"
        )
        first_key = next(iter(data_dict["BT-18"]))
        data_dict["BT-18"] = {first_key: data_dict["BT-18"][first_key]}
    # BT-17
    # BT-17 should be 0..n in CII extended-ctc-fr (in addition to Factur-X extended)
    # but the CII extended-ctc-fr schematron has a warning rule on it
    # https://github.com/fnfempe/France_RFE/issues/78  TODO update when bug is closed
    if (
        (level != "extended" or flavor != "factur-x")
        and data_dict.get("BT-17")
        and len(data_dict["BT-17"]) > 1
    ):
        logger.warning(
            "BT-17 is a list that can have several entries only in CII extended. "
            "Keeping only the first entry"
        )
        data_dict["BT-17"] = [data_dict["BT-17"][0]]
    # BT-147-00
    if (
        (level == "en16931" or flavor == "ubl-2.1")
        and data_dict.get("BT-147-00")
        and len(data_dict["BT-147-00"]) > 1
    ):
        logger.warning(
            "BT-147-00 is a list that can have several entries only in CII extended. "
            "Keeping only the first entry"
        )
        data_dict["BT-147-00"] = [data_dict["BT-147-00"][0]]

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
        # BT-127-00 : 0..n in extended but 0..1 otherwise
        if level in ("basicwl", "en16931"):
            single_note_list = []
            for note_dict in line_dict.get("BT-127-00") or []:
                if note_dict.get("BT-127"):
                    single_note_list.append(note_dict["BT-127"])
            line_dict["BT-127-00"] = [{"BT-127": "\n".join(single_note_list)}]
    return level


def _cii_generate_party(node_name, partner_dict, namespaces):
    if not node_name:
        raise ValueError("node_name arg is required")
    if not partner_dict:
        return
    if not isinstance(partner_dict, dict):
        raise ValueError("partner_dict arg must be a dict")
    tax_schemes = {}
    if partner_dict.get("vat_identifier"):
        tax_schemes["VA"] = partner_dict["vat_identifier"]
    if partner_dict.get("tax_identifier"):
        tax_schemes["FC"] = partner_dict["tax_identifier"]
    RAM = namespaces["ram"]
    generate_node_method = getattr(RAM, node_name)
    return generate_node_method(
        *[
            RAM.ID(privateid)
            for schemeid, privateid in (partner_dict.get("identifiers") or {}).items()
            if not schemeid
        ],
        *[
            RAM.GlobalID(globalid, schemeID=schemeid)
            for schemeid, globalid in (partner_dict.get("identifiers") or {}).items()
            if schemeid
        ],
        RAM.Name(partner_dict["name"]),
        *[
            RAM.Description(partner_dict["legal_info"])
            for _ in [1]
            if partner_dict.get("legal_info")
        ],
        *[
            RAM.RoleCode(partner_dict["role_code"])
            for _ in [1]
            if partner_dict.get("role_code")
        ],
        *[
            RAM.SpecifiedLegalOrganization(
                *[
                    RAM.ID(
                        partner_dict["legal_identifier"],
                        schemeID=partner_dict["legal_identifier_schemeid"],
                    )
                    for _ in [1]
                    if partner_dict.get("legal_identifier")
                    and partner_dict.get("legal_identifier_schemeid")
                ],
                *[
                    RAM.TradingBusinessName(partner_dict["biz_name"])
                    for _ in [1]
                    if partner_dict.get("biz_name")
                ],
            )
            for _ in [1]
            if (
                partner_dict.get("legal_identifier")
                and partner_dict.get("legal_identifier_schemeid")
            )
            or partner_dict.get("biz_name")
        ],
        *[
            RAM.DefinedTradeContact(
                *[
                    RAM.PersonName(contact_dict["name"])
                    for _ in [1]
                    if contact_dict.get("name")
                ],
                *[
                    RAM.DepartmentName(contact_dict["department_name"])
                    for _ in [1]
                    if contact_dict.get("department_name")
                ],
                *[
                    RAM.TypeCode(contact_dict["type_code"])
                    for _ in [1]
                    if contact_dict.get("type_code")
                ],
                *[
                    RAM.TelephoneUniversalCommunication(
                        RAM.CompleteNumber(contact_dict["phone"])
                    )
                    for _ in [1]
                    if contact_dict.get("phone")
                ],
                *[
                    RAM.EmailURIUniversalCommunication(RAM.URIID(contact_dict["email"]))
                    for _ in [1]
                    if contact_dict.get("email")
                ],
            )
            for contact_dict in partner_dict.get("contacts") or []
        ],
        *[
            RAM.PostalTradeAddress(
                *[
                    RAM.PostcodeCode(partner_dict["postcode"])
                    for _ in [1]
                    if partner_dict.get("postcode")
                ],
                *[
                    RAM.LineOne(partner_dict["addr_l1"])
                    for _ in [1]
                    if partner_dict.get("addr_l1")
                ],
                *[
                    RAM.LineTwo(partner_dict["addr_l2"])
                    for _ in [1]
                    if partner_dict.get("addr_l2")
                ],
                *[
                    RAM.LineThree(partner_dict["addr_l3"])
                    for _ in [1]
                    if partner_dict.get("addr_l3")
                ],
                *[
                    RAM.CityName(partner_dict["city"])
                    for _ in [1]
                    if partner_dict.get("city")
                ],
                RAM.CountryID(partner_dict["country_code"]),
                *[
                    RAM.CountrySubDivisionName(partner_dict["country_subdivision"])
                    for _ in [1]
                    if partner_dict.get("country_subdivision")
                ],
            )
            for _ in [1]
            if partner_dict.get("country_code")
        ],
        *[
            RAM.URIUniversalCommunication(
                RAM.URIID(
                    partner_dict["einvoicing_addr"],
                    schemeID=partner_dict["einvoicing_addr_schemeid"],
                )
            )
            for _ in [1]
            if partner_dict.get("einvoicing_addr")
            and partner_dict.get("einvoicing_addr_schemeid")
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
                    "bin": entry.get("BT-125") and base64.b64encode(entry["BT-125"]),
                    "mimecode": entry.get("BT-125-1"),
                    "filename": entry.get("BT-125-2"),
                }
            )
    for bt17 in data_dict.get("BT-17") or []:
        refdocs.append({"id": bt17, "type_code": "50"})
    for ref_type_code, value in (data_dict.get("BT-18") or {}).items():
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


def _cii_generate_single_allowance_charge(namespaces, indicator, allowance_charge_dict):
    if indicator not in ("false", "true"):
        raise ValueError("Wrong value for indicator argument")
    RAM = namespaces["ram"]
    UDT = namespaces["udt"]
    return RAM.SpecifiedTradeAllowanceCharge(
        RAM.ChargeIndicator(UDT.Indicator(indicator)),
        *[
            RAM.CalculationPercent(allowance_charge_dict["rate"])
            for _ in [1]
            if allowance_charge_dict.get("rate")
        ],
        *[
            RAM.BasisAmount(allowance_charge_dict["base_amount"])
            for _ in [1]
            if allowance_charge_dict.get("base_amount")
        ],
        RAM.ActualAmount(allowance_charge_dict["amount"]),
        *[
            RAM.ReasonCode(allowance_charge_dict["reason_code"])
            for _ in [1]
            if allowance_charge_dict.get("reason_code")
            and not allowance_charge_dict.get("non_vat_tax_code")
        ],
        *[
            RAM.ReasonCode(allowance_charge_dict["non_vat_tax_code"], listID="5153")
            for _ in [1]
            if allowance_charge_dict.get("non_vat_tax_code")
            and not allowance_charge_dict.get("reason_code")
        ],
        *[
            RAM.Reason(allowance_charge_dict["reason"])
            for _ in [1]
            if allowance_charge_dict.get("reason")
        ],
        *[
            RAM.CategoryTradeTax(
                RAM.TypeCode("VAT"),
                *[
                    RAM.ExemptionReason(allowance_charge_dict["vat_exemption"])
                    for _ in [1]
                    if allowance_charge_dict.get("vat_exemption")
                ],
                RAM.CategoryCode(allowance_charge_dict["vat_category_code"]),
                *[
                    RAM.ExemptionReasonCode(allowance_charge_dict["vat_exemption_code"])
                    for _ in [1]
                    if allowance_charge_dict.get("vat_exemption_code")
                ],
                *[
                    RAM.RateApplicablePercent(allowance_charge_dict["vat_rate"])
                    for _ in [1]
                    if allowance_charge_dict.get("vat_rate")
                ],
            )
            for _ in [1]
            if allowance_charge_dict.get("vat_category_code")
        ],
    )


def _cii_generate_single_invoice_line(namespaces, line_dict):
    if not isinstance(line_dict, dict):
        raise ValueError("BG-25 must be a list of dicts")
    RAM = namespaces["ram"]
    UDT = namespaces["udt"]
    QDT = namespaces["qdt"]
    return RAM.IncludedSupplyChainTradeLineItem(
        RAM.AssociatedDocumentLineDocument(
            RAM.LineID(line_dict["BT-126"]),
            *[
                RAM.IncludedNote(
                    RAM.Content(note["BT-127"]),
                    *[
                        RAM.SubjectCode(note["EXT-FR-FE-183"])
                        for _ in [1]
                        if note.get("EXT-FR-FE-183")
                    ],
                )
                for note in (line_dict.get("BT-127-00") or [])
                if note.get("BT-127")
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
                    RAM.Description(attrib_dict["BT-160"]),
                    RAM.Value(attrib_dict["BT-161"]),
                )
                for attrib_dict in (line_dict.get("BG-32") or [])
                if attrib_dict.get("BT-160") and attrib_dict.get("BT-161")
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
                for (listID, listVersionID_value_dict) in (
                    line_dict.get("BT-158") or {}
                ).items()
                if listID
                for listVersionID, value in listVersionID_value_dict.items()
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
                            line_dict["BT-149"], unitCode=line_dict["BT-130"]
                        )
                        for _ in [1]
                        if line_dict.get("BT-149")
                    ],
                    *[
                        RAM.AppliedTradeAllowanceCharge(
                            RAM.ChargeIndicator(UDT.Indicator("false")),
                            RAM.ActualAmount(price_disc["BT-147"]),
                            *[
                                RAM.ReasonCode(price_disc["EXT-FR-FE-196"])
                                for _ in [1]
                                if price_disc.get("EXT-FR-FE-196")
                            ],
                            *[
                                RAM.Reason(price_disc["EXT-FR-FE-195"])
                                for _ in [1]
                                if price_disc.get("EXT-FR-FE-195")
                            ],
                        )
                        for price_disc in line_dict.get("BT-147-00") or []
                    ],
                )
                for _ in [1]
                if line_dict.get("BT-148") or line_dict.get("BT-147-00")
            ],
            RAM.NetPriceProductTradePrice(
                RAM.ChargeAmount(line_dict["BT-146"]),
                *[
                    RAM.BasisQuantity(
                        line_dict["BT-149"],
                        unitCode=line_dict["BT-130"],
                    )
                    for _ in [1]
                    if line_dict.get("BT-149")
                ],
            ),
        ),
        RAM.SpecifiedLineTradeDelivery(
            RAM.BilledQuantity(line_dict["BT-129"], unitCode=line_dict["BT-130"]),
            _cii_generate_party(  # EXT-FR-FE-BG-10
                "ShipToTradeParty", line_dict.get("EXT-FR-FE-BG-10"), namespaces
            ),
            *[
                RAM.DespatchAdviceReferencedDocument(
                    *[
                        RAM.IssuerAssignedID(line_dict["EXT-FR-FE-140"])
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-140")
                    ],
                    *[
                        RAM.LineID(line_dict["EXT-FR-FE-141"])
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-141")
                    ],
                )
                for _ in [1]
                if line_dict.get("EXT-FR-FE-140") or line_dict.get("EXT-FR-FE-141")
            ],
        ),
        RAM.SpecifiedLineTradeSettlement(
            RAM.ApplicableTradeTax(
                RAM.TypeCode("VAT"),
                *[
                    RAM.ExemptionReason(line_dict["EXT-FR-FE-178"])
                    for _ in [1]
                    if line_dict.get("EXT-FR-FE-178")
                ],
                RAM.CategoryCode(line_dict["BT-151"]),
                *[
                    RAM.ExemptionReasonCode(line_dict["EXT-FR-FE-179"])
                    for _ in [1]
                    if line_dict.get("EXT-FR-FE-179")
                ],
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
                    "false",
                    allowance_dict,
                )
                for allowance_dict in (line_dict.get("BG-27") or [])
            ],
            *[
                _cii_generate_single_allowance_charge(
                    namespaces,
                    "true",
                    charge_dict,
                )
                for charge_dict in (line_dict.get("BG-28") or [])
            ],
            RAM.SpecifiedTradeSettlementLineMonetarySummation(
                RAM.LineTotalAmount(line_dict["BT-131"]),
            ),
            *[
                RAM.InvoiceReferencedDocument(
                    RAM.IssuerAssignedID(line_dict["EXT-FR-FE-136"]),
                    *[
                        RAM.LineID(line_dict["EXT-FR-FE-139"])
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-139")
                    ],
                    *[
                        RAM.TypeCode(line_dict["EXT-FR-FE-137"])
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-137")
                    ],
                    *[
                        RAM.FormattedIssueDateTime(
                            QDT.DateTimeString(
                                _cii_date_to_string(line_dict["EXT-FR-FE-138"]),
                                format="102",
                            )
                        )
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-138")
                    ],
                )
                for _ in [1]
                if line_dict.get("EXT-FR-FE-136")
            ],
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
                for ref_type_code, value in (line_dict.get("BT-128") or {}).items()
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
    data_dict,
    level="autodetect",
    check_xsd=True,
    check_schematron="base",
    saxon_server_url=None,
    saxon_server_codedb_base_url=None,
    saxon_server_codedb_dir=None,
    saxon_server_raise_if_http_error=False,
    prefixed_namespaces=True,
):
    # in data_dict, the key names use ID CII and not ID Modèle AFNOR FE
    # because we don't want France-specific stuff
    level = preprocess_data_dict(data_dict, "factur-x", level)
    FX_NAMESPACES = get_xml_namespaces("factur-x")
    if prefixed_namespaces:
        RSM = objectify.ElementMaker(
            namespace=FX_NAMESPACES["rsm"], nsmap=FX_NAMESPACES, annotate=False
        )
        RAM = objectify.ElementMaker(namespace=FX_NAMESPACES["ram"], annotate=False)
        UDT = objectify.ElementMaker(namespace=FX_NAMESPACES["udt"], annotate=False)
        QDT = objectify.ElementMaker(namespace=FX_NAMESPACES["qdt"], annotate=False)
    else:
        RSM = objectify.ElementMaker(
            namespace=FX_NAMESPACES["rsm"],
            nsmap={None: FX_NAMESPACES["rsm"]},
            annotate=False,
        )
        RAM = objectify.ElementMaker(
            namespace=FX_NAMESPACES["ram"],
            nsmap={None: FX_NAMESPACES["ram"]},
            annotate=False,
        )
        UDT = objectify.ElementMaker(
            namespace=FX_NAMESPACES["udt"],
            nsmap={None: FX_NAMESPACES["udt"]},
            annotate=False,
        )
        QDT = objectify.ElementMaker(
            namespace=FX_NAMESPACES["qdt"],
            nsmap={None: FX_NAMESPACES["qdt"]},
            annotate=False,
        )

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
                _cii_generate_party(
                    "SellerTradeParty",
                    data_dict["BG-4"],
                    namespaces,
                ),
                # BUYER  BG-7
                _cii_generate_party(
                    "BuyerTradeParty",
                    data_dict["BG-7"],
                    namespaces,
                ),
                # Sales Agent  EXT-FR-FE-BG-03
                _cii_generate_party(
                    "SalesAgentTradeParty", data_dict.get("EXT-FR-FE-BG-03"), namespaces
                ),
                # Seller Tax Representative  BG-11
                _cii_generate_party(
                    "SellerTaxRepresentativeTradeParty",
                    data_dict.get("BG-11"),
                    namespaces,
                ),
                # Incoterms  EXT-FR-FE-BG-14
                *[
                    RAM.ApplicableTradeDeliveryTerms(
                        RAM.DeliveryTypeCode(data_dict["EXT-FR-FE-185"]),
                        *[
                            RAM.RelevantTradeLocation(
                                RAM.Name(data_dict["EXT-FR-FE-186"])
                            )
                            for _ in [1]
                            if data_dict.get("EXT-FR-FE-186")
                        ],
                    )
                    for _ in [1]
                    if data_dict.get("EXT-FR-FE-185")
                ],
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
                _cii_generate_party(  # Buyer Agent
                    "BuyerAgentTradeParty",
                    data_dict.get("EXT-FR-FE-BG-01"),
                    namespaces,
                ),
                *[
                    RAM.SpecifiedProcuringProject(
                        RAM.ID(data_dict["BT-11"]),
                        # Name is required if ID is present
                        RAM.Name(data_dict.get("BT-11-0") or data_dict["BT-11"]),
                    )
                    for _ in [1]
                    if data_dict.get("BT-11")
                ],
            ),
            RAM.ApplicableHeaderTradeDelivery(
                _cii_generate_party(
                    "ShipToTradeParty",
                    data_dict.get("BG-13"),
                    namespaces,
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
                    RAM.PaymentReference(data_dict["BT-83"])
                    for _ in [1]
                    if data_dict.get("BT-83")
                ],
                *[
                    RAM.TaxCurrencyCode(data_dict["BT-6"])
                    for _ in [1]
                    if data_dict.get("BT-6")
                ],
                RAM.InvoiceCurrencyCode(data_dict["BT-5"]),
                _cii_generate_party(  # Invoicer
                    "InvoicerTradeParty",
                    data_dict.get("EXT-FR-FE-BG-05"),
                    namespaces,
                ),
                _cii_generate_party(  # Invoicee
                    "InvoiceeTradeParty",
                    data_dict.get("EXT-FR-FE-BG-04"),
                    namespaces,
                ),
                # Payee (Basic WL)  BG-10
                _cii_generate_party(
                    "PayeeTradeParty",
                    data_dict.get("BG-10"),
                    namespaces,
                ),
                # Payer  EXT-FR-FE-BG-02
                _cii_generate_party(  # Payer
                    "PayerTradeParty",
                    data_dict.get("EXT-FR-FE-BG-02"),
                    namespaces,
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
                            RAM.DueDateTypeCode(
                                BT_8toCII.get(data_dict["BT-8"], data_dict["BT-8"])
                            )
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
                        namespaces, "false", allowance_dict
                    )
                    for allowance_dict in (data_dict.get("BG-20") or [])
                ],
                *[
                    _cii_generate_single_allowance_charge(
                        namespaces, "true", charge_dict
                    )
                    for charge_dict in (data_dict.get("BG-21") or [])
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
                    RAM.TaxTotalAmount(
                        data_dict["BT-110"], currencyID=data_dict["BT-5"]
                    ),
                    *[
                        RAM.TaxTotalAmount(
                            data_dict["BT-111"], currencyID=data_dict["BT-6"]
                        )
                        for _ in [1]
                        if data_dict.get("BT-111")
                        and data_dict.get("BT-6")
                        and data_dict.get("BT-6") != data_dict["BT-5"]
                    ],
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
                            RAM.TypeCode(previnv["EXT-FR-FE-02"])
                            for _ in [1]
                            if previnv.get("EXT-FR-FE-02")
                        ],
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
    #    from pprint import pprint

    #    pprint(xml_bytes.decode("utf8"))
    if check_xsd:
        xml_check_xsd(xml_root, flavor="factur-x", level=level)
    if check_schematron:
        xml_check_schematron(
            xml_bytes,
            flavor="factur-x",
            level=level,
            check_option=check_schematron,
            saxon_server_url=saxon_server_url,
            saxon_server_codedb_base_url=saxon_server_codedb_base_url,
            saxon_server_codedb_dir=saxon_server_codedb_dir,
            saxon_server_raise_if_http_error=saxon_server_raise_if_http_error,
        )
    return xml_bytes


def _ubl_generate_party(
    wdict, field, namespaces, agent_field=None, service_provider_field=None
):
    if not field:
        raise ValueError("field arg is required")
    if not wdict:
        return
    if not isinstance(wdict, dict):
        raise ValueError("wdict arg must be a dict")
    partner_dict = wdict.get(field)
    if not partner_dict:
        return
    if not isinstance(partner_dict, dict):
        raise ValueError("partner_dict must be a dict")
    if field in ("BG-4", "BG-7", "EXT-FR-FE-BG-04", "EXT-FR-FE-BG-05"):
        node_name = "Party"
    elif field == "BG-10":
        node_name = "PayeeParty"
    elif field == "BG-11":
        node_name = "TaxRepresentativeParty"
    elif field == "EXT-FR-FE-BG-02":
        node_name = "PayerParty"
    elif field in ("EXT-FR-FE-BG-01", "EXT-FR-FE-BG-03"):
        node_name = "AgentParty"
    else:
        raise ValueError(f"field {field} is not supported by _ubl_generate_party")
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    tax_schemes = {}
    if partner_dict.get("vat_identifier"):
        tax_schemes["VAT"] = partner_dict["vat_identifier"]
    if partner_dict.get("tax_identifier"):
        tax_schemes["LOC"] = partner_dict["tax_identifier"]
    # HACK for tax representative name vs biz_name
    if field in ("BG-10", "BG-11"):
        partner_dict["biz_name"] = partner_dict.get("name")
        partner_dict.pop("name")
    generate_node_method = getattr(CAC, node_name)
    return generate_node_method(
        *[
            CBC.EndpointID(
                partner_dict["einvoicing_addr"],
                schemeID=partner_dict["einvoicing_addr_schemeid"],
            )
            for _ in [1]
            if partner_dict.get("einvoicing_addr")
            and partner_dict.get("einvoicing_addr_schemeid")
        ],
        *[
            CBC.IndustryClassificationCode(partner_dict["role_code"])
            for _ in [1]
            if partner_dict.get("role_code")
        ],
        *[
            CAC.PartyIdentification(
                CBC.ID(
                    ident, {key: val for key, val in [("schemeID", schemeid)] if val}
                )
            )
            for schemeid, ident in (partner_dict.get("identifiers") or {}).items()
        ],
        *[
            CAC.PartyName(CBC.Name(partner_dict["biz_name"]))
            for _ in [1]
            if partner_dict.get("biz_name")
        ],
        _ubl_generate_address("PostalAddress", partner_dict, namespaces),
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
                    CBC.RegistrationName(partner_dict["name"])
                    for _ in [1]
                    if partner_dict.get("name")
                ],
                *[
                    CBC.CompanyID(
                        partner_dict["legal_identifier"],
                        schemeID=partner_dict["legal_identifier_schemeid"],
                    )
                    for _ in [1]
                    if partner_dict.get("legal_identifier")
                    and partner_dict.get("legal_identifier_schemeid")
                ],
                *[
                    CBC.CompanyLegalForm(partner_dict["legal_info"])
                    for _ in [1]
                    if partner_dict.get("legal_info")
                ],
            )
            for _ in [1]
            if partner_dict.get("name")
            or (
                partner_dict.get("legal_identifier")
                and partner_dict.get("legal_identifier_schemeid")
            )
            or partner_dict.get("legal_info")
        ],
        *[
            CAC.Contact(
                *[
                    CBC.Name(contact_dict["name"])
                    for _ in [1]
                    if contact_dict.get("name")
                ],
                *[
                    CBC.Telephone(contact_dict["phone"])
                    for _ in [1]
                    if contact_dict.get("phone")
                ],
                *[
                    CBC.ElectronicMail(contact_dict["email"])
                    for _ in [1]
                    if contact_dict.get("email")
                ],
            )
            for contact_dict in partner_dict.get("contacts") or []
            if contact_dict.get("name")
            or contact_dict.get("phone")
            or contact_dict.get("email")
        ],
        *[
            _ubl_generate_party(wdict, agent_field, namespaces)
            for _ in [1]
            if agent_field and isinstance(wdict.get(agent_field), dict)
        ],
        *[
            CAC.ServiceProviderParty(
                _ubl_generate_party(wdict, service_provider_field, namespaces)
            )
            for _ in [1]
            if service_provider_field
            and isinstance(wdict.get(service_provider_field), dict)
            and (
                wdict[service_provider_field].get("name")
                or wdict[service_provider_field].get("biz_name")
            )
        ],
    )


def _ubl_generate_delivery(date, partner_dict, namespaces):
    if not partner_dict:
        partner_dict = {}
    if not isinstance(partner_dict, dict):
        raise ValueError("partner_dict arg must be a dict")
    if not date and (
        not partner_dict
        or (
            not partner_dict.get("country_code")
            and not partner_dict.get("name")
            and not partner_dict.get("biz_name")
        )
    ):
        return
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    name = partner_dict.get("name") or partner_dict.get("biz_name")
    return CAC.Delivery(
        *[CBC.ActualDeliveryDate(_ubl_date_to_string(date)) for _ in [1] if date],
        *[
            CAC.DeliveryLocation(
                *[
                    CBC.ID(
                        ident,
                        {key: val for key, val in [("schemeID", schemeid)] if val},
                    )
                    for schemeid, ident in (
                        partner_dict.get("identifiers") or {}
                    ).items()
                ],
                _ubl_generate_address("Address", partner_dict, namespaces),
            )
            for _ in [1]
            if partner_dict.get("country_code") or partner_dict.get("identifiers")
        ],
        *[CAC.DeliveryParty(CAC.PartyName(CBC.Name(name))) for _ in [1] if name],
    )


def _ubl_generate_address(node_name, partner_dict, namespaces):
    if not node_name:
        raise ValueError("node_name arg is required")
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    if not partner_dict.get("country_code"):
        return
    generate_node_method = getattr(CAC, node_name)
    return generate_node_method(
        *[
            CBC.StreetName(partner_dict["addr_l1"])
            for _ in [1]
            if partner_dict.get("addr_l1")
        ],
        *[
            CBC.AdditionalStreetName(partner_dict["addr_l2"])
            for _ in [1]
            if partner_dict.get("addr_l2")
        ],
        *[CBC.CityName(partner_dict["city"]) for _ in [1] if partner_dict.get("city")],
        *[
            CBC.PostalZone(partner_dict["postcode"])
            for _ in [1]
            if partner_dict.get("postcode")
        ],
        *[
            CBC.CountrySubentity(partner_dict["country_subdivision"])
            for _ in [1]
            if partner_dict.get("country_subdivision")
        ],
        *[
            CAC.AddressLine(CBC.Line(partner_dict["addr_l3"]))
            for _ in [1]
            if partner_dict.get("addr_l3")
        ],
        CAC.Country(CBC.IdentificationCode(partner_dict["country_code"])),
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
                    "id": entry["BT-122"],
                    "uri": entry.get("BT-124"),
                    "description": entry.get("BT-123"),
                    "bin": entry.get("BT-125") and base64.b64encode(entry["BT-125"]),
                    "mimecode": entry.get("BT-125-1"),
                    "filename": entry.get("BT-125-2"),
                }
            )
    for schemeid, value in (data_dict.get("BT-18") or {}).items():
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


def _ubl_generate_single_allowance_charge(
    namespaces, indicator, allowance_charge_dict, invoice_currency
):
    if indicator not in ("false", "true"):
        raise ValueError("Wrong value for indicator argument")
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    return CAC.AllowanceCharge(
        CBC.ChargeIndicator(indicator),
        *[
            CBC.AllowanceChargeReasonCode(allowance_charge_dict["reason_code"])
            for _ in [1]
            if allowance_charge_dict.get("reason_code")
            and not allowance_charge_dict.get("non_vat_tax_code")
        ],
        *[
            CBC.AllowanceChargeReasonCode(
                allowance_charge_dict["non_vat_tax_code"], listID="5153"
            )
            for _ in [1]
            if allowance_charge_dict.get("non_vat_tax_code")
            and not allowance_charge_dict.get("reason_code")
        ],
        *[
            CBC.AllowanceChargeReason(allowance_charge_dict["reason"])
            for _ in [1]
            if allowance_charge_dict.get("reason")
        ],
        *[
            CBC.MultiplierFactorNumeric(allowance_charge_dict["rate"])
            for _ in [1]
            if allowance_charge_dict.get("rate")
        ],
        CBC.Amount(allowance_charge_dict["amount"], currencyID=invoice_currency),
        *[
            CBC.BaseAmount(
                allowance_charge_dict["base_amount"], currencyID=invoice_currency
            )
            for _ in [1]
            if allowance_charge_dict.get("base_amount")
        ],
        *[
            CAC.TaxCategory(
                CBC.ID(allowance_charge_dict["vat_category_code"]),
                *[
                    CBC.Percent(allowance_charge_dict["vat_rate"])
                    for _ in [1]
                    if allowance_charge_dict.get("vat_rate")
                ],
                *[
                    CBC.TaxExemptionReasonCode(
                        allowance_charge_dict["vat_exemption_code"]
                    )
                    for _ in [1]
                    if allowance_charge_dict.get("vat_exemption_code")
                ],
                *[
                    CBC.TaxExemptionReason(allowance_charge_dict["vat_exemption"])
                    for _ in [1]
                    if allowance_charge_dict.get("vat_exemption")
                ],
                CAC.TaxScheme(CBC.ID("VAT")),
            )
            for _ in [1]
            if allowance_charge_dict.get("vat_category_code")
        ],
    )


def _ubl_generate_single_invoice_line(namespaces, line_dict, invoice_currency, refund):
    if not isinstance(line_dict, dict):
        raise ValueError("BG-25 must be a list of dicts")
    CAC = namespaces["cac"]
    CBC = namespaces["cbc"]
    invoice_line_builder = getattr(CAC, "CreditNoteLine" if refund else "InvoiceLine")
    qty_builder = getattr(CBC, "CreditedQuantity" if refund else "InvoicedQuantity")
    return invoice_line_builder(
        CBC.ID(line_dict["BT-126"]),
        *[
            CBC.Note(
                note.get("EXT-FR-FE-183")
                and f"#{note['EXT-FR-FE-183']}#{note['BT-127']}"
                or note["BT-127"]
            )
            for note in (line_dict.get("BT-127-00") or [])
            if note.get("BT-127")
        ],
        qty_builder(line_dict["BT-129"], unitCode=line_dict["BT-130"]),
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
            CAC.OrderLineReference(
                *[
                    CBC.LineID(line_dict["BT-132"])
                    for _ in [1]
                    if line_dict.get("BT-132")
                ],
                *[
                    CBC.SalesOrderLineID(line_dict["EXT-FR-FE-145"])
                    for _ in [1]
                    if line_dict.get("EXT-FR-FE-145")
                ],
                *[
                    CAC.OrderReference(
                        *[
                            CBC.ID(line_dict["EXT-FR-FE-135"])
                            for _ in [1]
                            if line_dict.get("EXT-FR-FE-135")
                        ],
                        *[
                            CBC.SalesOrderID(line_dict["EXT-FR-FE-144"])
                            for _ in [1]
                            if line_dict.get("EXT-FR-FE-144")
                        ],
                    )
                    for _ in [1]
                    if line_dict.get(
                        "EXT-FR-FE-135"
                    )  # XSD disallows to have EXT-FR-FE-144 without EXT-FR-FE-135
                ],
            )
            for _ in [1]
            if line_dict.get(
                "BT-132"
            )  # XSD disallows to have EXT-FR-FE-* without BT-132
        ],
        *[
            CAC.DespatchLineReference(
                CBC.LineID(line_dict["EXT-FR-FE-141"]),
                *[
                    CAC.DocumentReference(CBC.ID(line_dict["EXT-FR-FE-140"]))
                    for _ in [1]
                    if line_dict.get("EXT-FR-FE-140")
                ],
            )
            for _ in [1]
            if line_dict.get("EXT-FR-FE-141")
        ],
        *[
            CAC.BillingReference(
                CAC.InvoiceDocumentReference(
                    CBC.ID(line_dict["EXT-FR-FE-136"]),
                    *[
                        CBC.IssueDate(_ubl_date_to_string(line_dict["EXT-FR-FE-138"]))
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-138")
                    ],
                    *[
                        CBC.DocumentTypeCode(line_dict["EXT-FR-FE-137"])
                        for _ in [1]
                        if line_dict.get("EXT-FR-FE-137")
                    ],
                ),
                *[
                    CAC.BillingReferenceLine(CBC.ID(line_dict["EXT-FR-FE-139"]))
                    for _ in [1]
                    if line_dict.get("EXT-FR-FE-139")
                ],
            )
            for _ in [1]
            if line_dict.get("EXT-FR-FE-136")
        ],
        *[
            CAC.DocumentReference(
                CBC.ID(
                    value,
                    {key: val for key, val in [("schemeID", schemeid)] if schemeid},
                ),
                CBC.DocumentTypeCode("130"),
            )
            for schemeid, value in (line_dict.get("BT-128") or {}).items()
        ],
        _ubl_generate_delivery(
            line_dict.get("EXT-FR-FE-158"),
            line_dict.get("EXT-FR-FE-BG-10"),
            namespaces,
        ),
        *[
            _ubl_generate_single_allowance_charge(
                namespaces, "false", allowance_dict, invoice_currency
            )
            for allowance_dict in (line_dict.get("BG-27") or [])
        ],
        *[
            _ubl_generate_single_allowance_charge(
                namespaces, "true", charge_dict, invoice_currency
            )
            for charge_dict in (line_dict.get("BG-28") or [])
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
                for (listID, listVersionID_value_dict) in (
                    line_dict.get("BT-158") or {}
                ).items()
                if listID
                for listVersionID, value in listVersionID_value_dict.items()
            ],
            CAC.ClassifiedTaxCategory(
                CBC.ID(line_dict["BT-151"]),
                *[
                    CBC.Percent(line_dict["BT-152"])
                    for _ in [1]
                    if line_dict.get("BT-152")
                ],
                *[
                    CBC.TaxExemptionReasonCode(line_dict["EXT-FR-FE-179"])
                    for _ in [1]
                    if line_dict.get("EXT-FR-FE-179")
                ],
                *[
                    CBC.TaxExemptionReason(line_dict["EXT-FR-FE-178"])
                    for _ in [1]
                    if line_dict.get("EXT-FR-FE-178")
                ],
                CAC.TaxScheme(CBC.ID("VAT")),
            ),
            *[
                CAC.AdditionalItemProperty(
                    CBC.Name(attrib_dict["BT-160"]),
                    CBC.Value(attrib_dict["BT-161"]),
                )
                for attrib_dict in (line_dict.get("BG-32") or [])
                if attrib_dict.get("BT-160") and attrib_dict.get("BT-161")
            ],
        ),  # close Item
        CAC.Price(
            CBC.PriceAmount(line_dict["BT-146"], currencyID=invoice_currency),
            *[
                CBC.BaseQuantity(line_dict["BT-149"], unitCode=line_dict["BT-130"])
                for _ in [1]
                if line_dict.get("BT-149")
            ],
            *[
                CAC.AllowanceCharge(
                    CBC.ChargeIndicator("false"),
                    *[
                        CBC.AllowanceChargeReasonCode(
                            line_dict["BT-147-00"][0]["EXT-FR-FE-196"]
                        )
                        for _ in [1]
                        if line_dict["BT-147-00"][0].get("EXT-FR-FE-196")
                    ],
                    *[
                        CBC.AllowanceChargeReason(
                            line_dict["BT-147-00"][0]["EXT-FR-FE-195"]
                        )
                        for _ in [1]
                        if line_dict["BT-147-00"][0].get("EXT-FR-FE-195")
                    ],
                    CBC.Amount(
                        line_dict["BT-147-00"][0]["BT-147"], currencyID=invoice_currency
                    ),
                    *[
                        CBC.BaseAmount(line_dict["BT-148"], currencyID=invoice_currency)
                        for _ in [1]
                        if line_dict.get("BT-148")
                    ],
                )
                for _ in [1]
                if line_dict.get("BT-147-00")
            ],
        ),
    )


def generate_ubl_xml(
    data_dict,
    level="autodetect",
    check_xsd=True,
    check_schematron="base",
    saxon_server_url=None,
    saxon_server_raise_if_http_error=False,
    prefixed_namespaces=True,
):
    level = preprocess_data_dict(data_dict, "ubl-2.1", level)

    if data_dict.get("BT-90"):
        if data_dict.get("BG-10"):  # if PayeeParty
            if not data_dict["BG-10"].get("identifiers"):
                data_dict["BG-10"]["identifiers"] = {"SEPA": data_dict["BT-90"]}
            else:
                data_dict["BG-10"]["identifiers"]["SEPA"] = data_dict["BT-90"]
        else:  # add to seller block
            if not data_dict["BG-4"].get("identifiers"):
                data_dict["BG-4"]["identifiers"] = {"SEPA": data_dict["BT-90"]}
            else:
                data_dict["BG-4"]["identifiers"]["SEPA"] = data_dict["BT-90"]

    refund = is_credit_note(data_dict)
    UBL_NAMESPACES = get_xml_namespaces(
        "ubl-2.1-creditnote" if refund else "ubl-2.1-invoice"
    )
    default_urn = UBL_NAMESPACES.pop("default")
    UBL_NAMESPACES[None] = default_urn

    if prefixed_namespaces:
        CAC = objectify.ElementMaker(
            namespace=UBL_NAMESPACES["cac"], nsmap=UBL_NAMESPACES, annotate=False
        )
        CBC = objectify.ElementMaker(
            namespace=UBL_NAMESPACES["cbc"], nsmap=UBL_NAMESPACES, annotate=False
        )
        DEFAULT = objectify.ElementMaker(
            namespace=UBL_NAMESPACES[None], nsmap=UBL_NAMESPACES, annotate=False
        )
    else:
        CAC = objectify.ElementMaker(
            namespace=UBL_NAMESPACES["cac"],
            nsmap={None: UBL_NAMESPACES["cac"]},
            annotate=False,
        )
        CBC = objectify.ElementMaker(
            namespace=UBL_NAMESPACES["cbc"],
            nsmap={None: UBL_NAMESPACES["cbc"]},
            annotate=False,
        )
        DEFAULT = objectify.ElementMaker(
            namespace=UBL_NAMESPACES[None],
            nsmap={None: UBL_NAMESPACES[None]},
            annotate=False,
        )

    namespaces = {
        "cac": CAC,
        "cbc": CBC,
    }
    root_builder = getattr(DEFAULT, "CreditNote" if refund else "Invoice")
    type_code_builder = getattr(
        CBC, "CreditNoteTypeCode" if refund else "InvoiceTypeCode"
    )

    xml_root = root_builder(
        # UBLVersionID is optional, but present in sample UBL invoice of AFNOR XPZ12-012
        CBC.UBLVersionID("2.1"),
        CBC.CustomizationID(data_dict["BT-24"]),
        *[CBC.ProfileID(data_dict["BT-23"]) for _ in [1] if data_dict.get("BT-23")],
        CBC.ID(data_dict["BT-1"]),
        CBC.IssueDate(_ubl_date_to_string(data_dict["BT-2"])),
        *[
            CBC.DueDate(_ubl_date_to_string(data_dict["BT-9"]))
            for _ in [1]
            if data_dict.get("BT-9") and not refund
        ],
        type_code_builder(data_dict["BT-3"]),
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
                    CBC.DescriptionCode(
                        BT_8toUBL.get(data_dict["BT-8"], data_dict["BT-8"])
                    )
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
                    *[
                        CBC.DocumentTypeCode(previnv["EXT-FR-FE-02"])
                        for _ in [1]
                        if previnv.get("EXT-FR-FE-02")
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
            CAC.OriginatorDocumentReference(CBC.ID(data_dict["BT-17"][0]))
            for _ in [1]
            if data_dict.get("BT-17") and not refund
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
            if data_dict.get("BT-11") and not refund
        ],
        *[
            CAC.AdditionalDocumentReference(
                CBC.ID(data_dict["BT-11"]),
                CBC.DocumentTypeCode("50"),
            )
            for _ in [1]
            if data_dict.get("BT-11") and refund
        ],
        *[
            CAC.OriginatorDocumentReference(CBC.ID(data_dict["BT-17"][0]))
            for _ in [1]
            if data_dict.get("BT-17") and refund
        ],
        # SELLER  BG-4
        CAC.AccountingSupplierParty(
            _ubl_generate_party(
                data_dict,
                "BG-4",
                namespaces,
                # Sales Agent EXT-FR-FE-BG-03
                agent_field="EXT-FR-FE-BG-03",
                # Invoicer  EXT-FR-FE-BG-05
                service_provider_field="EXT-FR-FE-BG-05",
            ),
        ),
        # BUYER  BG-7
        CAC.AccountingCustomerParty(
            _ubl_generate_party(
                data_dict,
                "BG-7",
                namespaces,
                # Buyer Agent EXT-FR-FE-BG-01
                agent_field="EXT-FR-FE-BG-01",
                # Invoicee  EXT-FR-FE-BG-04
                service_provider_field="EXT-FR-FE-BG-04",
            ),
        ),
        # Payee  BG-10
        _ubl_generate_party(
            data_dict,
            "BG-10",
            namespaces,
        ),
        # Seller Tax Representative  BG-11
        _ubl_generate_party(
            data_dict,
            "BG-11",
            namespaces,
        ),
        _ubl_generate_delivery(
            data_dict.get("BT-72"), data_dict.get("BG-13"), namespaces
        ),
        # Incoterms  EXT-FR-FE-BG-14
        *[
            CAC.DeliveryTerms(
                CBC.ID(data_dict["EXT-FR-FE-185"]),
                *[
                    CAC.DeliveryLocation(CBC.Name(data_dict["EXT-FR-FE-186"]))
                    for _ in [1]
                    if data_dict.get("EXT-FR-FE-186")
                ],
            )
            for _ in [1]
            if data_dict.get("EXT-FR-FE-185")
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
                    CBC.PaymentDueDate(_ubl_date_to_string(data_dict["BT-9"]))
                    for _ in [1]
                    if data_dict.get("BT-9") and refund
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
                        # Payer  EXT-FR-FE-BG-02
                        _ubl_generate_party(data_dict, "EXT-FR-FE-BG-02", namespaces),
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
                namespaces, "false", allowance_dict, data_dict["BT-5"]
            )
            for allowance_dict in (data_dict.get("BG-20") or [])
        ],
        *[
            _ubl_generate_single_allowance_charge(
                namespaces, "true", charge_dict, data_dict["BT-5"]
            )
            for charge_dict in (data_dict.get("BG-21") or [])
        ],
        CAC.TaxTotal(
            CBC.TaxAmount(data_dict["BT-110"], currencyID=data_dict["BT-5"]),
            *[
                CAC.TaxSubtotal(
                    CBC.TaxableAmount(tax_dict["BT-116"], currencyID=data_dict["BT-5"]),
                    CBC.TaxAmount(tax_dict["BT-117"], currencyID=data_dict["BT-5"]),
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
        *[
            CAC.TaxTotal(
                CBC.TaxAmount(data_dict["BT-111"], currencyID=data_dict["BT-6"])
            )
            for _ in [1]
            if data_dict.get("BT-111")
            and data_dict.get("BT-6")
            and data_dict.get("BT-6") != data_dict["BT-5"]
        ],
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
            _ubl_generate_single_invoice_line(
                namespaces, iline, data_dict["BT-5"], refund
            )
            for iline in (data_dict.get("BG-25") or [])
        ],
    )  # Close Invoice
    xml_bytes = etree.tostring(
        xml_root, pretty_print=True, xml_declaration=True, encoding="UTF-8"
    )
    flavor = refund and "ubl-2.1-creditnote" or "ubl-2.1-invoice"
    if check_xsd:
        xml_check_xsd(xml_root, flavor=flavor)
    if check_schematron:
        xml_check_schematron(
            xml_bytes,
            flavor=flavor,
            level=level,
            check_option=check_schematron,
            saxon_server_url=saxon_server_url,
            saxon_server_raise_if_http_error=saxon_server_raise_if_http_error,
        )
    return xml_bytes


def generate_xml(
    data_dict,
    flavor="factur-x",
    level="autodetect",
    check_xsd=True,
    check_schematron="base",
    saxon_server_url=None,
    saxon_server_codedb_base_url=None,
    saxon_server_codedb_dir=None,
    saxon_server_raise_if_http_error=False,
    prefixed_namespaces=True,
):
    if flavor not in ("factur-x", "facturx", "ubl-2.1"):
        raise ValueError("Wrong value for flavor argument")
    if flavor in ("ubl-2.1"):
        return generate_ubl_xml(
            data_dict,
            level=level,
            check_xsd=check_xsd,
            check_schematron=check_schematron,
            saxon_server_url=saxon_server_url,
            saxon_server_raise_if_http_error=saxon_server_raise_if_http_error,
            prefixed_namespaces=prefixed_namespaces,
        )
    else:
        return generate_cii_xml(
            data_dict,
            level=level,
            check_xsd=check_xsd,
            check_schematron=check_schematron,
            saxon_server_url=saxon_server_url,
            saxon_server_codedb_base_url=saxon_server_codedb_base_url,
            saxon_server_codedb_dir=saxon_server_codedb_dir,
            saxon_server_raise_if_http_error=saxon_server_raise_if_http_error,
            prefixed_namespaces=prefixed_namespaces,
        )


def is_credit_note(data_dict):
    if not isinstance(data_dict, dict):
        raise ValueError("data_dict arg must be a dict")
    if not data_dict.get("BT-3"):
        raise ValueError("BT-3 is a required key in data_dict")
    credit_note = bool(data_dict["BT-3"] in CREDIT_NOTE_TYPE_CODES)
    return credit_note


def get_data_dict_copy_for_logs(data_dict):
    """This method generates a copy of data_dict where the bytes fields are
    remplaced by a short informative string,
    to have only the relevant data in the logs"""
    # data_dict may not be a dict when it calls itself
    if isinstance(data_dict, dict):
        return {
            key: get_data_dict_copy_for_logs(value) for key, value in data_dict.items()
        }
    elif isinstance(data_dict, list):
        return [get_data_dict_copy_for_logs(item) for item in data_dict]
    elif isinstance(data_dict, bytes):
        return f"<bytes len={len(data_dict)}>"
    else:
        return data_dict
