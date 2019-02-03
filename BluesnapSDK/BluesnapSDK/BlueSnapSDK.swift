//
//  BlueSnap.swift
//  BlueSnap
//
//

import Foundation
import PassKit

  open class BlueSnapSDK: NSObject {
	
    // MARK: Supported networks for ApplePay
    
    static let applePaySupportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .discover,
        .masterCard,
        .visa
    ]
    static internal var fraudSessionId : String?
    static internal var sdkRequest : BSSdkRequest?


    // MARK: SDK functions
    
    /**
     Inititalize BlueSnap SDK - this function must be called before any other function in the SDK
     
     - parameters:
     - bsToken: BlueSnap token, should be fresh and valid
     - generateTokenFunc: callback function for generating a new token
     - initKount: true if you want to initialize the Kount device data collection for fraud (recommended: True)
     - fraudSessionId: a unique ID (up to 32 characters) for the shopper session - optional (if empty, a new one is generated)
     - applePayMerchantIdentifier: optional identifier for ApplePay
     - merchantStoreCurrency: base currency code for currency rate calculations
     - completion: callback; will be called when the init process is done. Only then can you proceed to call other functions in the SDK
     */
    open class func initBluesnap(
        bsToken : BSToken!,
        generateTokenFunc: @escaping (_ completion: @escaping (BSToken?, BSErrors?) -> Void) -> Void,
        initKount: Bool,
        fraudSessionId: String?,
        applePayMerchantIdentifier: String?,
        merchantStoreCurrency : String?,
        completion: @escaping (BSErrors?)->Void) {
        
        BSApiManager.setBsToken(bsToken: bsToken)
        BSApiManager.setGenerateBsTokenFunc(generateTokenFunc: generateTokenFunc)
        
        BSApiManager.getSdkData(baseCurrency: merchantStoreCurrency, completion: { sdkData, error in
        
            if let error = error {
                NSLog("Failed to fetch data for Bluesnap SDK. error: \(error)")
		completion(error)
                return
            }
            
            if let sdkData = sdkData {
                if initKount {
                    KountInit(kountMid: sdkData.kountMID! as NSNumber, customFraudSessionId: fraudSessionId)
                }
                if let applePayMerchantIdentifier = applePayMerchantIdentifier {
                    BSApplePayConfiguration.setIdentifier(merchantId: applePayMerchantIdentifier)
                }
                completion(nil)
            } else {
                completion(BSErrors.unknown)
            }

        })
        
    }
    
    /**
     Set the token used for BS API
     This needs to be called when you generate a new token after a token expired (in your generateTokenFunc
     function, which you pass in initBluesnap call abopve)
     
     - parameters:
     - bsToken: BlueSnap token, should be fresh and valid
     */
    open class func setBsToken(bsToken : BSToken!) {
        
        BSApiManager.setBsToken(bsToken: bsToken)
    }
    
    /**
     Start the BlueSnap checkout flow
     
     - parameters:
     - inNavigationController: your viewController's navigationController (to be able to navigate back)
     - animated: how to navigate to the new screen
     - sdkRequest: initial payment details + flow settings
     */
    open class func showCheckoutScreen(
        inNavigationController: UINavigationController!,
        animated: Bool,
        sdkRequest : BSSdkRequest!) {
        
        self.sdkRequest = sdkRequest
        adjustSdkRequest()
        
        DispatchQueue.main.async {
            BSViewsManager.showStartScreen(inNavigationController: inNavigationController,
                                           animated: animated)
        }
    }
    
    /**
    Submit data to BLS server under the current token, to be used later for server-to-server actions
    */
    open class func submitTokenizedDetails(tokenizeRequest: BSTokenizeRequest, completion: @escaping ([String:String], BSErrors?) -> Void) {
        BSApiManager.submitTokenizedDetails(tokenizeRequest: tokenizeRequest, completion: completion)
    }
    
