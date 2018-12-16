//
//  BSSdkConfiguration.swift
//  BluesnapSDK
//
//  Created by Shevie Chen on 13/11/2017.
//  Copyright © 2017 Bluesnap. All rights reserved.
//

import Foundation

class BSSdkConfiguration: NSObject {

    var kountMID: Int?
    var currencies: BSCurrencies?
    var shopper: BSShopper?

    var supportedPaymentMethods: [String]?
    // TODO: use this top prevent paypal error
    var paypalCurrencies: [String]?
    // TODO: use these to filter out unsupported CC brands
    var creditCardTypes: [String]?
    var creditCardBrands: [String]?
    // TODO: use these to replace the static Regexes in the validator
    var creditCardRegex: [String: String]?
}

class BSShopper: BSBaseAddressDetails {
    public static let LAST_PAYMENT_INFO: String = "lastPaymentInfo";
    public static let SHOPPER_CURRENCY: String = "shopperCurrency";
    public static let VAULTED_SHOPPER_ID: String = "vaultedShopperId";
    public static let PAYMENT_SOURCES: String = "paymentSources";
    public static let SHIPPING_CONTACT_INFO: String = "shippingContactInfo";
    public static let CHOSEN_PAYMENT_METHOD: String = "chosenPaymentMethod";
    public static let TRANSACTION_FRAUD_INFO: String = "transactionFraudInfo";
    public static let FRAUD_SESSION_ID: String = "fraudSessionId";

    // todo: put contact address in baseAddressDetails?
    var vaultedShopperId: Int?
    var email: String?
    var address2: String?
    var phone: String?

    var shippingDetails: BSShippingAddressDetails?
    var chosenPaymentMethod: BSChosenPaymentMethod?

    // todo: change to paymentSources of type paymentInfo
    var existingCreditCards: [BSCreditCardInfo] = []

    // todo: add last payment info? type paymentInfo, base for creditCardInfo

    override func toJson() -> ([String: Any])! {
        var shopperDetails: [String: Any] = super.toJson()
        if let address2 = address2 {
            shopperDetails[BSBaseAddressDetails.ADDRESS_2] = address2
        }
        if let email = email {
            shopperDetails[BSBaseAddressDetails.EMAIL] = email
        }
        if let phone = phone {
            shopperDetails[BSBaseAddressDetails.PHONE] = phone
        }
        if let shippingDetails = shippingDetails {
            shopperDetails[BSShopper.SHIPPING_CONTACT_INFO] = shippingDetails.toJson()
        }
        if let chosenPaymentMethod = chosenPaymentMethod {
            shopperDetails[BSShopper.CHOSEN_PAYMENT_METHOD] = chosenPaymentMethod.toJson()
        }

        if let vaultedShopperId = vaultedShopperId {
            shopperDetails[BSShopper.VAULTED_SHOPPER_ID] = vaultedShopperId
        }
        return shopperDetails
    }
}

/**
Chosen Payment Method for Update Shopper
*/
public class BSChosenPaymentMethod: NSObject, BSJson {
    public static let CHOSEN_PAYMENT_METHOD_TYPE: String = "chosenPaymentMethodType";
    public static let CREDIT_CARD: String = "creditCard";

    var creditCard: BSCreditCard?
    var chosenPaymentMethodType: String?

    public func toJson() -> ([String: Any])! {
        var chosenPaymentMethodBody: [String: Any] = [:]

        if let chosenPaymentMethodType = chosenPaymentMethodType {
            chosenPaymentMethodBody[BSChosenPaymentMethod.CHOSEN_PAYMENT_METHOD_TYPE] = chosenPaymentMethodType

            if chosenPaymentMethodType == BSPaymentType.CreditCard.rawValue, let creditCard = creditCard {
                chosenPaymentMethodBody[BSChosenPaymentMethod.CREDIT_CARD] = creditCard.toJson()
            }
        }

        return chosenPaymentMethodBody
    }
}

public protocol BSJson {
    func toJson() -> ([String: Any])!
}
