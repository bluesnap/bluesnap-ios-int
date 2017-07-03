//
// Created by oz on 15/06/2017.
// Copyright (c) 2017 Bluesnap. All rights reserved.
//

import Foundation
import PassKit

public class BSApplePayInfo
{
    public var tokenPaymentNetwork: String!
    public var token: PKPaymentToken!
    public var tokenInstrumentName:String!
    public var transactionId: String!
    public let payment: PKPayment
    public var billingContact: PKContact?
    public var shippingContact: PKContact?



    public init(payment:PKPayment)
    {
        self.payment = payment;
        //self.paymentdataString = String(data:payment.token.paymentData, encoding: .utf8);
        self.token = payment.token
        self.tokenPaymentNetwork = payment.token.paymentMethod.network?.rawValue;
        self.transactionId = payment.token.transactionIdentifier;
        self.tokenInstrumentName = payment.token.paymentMethod.displayName;
        self.billingContact = payment.billingContact;
        self.shippingContact = payment.shippingContact;
    }
}

extension BSApplePayInfo: DictionaryConvertible
{
//    public func toDictionary() -> [String : Any] {
//        var map = [String:Any]();
//        map.setValueIfExists(value: self.token, for: "token");
//        map.setValueIfExists(value: self.tokenInstrumentName, for: "token_instrument_name");
//        map.setValueIfExists(value: self.tokenPaymentNetwork, for: "token_payment_network");
//        map.setValueIfExists(value: self.transactionId, for: "transactionIdentifier");
//        map.setValueIfExists(value: self.billingContact?.toDictionary(), for: "billingContact");
//        map.setValueIfExists(value: self.shippingContact?.toDictionary(), for: "shippingContact");
//        return map;
//    }

    public func toDictionary() -> [String: Any] {
        let desrilaziedToken = try! JSONSerialization.jsonObject(with: payment.token.paymentData, options: JSONSerialization.ReadingOptions())

        let shippingContactDict = [
                //"addressLines": shippingContact?.postalAddress?.description,
                //"country": shippingContact?.postalAddress?.country,
                //"countryCode": shippingContact?.postalAddress?.isoCountryCode,
                "familyName": shippingContact?.name?.familyName ?? "",
                "givenName": shippingContact?.name?.givenName ?? "",
                //"locality": shippingContact?.postalAddress?.street,
                //"emailAddress": shippingContact?.emailAddress,
                //"phoneNumber": shippingContact?.phoneNumber?.stringValue,
                //"postalCode": shippingContact?.postalAddress?.postalCode,
        ] as [String: Any]!

        var billingAddresLines = [String]()
        billingAddresLines.append("")
        if (billingContact?.postalAddress?.street != nil) {
            billingAddresLines.append(billingContact!.postalAddress!.street)
        }

        var locality: String? = nil
        if #available(iOS 10.3, *) {
            locality = billingContact?.postalAddress?.subLocality
        }
        let billingContactDict = [
                //"emailAddress": billingContact?.emailAddress,
                //"phoneNumber": billingContact?.phoneNumber?.stringValue,
                "addressLines": billingAddresLines,
                "country": billingContact?.postalAddress?.country ?? "",
                "countryCode": billingContact?.postalAddress?.isoCountryCode ?? "",
                "familyName": billingContact?.name?.familyName ?? "",
                "givenName": billingContact?.name?.givenName ?? "",
                "locality": locality ?? "",
                "postalCode": billingContact?.postalAddress?.postalCode ?? "",
        ] as [String: Any]!

        let ordered = [
                "billingContact": billingContactDict!,
                "shippingContact": shippingContactDict!,
                "token": [
                        "transactionIdentifier": token.transactionIdentifier,
                        "paymentData": desrilaziedToken,
                        "paymentMethod": [
                                "displayName": token.paymentMethod.displayName ?? "",
                                "network": token.paymentMethod.network?._rawValue ?? "",
                                "type": "debit",
                        ],
                ]
        ] as [String: Any]
        return ordered
    }
}