//    /**
//     Submit Payment token fields
//     If you do not want to use our check-out page, you can implement your own.
//     You need to generate a token, and then call this function to submit the CC details to BlueSnap instead of returning them to your server (which is less secure) and then passing them to BlueSnap when you create the transaction.
//     - parameters:
//     - ccNumber: Credit card number
//     - expDate: CC expiration date in format MM/YYYY
//     - cvv: CC security code (CVV)
//     - purchaseDetails: optional purchase details to be tokenized as well as the CC details
//     - completion: callback with either result details if OK, or error details if not OK
//     */
//    open class func submitCcDetails(ccNumber: String, expDate: String, cvv: String, purchaseDetails: BSCcSdkResult?, completion : @escaping (BSCreditCard,BSErrors?)->Void) {
//        
//        BSApiManager.submitPurchaseDetails(ccNumber: ccNumber, expDate: expDate, cvv: cvv, last4Digits: nil, cardType: nil, billingDetails: purchaseDetails?.billingDetails, shippingDetails: purchaseDetails?.shippingDetails, fraudSessionId: BlueSnapSDK.fraudSessionId, completion: completion)
//    }
    
    /**
     Return a list of currencies and their rates from BlueSnap server
     The list is updated when calling initBluesnap
     */
    open class func getCurrencyRates() -> BSCurrencies? {
        return BSApiManager.bsCurrencies
    }

    /**
     Navigate to the currency list, allow changing current selection.
     
     - parameters:
     - inNavigationController: your viewController's navigationController (to be able to navigate back)
     - animated: how to navigate to the new screen
     - selectedCurrencyCode: 3 characters of the current language code (uppercase)
     - updateFunc: callback; will be called each time a new value is selected
     - errorFunc: callback; will be called if we fail to get the currencies
     */
    open class func showCurrencyList(
        inNavigationController: UINavigationController!,
        animated: Bool,
        selectedCurrencyCode : String!,
        updateFunc: @escaping (BSCurrency?, BSCurrency?)->Void,
        errorFunc: @escaping()->Void) {
        
        BSViewsManager.showCurrencyList(inNavigationController: inNavigationController, animated: animated, selectedCurrencyCode: selectedCurrencyCode, updateFunc: updateFunc, errorFunc: errorFunc)
    }
    
    
    /**
     Fetch the merchant's supported Payment Methods
     - parameters:
     - completion: function to call once the data is fetched; will receive optional list of strings that are the payment methods, and optional error.
    */
    static func getSupportedPaymentMethods(completion: @escaping ([String]?, BSErrors?) -> Void) {
        
        BSApiManager.getSupportedPaymentMethods(completion: completion)
    }

    /**
    Check if ApplePay is available
    */
    open class func applePaySupported(supportedPaymentMethods: [String]?,
                                      supportedNetworks: [PKPaymentNetwork]) -> (canMakePayments: Bool, canSetupCards: Bool) {
        
        if #available(iOS 10, *) {
            
            let isSupportedByBS = BSApiManager.isSupportedPaymentMethod(paymentType: BSPaymentType.ApplePay, supportedPaymentMethods: supportedPaymentMethods)
            if isSupportedByBS {
                return (PKPaymentAuthorizationController.canMakePayments(),
                        PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks));
            }
        }

        return (canMakePayments: false, canSetupCards: false)
    }

    
    // MARK: Utility functions for quick testing
    
    /**
     Create token for BlueSnap Sandbox environment; useful for tests.
     In your real app, the token should be generated on the server side and passed to the app, so that the app will not expose the username/password
     - parameters:
     - completion: function to be called once we have the server result; will receive optional token and optional error
    */
    open class func createSandboxTestToken(completion: @escaping (BSToken?, BSErrors?) -> Void) {
        BSApiManager.createSandboxBSToken(shopperId: nil, completion: completion)
    }
    
    /**
     Create token for BlueSnap Sandbox environment; useful for tests.
     In your real app, the token should be generated on the server side and passed to the app, so that the app will not expose the username/password
     - parameters:
     - shopperId: for returning shopper
     - completion: function to be called once we have the server result; will receive optional token and optional error
     */
    open class func createSandboxTestTokenWithShopperId(shopperId: Int?, completion: @escaping (BSToken?, BSErrors?) -> Void) {
        BSApiManager.createSandboxBSToken(shopperId: shopperId, completion: completion)
    }

//    /**
//    Objective C helper method for returning sandbox token
//    */
//      open class func createSandboxTestTokenOrNil() -> BSToken? {
//        do {
//            return try BSApiManager.createSandboxBSToken()!
//        } catch let error {
//            NSLog("Error creating token: \(error.localizedDescription)")
//            return nil
//        }
//    }

    
    // MARK: Private functions
    
    /**
     Call Kount SDK to initialize device data collection in a background thread
     - parameters:
     - kountMid: if you have your own Kount MID, send it here; otherwise leave empty
     - fraudSessionID: this unique ID per shopper should be sent later to BlueSnap when creating the transaction
     */
    private static func KountInit(kountMid: NSNumber? , customFraudSessionId : String?) {
        
        if customFraudSessionId != nil {
            BlueSnapSDK.fraudSessionId = customFraudSessionId!
        } else {
            BlueSnapSDK.fraudSessionId = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        
        //// Configure the Data Collector
        //KDataCollector.shared().debug = true
        if (kountMid != nil) {
            KDataCollector.shared().merchantID = kountMid!.intValue
        } else {
            KDataCollector.shared().merchantID = 700000
        }
        // Optional Set the location collection configuration
        KDataCollector.shared().locationCollectorConfig = KLocationCollectorConfig.passive
        
        if BSApiManager.isProductionToken() {
            KDataCollector.shared().environment = KEnvironment.production
        } else {
            KDataCollector.shared().environment = KEnvironment.test
        }
        NSLog("Kount session ID")
        if let fraudSessionId = BlueSnapSDK.fraudSessionId {
            KDataCollector.shared().collect(forSession: fraudSessionId) { (sessionID, success, error) in
                if success {
                    NSLog("Kount collection success")
                } else {
                    NSLog("Kount collection failed")
                }
            }
        }
    }

    private class func adjustSdkRequest() {
        
        if let data = sdkRequest {
            
            let defaultCountry = NSLocale.current.regionCode ?? BSCountryManager.US_COUNTRY_CODE
            
            if data.withShipping {
                if data.shippingDetails == nil {
                    data.shippingDetails = BSShippingAddressDetails()
                }
            } else if data.shippingDetails != nil {
                data.shippingDetails = nil
            }
            
            if data.billingDetails == nil {
                data.billingDetails = BSBillingAddressDetails()
            }
            
            if data.billingDetails!.country ?? "" == "" {
                data.billingDetails!.country = defaultCountry
            }
        }
    }
    
}

public class BSApplePayConfiguration {

    internal static var identifier: String? = nil

    public static func setIdentifier(merchantId: String!) {
        identifier = merchantId;
    }

    public static func getIdentifier() -> String! {
        return identifier
    }

}
