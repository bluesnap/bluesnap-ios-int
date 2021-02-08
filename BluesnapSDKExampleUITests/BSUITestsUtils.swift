//
//  BSUITestsUtils.swift
//  BluesnapSDKExampleUITests
//
//  Created by Sivani on 06/02/2019.
//  Copyright © 2019 Bluesnap. All rights reserved.
//

import Foundation
import XCTest
import BluesnapSDK

class BSUITestUtils {
    
    static func checkRetrieveVaultedShopperResponse(responseBody: Data, sdkRequest: BSSdkRequest, cardStored: Bool = false, expectedCreditCardInfo: [(String,String,String,String)], shippingSameAsBilling: Bool = false, chosenPaymentMethod: String? = nil, cardIndex: Int? = nil, isSubscription: Bool = false) -> BSErrors? {
        var resultError: BSErrors? = nil
        do {
            // Parse the result JSOn object
            if let jsonData = try JSONSerialization.jsonObject(with: responseBody, options: .allowFragments) as? [String: AnyObject] {
                if sdkRequest.shopperConfiguration.withEmail && !isSubscription { // second part is temporary till server bug is fixed
                    checkFieldContent(expectedValue: (sdkRequest.shopperConfiguration.billingDetails?.email!)!, actualValue: jsonData["email"] as! String, fieldName: "email")
                }
                
                
                if let paymentSources = jsonData["paymentSources"] as? [String: AnyObject] {
                    if let creditCardInfo = paymentSources["creditCardInfo"] as? [[String: Any]] {
                        if (!cardStored){
                            NSLog("Error on Retrieve vaulted shopper- 'creditCardInfo' exists when shopper selected DO NOT store")
                            resultError = .unknown
                        }
                        
                        var i = 0
                        for item in creditCardInfo {
                            if let creditCard = item["creditCard"] as? [String: AnyObject], let billingContactInfo = item["billingContactInfo"] as? [String: AnyObject] {
                                //TODO: integrate this for multiple cc
                                //                                let cardLastFourDigits = creditCard["cardLastFourDigits"] as? String
                                let j = creditCard["cardType"] as! String == "VISA" ? 0 : 1
                                if (chosenPaymentMethod == nil ||  (chosenPaymentMethod != nil && j == cardIndex)) { //check info only in chosen card in shopper config
                                    checkShopperInfo(sdkRequest: sdkRequest, resultData: billingContactInfo, isBilling: true)
                                }
                                checkCreditCardInfo(expectedCreditCardInfo: expectedCreditCardInfo[j], resultData: creditCard)
                            } else {
                                NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'creditCard' or 'billingContactInfo'")
                                resultError = .unknown
                            }
                            i += 1
                        }
                        XCTAssertEqual(i, Mirror(reflecting: expectedCreditCardInfo).children.count, "Error: worng number of credit cards in server")

                    } else if (cardStored) {
                        NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'creditCardInfo'")
                        resultError = .unknown
                    }
                } else {
                    NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'paymentSources'")
                    resultError = .unknown
                }
                

                if sdkRequest.shopperConfiguration.withShipping && !isSubscription { // second part is temporary till server bug is fixed
                    if let shippingContactInfo = jsonData["shippingContactInfo"] as? [String: AnyObject] {
                        checkShopperInfo(sdkRequest: sdkRequest, resultData: shippingContactInfo, isBilling: shippingSameAsBilling)
                    } else {
                        NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'shippingContactInfo'")
                        resultError = .unknown
                    }
                }
                
                // choose payment flow
                if let chosenPaymentMethod_ = chosenPaymentMethod {
                    if let chosenPaymentMethodInfo = jsonData["chosenPaymentMethod"] as? [String: AnyObject] {
                        checkFieldContent(expectedValue: chosenPaymentMethod_, actualValue: chosenPaymentMethodInfo["chosenPaymentMethodType"] as! String, fieldName: "chosenPaymentMethodType")
                        if let cardIndex_ = cardIndex {
                            if let creditCard = chosenPaymentMethodInfo["creditCard"] as? [String: AnyObject] {
                                //TODO: integrate this for multiple cc
                                checkCreditCardInfo(expectedCreditCardInfo: expectedCreditCardInfo[cardIndex_], resultData: creditCard)
                            } else {
                                NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'creditCard' or 'billingContactInfo'")
                                resultError = .unknown
                            }
                        }

                    } else {
                        NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'chosenPaymentMethod'")
                        resultError = .unknown
                    }
                }
                
                // all other flows that includes payment- regular checkout and create payment 
                else{ //TODO: change this to support other payment method
                    if let lastPaymentInfo = jsonData["lastPaymentInfo"] as? [String: AnyObject] {
                        checkFieldContent(expectedValue: "CC", actualValue: lastPaymentInfo["paymentMethod"] as! String, fieldName: "paymentMethod")

                    } else {
                        NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'lastPaymentInfo'")
                        resultError = .unknown
                    }
                
                }
                
            } else {
                NSLog("Error parsing BS result on Retrieve vaulted shopper")
                resultError = .unknown
            }
        } catch let error as NSError {
            NSLog("Error parsing BS result on Retrieve vaulted shopper: \(error.localizedDescription)")
            resultError = .unknown
        }
        
        return resultError
        
    }
    
