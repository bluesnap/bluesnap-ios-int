//
//  BSCcInputLine.swift
//  BluesnapSDK
//
//  Created by Shevie Chen on 22/05/2017.
//  Copyright © 2017 Bluesnap. All rights reserved.
//

import UIKit

/**
 This protocol should be implemented by the view which owns the BSCcInputLine control; Although the component's functionality is sort-of self-sufficient, we still have some calls to the parent
 */
public protocol BSCcInputLineDelegate: class {
    /**
     startEditCreditCard is called when we switch to the 'open' state of the component
    */
    func startEditCreditCard()
    /**
     startEditCreditCard is called when we switch to the 'closed' state of the component
     */
    func endEditCreditCard()
    /**
     willCheckCreditCard is called just before calling the BlueSnap server to validate the CCN; since this is a longish asynchronous action, you may want to disable some functionality
     */
    func willCheckCreditCard()
    /**
     didCheckCreditCard is called just after getting the BlueSnap server result; this is where you hide the activity indicator.
     The card type, issuing country etc will be filled in the creditCard if the error is nil, so check the error first.
     */
    func didCheckCreditCard(creditCard: BSCreditCard, error: BSErrors?)
    /**
     didSubmitCreditCard is called at the end of submitPaymentFields() to let the owner know of the submit result; The card type, issuing country etc will be filled in the creditCard if the error is nil, so check the error first.
     */
    func didSubmitCreditCard(creditCard: BSCreditCard, error: BSErrors?)
    /**
     showAlert is called in case of unexpected errors from the BlueSnap server.
     */
    func showAlert(_ message: String)
}

/**
 BSCcInputLine is a Custom control for CC details input (Credit Card number, expiration date and CVV).
 It inherits configurable properties from BSBaseTextInput that let you adjust the look&feel and adds some.
 [We use BSBaseTextInput for the CCN field and image,and add fields for EXP and CVV.]

 The control has 2 states:
 * Open: when we edit the CC number, the field gets longer, EXP and CVV fields are hidden; a 'next' button is shown if the field already has a value
 * Closed: after CCN is entered and validated, the field gets shorter and displays only the last 4 digits; EXP and CVV fields are shown and ediatble; 'next' button is hidden.
*/
@IBDesignable
public class BSCcInputLine: BSBaseTextInput {

    // MARK: Configurable properties

    /**
     showOpenInDesign (default = false) helps you to see the component on the storyboard in both states, open (when you edit the CCN field) or closed (CCn shows only last 4 digits and is not editable, you can edit EXP and CVV fields).
     */
    @IBInspectable var showOpenInDesign: Bool = false {
        didSet {
            if designMode {
                ccnIsOpen = showOpenInDesign
                if ccnIsOpen {
                    setOpenState(before: true, during: true, after: true)
                } else {
                    setClosedState(before: true, during: true, after: true)
                }
            }
        }
    }

    /**
     expPlaceholder (default = "MM/YY") determines the placeholder text for the EXP field
     */
    @IBInspectable var expPlaceholder: String = "MM/YY" {
        didSet {
            self.expTextField.placeholder = expPlaceholder
        }
    }
    /**
     cvvPlaceholder (default = "CVV") determines the placeholder text for the CVV field
     */
    @IBInspectable var cvvPlaceholder: String = "CVV" {
        didSet {
            self.cvvTextField.placeholder = cvvPlaceholder
        }
    }

