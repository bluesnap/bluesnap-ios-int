//
// Created by oz on 15/06/2017.
// Copyright (c) 2017 Bluesnap. All rights reserved.
//

import Foundation
import PassKit

/**
 Apple Pay details for the purchase
 This class fetch information from Passkit PKPayment and adapt it to Bluesnap API call
 */
  public class BSApplePaySdkResult: BSBaseSdkResult {
    
    public override init(sdkRequestBase: BSSdkRequestProtocol) {
        super.init(sdkRequestBase: sdkRequestBase)
        storeCard = nil
        chosenPaymentMethodType = BSPaymentType.ApplePay
    }
  }


// This extention is required only to extract enum string values of the OBJC Passkit type
extension PKPaymentMethodType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .debit:
            return "debit"
        case .prepaid:
            return "prepaid"
        case .store:
            return "store"
        default:
            return "unknown"
        
        }
    }
}



public class BSApplePayInfo
{
    public var tokenPaymentNetwork: String?
    public var tokenPaymentNetworkType: String
    public var token: PKPaymentToken
    public var tokenInstrumentName:String?
    public var transactionId: String
    public let payment: PKPayment
    public var billingContact: PKContact?
    public var shippingContact: PKContact?



    public init(payment:PKPayment)
    {
        self.payment = payment;
        self.token = payment.token
        self.tokenPaymentNetwork = payment.token.paymentMethod.network?.rawValue;
        self.transactionId = payment.token.transactionIdentifier;
        self.tokenInstrumentName = payment.token.paymentMethod.displayName;
        self.billingContact = payment.billingContact;
        self.shippingContact = payment.shippingContact;
        self.tokenPaymentNetworkType = payment.token.paymentMethod.type.description
    }
}

extension BSApplePayInfo: DictionaryConvertible
{

    public func toDictionary() throws -> [String: Any] {

        //let desrilaziedToken = try JSONSerialization.jsonObject(with: payment.token.paymentData, options: JSONSerialization.ReadingOptions())
        let desrilaziedToken: Any
        if (payment.token.transactionIdentifier != "Simulated Identifier") {
            desrilaziedToken = try JSONSerialization.jsonObject(with: payment.token.paymentData, options: JSONSerialization.ReadingOptions())
        } else {
            desrilaziedToken = "Simulated Instrument"
            NSLog("This is a Simulated Instrument")
        }


        let shippingContactDict = [
                "familyName": shippingContact?.name?.familyName ?? "",
                "givenName": shippingContact?.name?.givenName ?? "",
                /**
                These are unused by the API and should not be sent, otherwise API call might fail.
                */
                //"addressLines": shippingContact?.postalAddress?.description,
                //"country": shippingContact?.postalAddress?.country,
                //"countryCode": shippingContact?.postalAddress?.isoCountryCode,
                //"locality": shippingContact?.postalAddress?.street,
                //"emailAddress": shippingContact?.emailAddress,
                //"phoneNumber": shippingContact?.phoneNumber?.stringValue,
                //"postalCode": shippingContact?.postalAddress?.postalCode,
        ] as [String: Any]

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
                "addressLines": billingAddresLines,
                "country": billingContact?.postalAddress?.country ?? "",
                "countryCode": billingContact?.postalAddress?.isoCountryCode ?? "",
                "familyName": billingContact?.name?.familyName ?? "",
                "givenName": billingContact?.name?.givenName ?? "",
                "locality": locality ?? "",
                "postalCode": billingContact?.postalAddress?.postalCode ?? "",
        ] as [String: Any]

        
        let paymentMethod = [
        "displayName": token.paymentMethod.displayName ?? "",
        "network": tokenPaymentNetwork ?? "",
        "type": tokenPaymentNetworkType,
        ] as [String: String]
        
        let pktoken = [
            "transactionIdentifier": token.transactionIdentifier,
            "paymentData": desrilaziedToken,
            "paymentMethod": paymentMethod,
        ] as [String: Any]
        
        let ordered = [
                "billingContact": billingContactDict,
                "shippingContact": shippingContactDict,
                "token": pktoken ,
        ] as [String: Any]
        return ordered
    }
}