    static func checkCreateSubscriptionResponse(responseBody: Data, sdkRequest: BSSdkRequest, expectedCreditCardInfo: (String,String,String,String), shippingSameAsBilling: Bool = false) -> BSErrors? {
        var resultError: BSErrors? = nil
        do {
            // Parse the result JSOn object
            if let jsonData = try JSONSerialization.jsonObject(with: responseBody, options: .allowFragments) as? [String: AnyObject] {
                checkFieldContent(expectedValue: "ACTIVE", actualValue: jsonData["status"] as! String, fieldName: "status")
                
                if let paymentSources = jsonData["paymentSource"] as? [String: AnyObject] {
                    if let creditCardInfo = paymentSources["creditCardInfo"] as? [String: Any] {
                        
                        if let creditCard = creditCardInfo["creditCard"] as? [String: AnyObject], let billingContactInfo = creditCardInfo["billingContactInfo"] as? [String: AnyObject] {
                            checkShopperInfo(sdkRequest: sdkRequest, resultData: billingContactInfo, isBilling: true)
                            checkCreditCardInfo(expectedCreditCardInfo: expectedCreditCardInfo, resultData: creditCard)
                            
                        } else {
                            NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'creditCard' or 'billingContactInfo'")
                            resultError = .unknown
                        }
                        
                    } else {
                        NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'creditCardInfo'")
                        resultError = .unknown
                    }
                    
                } else {
                    NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'paymentSource'")
                    resultError = .unknown
                }
                
                // add this when the server bug is fixed
//                if sdkRequest.shopperConfiguration.withShipping {
//                    if let shippingContactInfo = jsonData["shippingContactInfo"] as? [String: AnyObject] {
//                        checkShopperInfo(sdkRequest: sdkRequest, resultData: shippingContactInfo, isBilling: shippingSameAsBilling)
//                    } else {
//                        NSLog("Error parsing BS result on Retrieve vaulted shopper- Missing 'shippingContactInfo'")
//                        resultError = .unknown
//                    }
//                }
                
            } else {
                NSLog("Error parsing BS result on Retrieve vaulted shopper")
                resultError = .unknown
            }
        } catch let error as NSError {
            NSLog("Error parsing BS result on Retrieve vaulted shopper: \(error.localizedDescription)")
            resultError = .unknown
        }
        
        return resultError
        
    }
    
    static func checkCreditCardInfo(expectedCreditCardInfo: (String,String,String,String), resultData: [String: AnyObject]) {
        checkFieldContent(expectedValue: expectedCreditCardInfo.0 , actualValue: resultData["cardLastFourDigits"] as! String, fieldName: "cardLastFourDigits")
        checkFieldContent(expectedValue: expectedCreditCardInfo.1, actualValue: resultData["cardType"] as! String, fieldName: "cardType")
        checkFieldContent(expectedValue: expectedCreditCardInfo.2, actualValue: resultData["expirationMonth"] as! String, fieldName: "expirationMonth")
        checkFieldContent(expectedValue: expectedCreditCardInfo.3, actualValue: resultData["expirationYear"] as! String, fieldName: "expirationYear")
    }
    