    /**
     ccnWidth (default = 220) determines the CCN text field width in the 'open' state (value will change at runtime according to the device)
     */
    @IBInspectable var ccnWidth: CGFloat = 220 {
        didSet {
            if designMode {
                resizeElements()
            }
        }
    }
    /**
     last4Width (default = 70) determines the CCN text field width in the 'closed' state, when we show only last 4 digits of the CCN (value will change at runtime according to the device)
     */
    @IBInspectable var last4Width: CGFloat = 70 {
        didSet {
            if designMode {
                resizeElements()
            }
        }
    }
    /**
     expWidth (default = 70) determines the EXP field width (value will change at runtime according to the device)
     */
    @IBInspectable var expWidth: CGFloat = 70 {
        didSet {
            self.actualExpWidth = expWidth
            if designMode {
                resizeElements()
            }
        }
    }
    /**
     cvvWidth (default = 70) determines the CVV field width (value will change at runtime according to the device)
     */
    @IBInspectable var cvvWidth: CGFloat = 70 {
        didSet {
            if designMode {
                resizeElements()
            }
        }
    }
    /**
     nextBtnWidth (default = 20) determines the width of the next button, which shows in the open state when we already have a value in the CCN field (value will change at runtime according to the device)
     */
    @IBInspectable var nextBtnWidth: CGFloat = 22 {
        didSet {
            if designMode {
                resizeElements()
            }
        }
    }
    /**
     nextBtnHeight (default = 22) determines the height of the next button, which shows in the open state when we already have a value in the CCN field (value will change at runtime according to the device)
     */
    @IBInspectable var nextBtnHeight: CGFloat = 22 {
        didSet {
            if designMode {
                resizeElements()
            }
        }
    }
    /**
     nextBtnHeight (default = internal image, looks like >) determines the image for the next button, which shows in the open state when we already have a value in the CCN field (value will change at runtime according to the device)
     */
    @IBInspectable var nextBtnImage: UIImage?


    // MARK: public properties

    /**
     When using this control, you need to implement the BSCcInputLineDelegate protocol, and set the control's delegate to be that class
    */
    public var delegate: BSCcInputLineDelegate?

    var cardType: String = "" {
        didSet {
            updateCcIcon(ccType: cardType)
        }
    }

    /**
    ccnIsOpen indicated the state of the control (open or closed)
    */
    var ccnIsOpen: Bool = true {
        didSet {
            if designMode {
                self.isEditable = ccnIsOpen ? true : false
                if ccnIsOpen {
                    self.textField.text = ccn
                } else {
                    self.textField.text = BSStringUtils.last4(ccn)
                }
            }
        }
    }


    // MARK: private properties

    internal var expTextField: UITextField = UITextField()
    internal var cvvTextField: UITextField = UITextField()
    private var ccnAnimationLabel: UILabel = UILabel()
    internal var expErrorLabel: UILabel?
    internal var cvvErrorLabel: UILabel?
    private var nextButton: UIButton = UIButton()
    private var showNextButton = false

    private var ccn: String = ""
    private var lastValidateCcn: String = ""
    private var closing = false

    var actualCcnWidth: CGFloat = 220
    var actualLast4Width: CGFloat = 70
    var actualExpWidth: CGFloat = 70
    var actualCvvWidth: CGFloat = 70
    var actualErrorWidth: CGFloat = 150
    var actualNextBtnWidth: CGFloat = 22
    var actualNextBtnHeight: CGFloat = 22


    // MARK: Constants

    fileprivate let animationDuration = TimeInterval(0.4)


    // MARK: UIView override functions

    // called at design time (StoryBoard) to init the component
    override init(frame: CGRect) {

        super.init(frame: frame)
        updateCcIcon(ccType: "")
    }

    // called at runtime to init the component
    required public init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
    }

    // MARK: Public functions

    /**
     reset sets the component to its initial state, where the fields are emnpty and we are in the 'open' state
    */
    public func reset() {
        closing = false
        showNextButton = false
        hideError()
        textField.text = ""
        expTextField.text = ""
        cvvTextField.text = ""
        updateCcIcon(ccType: "")
        ccn = ""
        openCcn(animated: false)
    }

    /**
     This should be called when you try to navigate away from the current view; it bypasses validations so that the fields will resign first responder
    */
    public func closeOnLeave() {
        closing = true
    }

    /**
     The EXP field contains the expiration date in format MM/YY. This function returns the expiration date in format MMYYYY
    */
    public func getExpDateAsMMYYYY() -> String! {

        let newValue = self.expTextField.text ?? ""
        if let p = newValue.firstIndex(of: "/") {
            let mm = newValue[..<p]
            let yy = BSStringUtils.removeNoneDigits(String(newValue[p..<newValue.endIndex]))
            let currentYearStr = String(BSValidator.getCurrentYear())
            let p1 = currentYearStr.index(currentYearStr.startIndex, offsetBy: 2)
            let first2Digits = currentYearStr[..<p1]
            return "\(mm)/\(first2Digits)\(yy)"
        }
        return ""
    }

    /**
     Returns the CCN value
    */
    override public func getValue() -> String! {
        if self.ccnIsOpen {
            return self.textField.text
        } else {
            return ccn
        }
    }

    /**
     Sets the CCN value
     */
    override public func setValue(_ newValue: String!) {
        ccn = newValue
        if self.ccnIsOpen {
            self.textField.text = ccn
        }
    }

    /**
     Returns the CVV value
     */
    public func getCvv() -> String! {
        return self.cvvTextField.text ?? ""
    }

    /**
     Returns the CC Type
     */
    public func getCardType() -> String! {
        return cardType
    }

    /**
     Validated the 3 fields; returns true if all are OK; displays errors under the fields if not.
     */
    public func validate() -> Bool {

        let ok1 = validateCCN()
//        let ok2 = validateExp(ignoreIfEmpty: false)
        let ok2 = true
        let ok3 = validateCvv(ignoreIfEmpty: false)
        let result = ok1 && ok2 && ok3

        return result
    }

    /**
     Submits the CCN to BlueSnap server; This lets us get the CC issuing country and card type from server, while validating the CCN
     */
    public func checkCreditCard(ccn: String) {

        if validateCCN() {

            self.closeCcn(animated: true)
            self.delegate?.willCheckCreditCard()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                BSApiManager.submitCcn(ccNumber: ccn, completion: { (creditCard, error) in

                    // Check for error
                    if let error = error {
                        if (error == .invalidCcNumber) {
                            DispatchQueue.main.async {
                                self.showError(BSValidator.ccnInvalidMessage)
                            }
                        } else {
                            var message = BSLocalizedStrings.getString(BSLocalizedString.Error_General_CC_Validation_Error)
                            if (error == .cardTypeNotSupported) {
                                message = BSLocalizedStrings.getString(BSLocalizedString.Error_Card_Type_Not_Supported_1) + BSLocalizedStrings.getString(BSLocalizedString.Error_Card_Type_Not_Supported_2)
                                DispatchQueue.main.async {
                                    self.showError(BSValidator.ccnInvalidMessage)
                                }
                            }
                            DispatchQueue.main.async {
                                self.delegate?.showAlert(message)
                            }
                        }
                    } else {
                        self.cardType = creditCard.ccType ?? ""
                    }
                    DispatchQueue.main.async {
                        self.delegate?.didCheckCreditCard(creditCard: creditCard, error: error)
                    }
                })
            })
        }
    }

    /**
     This should be called by the 'Pay' button - it submits all the CC details to BlueSnap server, so that later purchase requests to BlueSnap will not need gto contain these values (they will be automatically identified by the token).
     In case of errors from the server (there may be validations we did not catch before), we show the errors under the matching fields.
     After getting the result, we call the delegate's didSubmitCreditCard function.
     - parameters:
     - purchaseDetails: optional purchase details to be tokenized as well as the CC details
    */
    public func submitPaymentFields(purchaseDetails: BSCcSdkResult?, _ cardinalCompletion: @escaping (String, BSCreditCard, BSErrors?) -> Void) {

        let ccn = self.getValue() ?? ""
        let cvv = self.getCvv() ?? ""
        let exp = self.getExpDateAsMMYYYY() ?? ""

        BSApiManager.submitPurchaseDetails(ccNumber: ccn, expDate: exp, cvv: cvv, last4Digits: nil, cardType: nil, billingDetails: purchaseDetails?.billingDetails, shippingDetails: purchaseDetails?.shippingDetails, storeCard: purchaseDetails?.storeCard, fraudSessionId: BlueSnapSDK.fraudSessionId, completion: {
            creditCard, error in

            if let error = error {
                if (error == .invalidCcNumber) {
                    self.showError(BSValidator.ccnInvalidMessage)
                } else if (error == .invalidExpDate) {
                    self.showExpError(BSValidator.expInvalidMessage)
                } else if (error == .invalidCvv) {
                    self.showCvvError(BSValidator.cvvInvalidMessage)
                } else if (error == .expiredToken) {
                    let message = BSLocalizedStrings.getString(BSLocalizedString.Error_Cc_Submit_Token_expired)
                    DispatchQueue.main.async {
                        self.delegate?.showAlert(message)
                    }
                } else if (error == .tokenNotFound) {
                    let message = BSLocalizedStrings.getString(BSLocalizedString.Error_Cc_Submit_Token_not_found)
                    DispatchQueue.main.async {
                        self.delegate?.showAlert(message)
                    }
                } else {
                    NSLog("Unexpected error submitting Payment Fields to BS")
                    let message = BSLocalizedStrings.getString(BSLocalizedString.Error_General_CC_Submit_Error)
                    DispatchQueue.main.async {
                        self.delegate?.showAlert(message)
                    }
                }
            }

            defer {
                if (purchaseDetails!.isShopperRequirements()) { // shopper configuration
                    BSApiManager.shopper?.chosenPaymentMethod = BSChosenPaymentMethod(chosenPaymentMethodType: BSPaymentType.CreditCard.rawValue)
                    BSApiManager.shopper?.chosenPaymentMethod?.creditCard = creditCard
                    BSApiManager.updateShopper(completion: {
                        result, error in

                        if let error = error {
                            if (error == .expiredToken) {
                                let message = BSLocalizedStrings.getString(BSLocalizedString.Error_Cc_Submit_Token_expired)
                                DispatchQueue.main.async {
                                    self.delegate?.showAlert(message)
                                }
                            } else if (error == .tokenNotFound) {
                                let message = BSLocalizedStrings.getString(BSLocalizedString.Error_Cc_Submit_Token_not_found)
                                DispatchQueue.main.async {
                                    self.delegate?.showAlert(message)
                                }
                            } else {
                                NSLog("Unexpected error submitting Payment Fields to BS")
                                let message = BSLocalizedStrings.getString(BSLocalizedString.Error_General_CC_Submit_Error)
                                DispatchQueue.main.async {
                                    self.delegate?.showAlert(message)
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            self.delegate?.didSubmitCreditCard(creditCard: creditCard, error: error)
                        }
                    })
                } else { // regular cc checkout
                    if let purchaseDetailsR = purchaseDetails {
                        if (BlueSnapSDK.sdkRequestBase?.activate3DS ?? false){
                            cardinalCompletion(ccn, creditCard, error)
                            
                        } else {
                            DispatchQueue.main.async {
                                self.delegate?.didSubmitCreditCard(creditCard: creditCard, error: error)
                            }
                        }
                    }


                    
                    
                }
            }
        })
    }

    override public func dismissKeyboard() {

        if self.textField.isFirstResponder {
            self.textField.resignFirstResponder()
        } else if self.expTextField.isFirstResponder {
            self.expTextField.resignFirstResponder()
        } else if self.cvvTextField.isFirstResponder {
            self.cvvTextField.resignFirstResponder()
        }
    }


    // MARK: BSBaseTextInput Override functions

    override func initRatios() -> (hRatio: CGFloat, vRatio: CGFloat) {

        let ratios = super.initRatios()

        // keep proportion of image
        let imageRatio = min(ratios.hRatio, ratios.vRatio)
        actualNextBtnWidth = (nextBtnWidth * imageRatio).rounded()
        actualNextBtnHeight = (nextBtnHeight * imageRatio).rounded()

        actualCcnWidth = (ccnWidth * ratios.hRatio).rounded()
        actualLast4Width = (last4Width * ratios.hRatio).rounded()
        actualExpWidth = (expWidth * ratios.hRatio).rounded()
        actualCvvWidth = (cvvWidth * ratios.hRatio).rounded()
        actualErrorWidth = self.frame.width / 3
        return ratios
    }

    override func buildElements() {

        super.buildElements()

        self.textField.accessibilityIdentifier = "CcTextField"
        self.expTextField.accessibilityIdentifier = "ExpTextField"
        self.cvvTextField.accessibilityIdentifier = "CvvTextField"
        ccnAnimationLabel.accessibilityIdentifier = "last4digitsLabel"
        nextButton.accessibilityIdentifier = "NextButton"

        self.textField.delegate = self
        self.addSubview(expTextField)
        self.expTextField.delegate = self
        self.addSubview(cvvTextField)
        self.cvvTextField.delegate = self
        if let fieldCoverButton = fieldCoverButton {
            self.insertSubview(ccnAnimationLabel, belowSubview: fieldCoverButton)
        } else {
            self.addSubview(ccnAnimationLabel)
        }

        fieldKeyboardType = .numberPad

        expTextField.addTarget(self, action: #selector(BSCcInputLine.expFieldDidBeginEditing(_:)), for: .editingDidBegin)
        expTextField.addTarget(self, action: #selector(BSCcInputLine.expFieldEditingChanged(_:)), for: .editingChanged)

        cvvTextField.addTarget(self, action: #selector(BSCcInputLine.cvvFieldDidBeginEditing(_:)), for: .editingDidBegin)
        cvvTextField.addTarget(self, action: #selector(BSCcInputLine.cvvFieldEditingChanged(_:)), for: .editingChanged)

        expTextField.textAlignment = .center
        cvvTextField.textAlignment = .center

        setNumericKeyboard()

        setButtonImage()
    }

    override func setElementAttributes() {

        super.setElementAttributes()

        expTextField.keyboardType = .numberPad
        expTextField.backgroundColor = self.fieldBkdColor
        expTextField.textColor = self.textColor
        expTextField.returnKeyType = UIReturnKeyType.done
        expTextField.borderStyle = .none
        expTextField.placeholder = expPlaceholder

        cvvTextField.keyboardType = .numberPad
        cvvTextField.backgroundColor = self.fieldBkdColor
        cvvTextField.textColor = self.textColor
        cvvTextField.returnKeyType = UIReturnKeyType.done
        cvvTextField.borderStyle = .none
        cvvTextField.placeholder = cvvPlaceholder

        cvvTextField.borderStyle = textField.borderStyle
        expTextField.borderStyle = textField.borderStyle
        cvvTextField.layer.borderWidth = fieldBorderWidth
        expTextField.layer.borderWidth = fieldBorderWidth

        if let fieldBorderColor = self.fieldBorderColor {
            cvvTextField.layer.borderColor = fieldBorderColor.cgColor
            expTextField.layer.borderColor = fieldBorderColor.cgColor
        }
    }

    override func resizeElements() {

        super.resizeElements()

        expTextField.font = textField.font
        cvvTextField.font = textField.font

        if ccnIsOpen == true {
            expTextField.alpha = 0
            cvvTextField.alpha = 0
        } else {
            expTextField.alpha = 1
            cvvTextField.alpha = 1
        }

        let fieldEndX = getFieldX() + self.actualLast4Width
        let cvvFieldX = self.frame.width - actualCvvWidth - self.actualRightMargin
        let expFieldX = (fieldEndX + cvvFieldX - actualExpWidth) / 2.0
        let fieldY = (self.frame.height - actualFieldHeight) / 2
        expTextField.frame = CGRect(x: expFieldX, y: fieldY, width: actualExpWidth, height: actualFieldHeight)
        cvvTextField.frame = CGRect(x: cvvFieldX, y: fieldY, width: actualCvvWidth, height: actualFieldHeight)

        adjustNextButton()

        if fieldCornerRadius != 0 {
            cvvTextField.layer.cornerRadius = fieldCornerRadius
            expTextField.layer.cornerRadius = fieldCornerRadius
        }

        self.ccnAnimationLabel.font = self.textField.font
        let labelWidth = self.ccnIsOpen ? actualCcnWidth : actualLast4Width
        self.ccnAnimationLabel.frame = CGRect(x: self.textField.frame.minX, y: self.textField.frame.minY, width: labelWidth, height: self.textField.frame.height)
        self.ccnAnimationLabel.alpha = self.ccnIsOpen ? 0 : 1
    }

    override func getImageRect() -> CGRect {
        return CGRect(x: actualRightMargin, y: (self.frame.height - actualImageHeight) / 2, width: actualImageWidth, height: actualImageHeight)
    }

    override func getFieldWidth() -> CGFloat {
        return actualCcnWidth
    }

    override func getFieldX() -> CGFloat {
        let fieldX = actualLeftMargin + actualImageWidth + actualMiddleMargin
        return fieldX
    }

    override func resizeError() {

        let labelFont = UIFont(name: self.fontName, size: actualErrorFontSize)

        if let errorLabel = errorLabel {
            if labelFont != nil {
                errorLabel.font = labelFont
            }
            errorLabel.textAlignment = .left
            let x: CGFloat = actualLeftMargin
            errorLabel.frame = CGRect(x: x, y: self.frame.height - actualErrorHeight, width: actualErrorWidth, height: actualErrorHeight)
        }
        if let expErrorLabel = expErrorLabel {
            if labelFont != nil {
                expErrorLabel.font = labelFont
            }
            expErrorLabel.textAlignment = .center
            let fieldCenter: CGFloat! = expTextField.frame.minX + expTextField.frame.width / 2.0
            let x = fieldCenter - actualErrorWidth / 2.0
            expErrorLabel.textAlignment = .center
            expErrorLabel.frame = CGRect(x: x, y: self.frame.height - actualErrorHeight, width: actualErrorWidth, height: actualErrorHeight)
        }
        if let cvvErrorLabel = cvvErrorLabel {
            if labelFont != nil {
                cvvErrorLabel.font = labelFont
            }
            cvvErrorLabel.textAlignment = .right
            let x = self.frame.width - rightMargin - actualErrorWidth
            cvvErrorLabel.textAlignment = .right
            cvvErrorLabel.frame = CGRect(x: x, y: self.frame.height - actualErrorHeight, width: actualErrorWidth, height: actualErrorHeight)
        }

    }

    // MARK: TextFieldDelegate functions

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    /**
     This handler is called when one of the text fields is about to end editing; we perform validation,
     ignoring empty values, but allow exiting the field even if there is an error.
    */
    func textFieldShouldEndEditing(_ sender: UITextField) -> Bool {

        if closing {
            closing = false
            return true
        }
        if sender == self.textField {
            if ccnIsOpen {
                ccn = self.textField.text!
                if lastValidateCcn == self.textField.text {
                    self.closeCcn(animated: true)
                } else {
                    self.lastValidateCcn = self.ccn
                    self.checkCreditCard(ccn: ccn)
                }
            }
        } else if sender == self.expTextField {
//            _ = validateExp(ignoreIfEmpty: true)
        } else if sender == self.cvvTextField {
            _ = validateCvv(ignoreIfEmpty: true)
        }
        return true
    }

    // MARK: Numeric Keyboard 'done' button enhancement

    override internal func setNumericKeyboard() {

        let viewForDoneButtonOnKeyboard = createDoneButtonForKeyboard()
        self.textField.inputAccessoryView = viewForDoneButtonOnKeyboard
        self.expTextField.inputAccessoryView = viewForDoneButtonOnKeyboard
        self.cvvTextField.inputAccessoryView = viewForDoneButtonOnKeyboard
    }


    // MARK: extra error handling

    /*
     Shows the given text as an error below the exp text field
     */
    public func showExpError(_ errorText: String?) {

        if expErrorLabel == nil {
            expErrorLabel = UILabel()
            expErrorLabel!.accessibilityIdentifier = "ExpErrorLabel"
            initErrorLabel(errorLabel: expErrorLabel)
        }
        showErrorByField(field: self.expTextField, errorLabel: expErrorLabel, errorText: errorText)
    }

    /*
     Shows the given text as an error below the exp text field
     */
    public func showCvvError(_ errorText: String?) {

        if cvvErrorLabel == nil {
            cvvErrorLabel = UILabel()
            cvvErrorLabel!.accessibilityIdentifier = "CvvErrorLabel"
            initErrorLabel(errorLabel: cvvErrorLabel)
        }
        showErrorByField(field: self.cvvTextField, errorLabel: cvvErrorLabel, errorText: errorText)
    }

    func hideExpError() {

        hideErrorByField(field: expTextField, errorLabel: expErrorLabel)
    }

    func hideCvvError() {

        hideErrorByField(field: cvvTextField, errorLabel: cvvErrorLabel)
    }


    // MARK: focus on fields

    func focusOnCcnField() {
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                if self.ccnIsOpen == true {
                    self.textField.becomeFirstResponder()
                }
            }
        }
    }

    func focusOnExpField() {
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                if self.ccnIsOpen == false {
                    self.expTextField.becomeFirstResponder()
                }
            }
        }
    }

    func focusOnCvvField() {
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                if self.ccnIsOpen == false {
                    self.cvvTextField.becomeFirstResponder()
                }
            }
        }
    }

    func focusOnNextField() {
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                let nextTage = self.tag + 1;
                let nextResponder = self.superview?.viewWithTag(nextTage) as? BSBaseTextInput
                if nextResponder != nil {
                    nextResponder?.textField.becomeFirstResponder()
                }
            }
        }
    }


    // MARK: event handlers

    override func fieldCoverButtonTouchUpInside(_ sender: Any) {

        openCcn(animated: true)
    }

    override public func textFieldDidBeginEditing(_ sender: UITextField) {
        //hideError(textField)
    }

    override public func textFieldDidEndEditing(_ sender: UITextField) {
        delegate?.endEditCreditCard()
    }

    override func textFieldEditingChanged(_ sender: UITextField) {

        self.ccn = self.textField.text!
        BSValidator.ccnEditingChanged(textField)

        let ccn = BSStringUtils.removeNoneDigits(textField.text ?? "")
        let ccnLength = ccn.count

        if ccnLength >= 6 {
            cardType = BSValidator.getCCTypeByRegex(textField.text ?? "")?.lowercased() ?? ""
        } else {
            cardType = ""
        }
        let maxLength: Int = BSValidator.getCcLengthByCardType(cardType)
        if checkMaxLength(textField: sender, maxLength: maxLength) == true {
            if ccnLength == maxLength {
                if self.textField.canResignFirstResponder {
                    focusOnExpField()
                }
            }
        }
    }

    @objc func expFieldDidBeginEditing(_ sender: UITextField) {

        //hideError(expTextField)
    }

    @objc func expFieldEditingChanged(_ sender: UITextField) {

        BSValidator.expEditingChanged(sender)
        if checkMaxLength(textField: sender, maxLength: 5) == true {
            if sender.text?.count == 5 {
                if expTextField.canResignFirstResponder {
                    focusOnCvvField()
                }
            }
        }
    }

    @objc func cvvFieldDidBeginEditing(_ sender: UITextField) {

        //hideError(cvvTextField)
    }

    @objc func cvvFieldEditingChanged(_ sender: UITextField) {

        BSValidator.cvvEditingChanged(sender)
        let cvvLength = BSValidator.getCvvLength(cardType: self.cardType)
        if checkMaxLength(textField: sender, maxLength: cvvLength) == true {
            if sender.text?.count == cvvLength {
                if cvvTextField.canResignFirstResponder == true {
                    focusOnNextField()
                }
            }
        }
    }

    @objc func nextArrowClick() {

        if textField.canResignFirstResponder {
            focusOnExpField()
        }
    }

    // MARK: Validation methods

    func validateCCN() -> Bool {

        let result = BSValidator.validateCCN(input: self)
        return result
    }

    func validateExp(ignoreIfEmpty: Bool) -> Bool {

        if ccnIsOpen {
            return true
        }
        var result = true
        if !ignoreIfEmpty || (expTextField.text?.count)! > 0 {
            result = BSValidator.validateExp(input: self)
        }
        return result
    }

    func validateCvv(ignoreIfEmpty: Bool) -> Bool {

        if ccnIsOpen {
            return true
        }
        var result = true
        if !ignoreIfEmpty || (cvvTextField.text?.count)! > 0 {
            result = BSValidator.validateCvv(input: self, cardType: cardType)
        }
        return result
    }

    // private/internal functions

    private func closeCcn(animated: Bool) {

        self.ccnIsOpen = false

        if animated {
            DispatchQueue.main.async {
                self.setClosedState(before: true, during: false, after: false)
                //self.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIView.animate(withDuration: self.animationDuration, animations: {
                    self.setClosedState(before: false, during: true, after: false)
                }, completion: { animate in
                    self.setClosedState(before: false, during: false, after: true)
                })
            }
        } else {
            self.setClosedState(before: true, during: true, after: true)
        }
        self.showNextButton = true // after first close, this will always be true
    }

    private func openCcn(animated: Bool) {
        var canOpen = true
        if cvvTextField.isFirstResponder {
            if !cvvTextField.canResignFirstResponder {
                canOpen = false
            } else {
                //cvvTextField.resignFirstResponder()
            }
        } else if expTextField.isFirstResponder {
            if !expTextField.canResignFirstResponder {
                canOpen = false
            } else {
                //expTextField.resignFirstResponder()
            }
        }
        if canOpen {
            self.hideExpError()
            self.hideCvvError()
            self.ccnIsOpen = true

            if animated {
                DispatchQueue.main.async {
                    self.setOpenState(before: true, during: false, after: false)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIView.animate(withDuration: self.animationDuration, animations: {
                        self.setOpenState(before: false, during: true, after: false)
                    }, completion: { animate in
                        self.setOpenState(before: false, during: false, after: true)
                    })
                }
            } else {
                self.setOpenState(before: true, during: true, after: true)
            }
        }
    }

    func adjustNextButton() {

        let x: CGFloat = self.frame.width - actualRightMargin - actualNextBtnWidth
        let y: CGFloat = (self.frame.height - actualNextBtnHeight) / 2.0
        nextButton.frame = CGRect(x: x, y: y, width: actualNextBtnWidth, height: actualNextBtnHeight)
        if self.ccnIsOpen && (showNextButton || designMode) {
            nextButton.alpha = 1
        } else {
            nextButton.alpha = 0
        }
    }

    private func setButtonImage() {

        var btnImage: UIImage?
        if let img = self.nextBtnImage {
            btnImage = img
        } else {
            btnImage = BSViewsManager.getImage(imageName: "forward_arrow")
        }
        if let img = btnImage {
            nextButton.setImage(img, for: .normal)
            nextButton.contentVerticalAlignment = .fill
            nextButton.contentHorizontalAlignment = .fill
            nextButton.addTarget(self, action: #selector(self.nextArrowClick), for: .touchUpInside)
            self.addSubview(nextButton)
        }
    }


    func updateCcIcon(ccType: String?) {

        // change the image in ccIconImage
        if let image = BSImageLibrary.getCcIconByCardType(ccType: ccType) {
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }

    private func checkMaxLength(textField: UITextField!, maxLength: Int) -> Bool {
        if (BSStringUtils.removeNoneDigits(textField.text!).count > maxLength) {
            textField.deleteBackward()
            return false
        } else {
            return true
        }
    }

    private func closeExpCvv() {

        self.expTextField.frame = CGRect(x: self.expTextField.frame.maxX, y: self.expTextField.frame.minY, width: 0, height: self.expTextField.frame.height)
        self.cvvTextField.frame = CGRect(x: self.cvvTextField.frame.maxX, y: self.cvvTextField.frame.minY, width: 0, height: self.cvvTextField.frame.height)
    }

    private func openExpCvv() {
        self.expTextField.frame = CGRect(x: self.expTextField.frame.maxX - actualExpWidth, y: self.expTextField.frame.minY, width: actualExpWidth, height: self.expTextField.frame.height)
        self.cvvTextField.frame = CGRect(x: self.cvvTextField.frame.maxX - actualCvvWidth, y: self.cvvTextField.frame.minY, width: actualCvvWidth, height: self.cvvTextField.frame.height)

    }

    private func setClosedState(before: Bool, during: Bool, after: Bool) {

        if before {
            closeExpCvv()
            self.ccnAnimationLabel.text = self.ccn
            self.textField.alpha = 0
            self.ccnAnimationLabel.alpha = 1
            //self.layoutIfNeeded()
        }
        if during {
            self.expTextField.alpha = 1
            self.cvvTextField.alpha = 1
            self.ccnAnimationLabel.frame = CGRect(x: self.textField.frame.minX, y: self.textField.frame.minY, width: self.actualLast4Width, height: self.textField.frame.height)
            openExpCvv()
            adjustNextButton()
        }
        if (after) {
            self.ccnAnimationLabel.text = BSStringUtils.last4(ccn)
            self.isEditable = false
            self.adjustCoverButton()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                //self.layoutIfNeeded()
                if !self.expTextField.isFirstResponder {
//                    _ = self.validateExp(ignoreIfEmpty: true)
                }
                if !self.cvvTextField.isFirstResponder {
                    _ = self.validateCvv(ignoreIfEmpty: true)
                }
            }
        }
    }

    override func getCoverButtonWidth() -> CGFloat {
        return actualLast4Width
    }

    private func setOpenState(before: Bool, during: Bool, after: Bool) {

        if before {
            self.ccnAnimationLabel.frame = CGRect(x: self.textField.frame.minX, y: self.textField.frame.minY, width: self.actualLast4Width, height: self.textField.frame.height)
            self.ccnAnimationLabel.alpha = 1
            self.ccnAnimationLabel.text = BSStringUtils.last4(ccn)
            self.textField.alpha = 0
        }
        if during {
            self.expTextField.alpha = 0
            self.cvvTextField.alpha = 0
            self.ccnAnimationLabel.alpha = 1
            self.ccnAnimationLabel.frame = CGRect(x: self.textField.frame.minX, y: self.textField.frame.minY, width: self.actualCcnWidth, height: self.textField.frame.height)
            self.ccnAnimationLabel.text = ccn
            closeExpCvv()
            adjustNextButton()
        }
        if (after) {
            self.ccnAnimationLabel.alpha = 0
            self.textField.alpha = 1
            self.isEditable = true
            self.adjustCoverButton()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                //self.layoutIfNeeded()
                self.delegate?.startEditCreditCard()
                self.focusOnCcnField()
            }
        }
    }


}