    static func checkShopperInfo(sdkRequest: BSSdkRequest, resultData: [String: AnyObject], isBilling: Bool) {
//        let address = "address1"
        let fullInfo = (isBilling && sdkRequest.shopperConfiguration.fullBilling) || !isBilling
        let shopperInfo = isBilling ? sdkRequest.shopperConfiguration.billingDetails! : sdkRequest.shopperConfiguration.shippingDetails!
        let country = shopperInfo.country!
        
        let (firstName, lastName) = shopperInfo.getSplitName()!

        checkFieldContent(expectedValue: firstName, actualValue: resultData["firstName"] as! String, fieldName: "firstName")
        checkFieldContent(expectedValue: lastName, actualValue: resultData["lastName"] as! String, fieldName: "lastName")
        checkFieldContent(expectedValue: country.lowercased(), actualValue: resultData["country"] as! String, fieldName: "country")
        
        if (checkCountryHasZip(country: country)){
            checkFieldContent(expectedValue: shopperInfo.zip!, actualValue: resultData["zip"] as! String, fieldName: "zip")
        }
        
        if (fullInfo){ //full billing or shipping
            if (checkCountryHasState(country: country)){
                checkFieldContent(expectedValue: shopperInfo.state!, actualValue: resultData["state"] as! String, fieldName: "state")
            }
            checkFieldContent(expectedValue: shopperInfo.city!, actualValue: resultData["city"] as! String, fieldName: "city")
            checkFieldContent(expectedValue: shopperInfo.address!, actualValue: resultData["address1"] as! String, fieldName: "address")
        }
        
    }
    
    static func checkFieldContent(expectedValue: String, actualValue: String, fieldName: String) {
        XCTAssertEqual(expectedValue, actualValue, "Field \(fieldName) was not saved correctly in DataBase")
    }
    
    static func checkCountryHasState(country: String) -> Bool {
        var countryHasState = false
        
        if country == "US" || country == "CA" || country == "BR" {
            countryHasState =  true
        }
        
        return countryHasState
    }
    
    static func checkCountryHasZip(country: String) -> Bool {
        let countryHasZip = !BSCountryManager.getInstance().countryHasNoZip(countryCode: country)
        return countryHasZip
    }
    
    static func getPayButtonText(sdkRequest: BSSdkRequest, country: String?, state: String?, subscriptionHasPriceDetails: Bool? = nil) -> String{
        
        var amount: Double = sdkRequest.priceDetails.amount.doubleValue
        var payString: String
        
        if let subscriptionHasPriceDetails = subscriptionHasPriceDetails{ // Subscription flow
            payString = "Subscribe"
            if (!subscriptionHasPriceDetails){ // Subscription flow doesn't have amount
                return payString
            }
        } else { // regular flow
            payString = "Pay"
        }
        
        if let countryCode = country, let stateCode = state{
            amount = calcTaxFromCuntryAndState(countryCode: countryCode, stateCode: stateCode, purchaseAmount: sdkRequest.priceDetails.amount.doubleValue)
        }
        
        let result = "\(payString) \(sdkRequest.priceDetails.currency == "USD" ? "$" : sdkRequest.priceDetails.currency ?? "USD") \(amount)"
        
        return result
    }
    
    static func calcTaxFromCuntryAndState(countryCode: String, stateCode: String, purchaseAmount: Double) -> Double {
        var taxPrecent = 0.0
        if (countryCode == "US"){
            taxPrecent = 0.05
            if (stateCode == "NY"){
                taxPrecent = 0.08
            }
        }
            
        else if (countryCode == "CA"){
            taxPrecent = 0.01
        }
        
        let includeTaxAmount = purchaseAmount * (1+taxPrecent)
        
        return includeTaxAmount
    }
    
    static func checkAPayButton(app: XCUIApplication, buttonId: String, expectedPayText: String) {
        
        let payButton = app.buttons[buttonId]
        
        XCTAssertTrue(payButton.exists, "\(buttonId) is not displayed")
        
        let payButtonText = payButton.label
        //        XCTAssert(expectedPayText == payButtonText)
        XCTAssert(payButtonText.contains(expectedPayText), "Pay Button doesn't display the correct text. expected text: \(expectedPayText), actual text: \(payButtonText)")
    }
    
    static func pressBackButton(app: XCUIApplication) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    static func getVisaCard() -> [String: String] {
        return ["ccn": "4111111111111111", "exp": "10/2025", "cvv": "111", "ccType": "VISA", "last4Digits": "1111", "issuingCountry": "US"]
    }
    
    static func getMasterCard() -> [String: String] {
        return ["ccn": "5555555555555557", "exp": "11/2025", "cvv": "123", "ccType": "MASTERCARD", "last4Digits": "5557", "issuingCountry": "BR"]
    }
    
    static func getDummyBillingDetails(countryCode: String? = "CA", stateCode: String? = "ON") -> BSBillingAddressDetails {
        
        let billingDetails = BSBillingAddressDetails(email: "shevie@gmail.com", name: "Shevie Chen", address: "58 somestreet", city : "somecity", zip : "4282300", country : countryCode, state : stateCode)
        return billingDetails
    }
    
    static func getDummyShippingDetails(countryCode: String? = "CA", stateCode: String? = "ON") -> BSShippingAddressDetails {
        
        let shippingDetails = BSShippingAddressDetails(name: "Funny Brice", address: "77 Rambla street", city : "Barcelona", zip : "4815", country : countryCode, state : stateCode)
        return shippingDetails
    }
    
    static func getDummyEditBillingDetails(countryCode: String? = "US", stateCode: String? = "NY") -> BSBillingAddressDetails {
        
        let billingDetails = BSBillingAddressDetails(email: "test@sdk.com", name: "La Fleur", address: "555 Broadway street", city : "New York", zip : "3abc 324a", country : countryCode, state : stateCode)
        return billingDetails
    }
    
    static func getDummyEditShippingDetails(countryCode: String? = "CA", stateCode: String? = "ON") -> BSShippingAddressDetails {
        
        let shippingDetails = BSShippingAddressDetails(name: "Janet Weiss", address: "75 some street", city : "Denton", zip : "162342", country : countryCode, state : stateCode)
        return shippingDetails
    }
    
    static func getValidVisaCreditCardNumber()->String {
        return "4111 1111 1111 1111"
    }
    
    static func getValidVisaCreditCardNumberWithoutSpaces()->String {
        return "4111111111111111"
    }
    
    static func getValidVisaLast4Digits()->String {
        return "1111"
    }
    
    static func getValidExpDate()->String {
        return "1126"
    }
    
    static func getValidExpYear()->String {
        return "2026"
    }
    
    static func getValidExpMonth()->String {
        return "11"
    }
    
    static func getValidCvvNumber()->String {
        return "333"
    }
    
    static func getValidMCCreditCardNumber()->String {
        return "5572 7588 8601 5288"
    }

    static func getValidMCLast4Digits()->String {
        return "5288"
    }
    
    static func getInvalidCreditCardNumber()->String {
        return "5572 7588 8112 2333"
    }
    
    static func closeKeyboard(app: XCUIApplication, inputToTap: XCUIElement) {
        //        if (!keyboardIsHidden) {
        inputToTap.tap()
//        if (app.keyboards.count > 0) {
//            let doneBtn = app.keyboards.buttons["Done"]
//            if doneBtn.exists && doneBtn.isHittable {
//                doneBtn.tap()
//            }
//        }
    }
    
}

extension XCUIElement {
    func clearText() {
        tap()
        guard let stringValue = self.value as? String else {
            return
        }
        
        var deleteString = String()
        for _ in stringValue {
            deleteString += XCUIKeyboardKey.delete.rawValue
        }
        self.typeText(deleteString)
    }
    
    func typeNewText(_ text: String) {
        tap()
        if let existingText = value as? String, !existingText.isEmpty {
          if existingText != text {
            doubleTap()
          } else {
            return
          }
        }

        typeText(text)
      }
}
