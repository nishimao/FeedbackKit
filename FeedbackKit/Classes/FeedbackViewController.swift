//
//  FeedbackViewController.swift
//  FeedbackKit
//
//  Created by Mao Nishi on 8/15/16.
//  Copyright © 2016 Mao Nishi. All rights reserved.
//

import UIKit
import CoreGraphics

public struct SendInformation {
    public var selectedTitle: String?
    public var comment: String?
    public var captureImage: UIImage?
    public var reporterName: String?
    public var className: String?
    
    public var feedbackBodyMessage: String {
        get {
            var bodyMessage = ""
            if let selectedTitle = selectedTitle {
                bodyMessage =  "Title: [\(selectedTitle)]\n"
            }
            if let comment = comment {
                bodyMessage = bodyMessage + "Comment: [\(comment)]\n"
            }
            if let reporterName = reporterName {
                bodyMessage = bodyMessage + "Reporter: [\(reporterName)]\n"
            }
            if let className = className {
                bodyMessage = bodyMessage + "ClassName: [\(className)]"
            }
            return bodyMessage
        }
    }
    
    public var captureImageData: NSData? {
        get {
            guard let captureImage = captureImage else {
                return nil
            }
            return UIImagePNGRepresentation(captureImage)
        }
    }
}

final public class FeedbackViewController: UIViewController {

    @IBOutlet weak var screenImageView: UIImageView!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var freeCommentTextField: UITextField!
    @IBOutlet weak var reporterField: UITextField!
    
    var reportClassName: String?
    var callerViewController: UIViewController?
    var overlayView: UIView?
    var effectView: UIView?
    var isKeyboardObserving: Bool = false
    var parentView: UIView?
    
    var sendAction: ((feedbackViewController: FeedbackViewController, sendInformation: SendInformation) -> Void)?
    
    var mailSendCompletion: ((feedbackViewController: FeedbackViewController) -> Void)?

    struct FeedbackUseState {
        static var using: Bool = false
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        initialize()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.isKeyboardObserving {
            let notificationCenter = NSNotificationCenter.defaultCenter()
            notificationCenter.addObserver(self, selector: #selector(FeedbackViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(FeedbackViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
            self.isKeyboardObserving = true
        }
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isKeyboardObserving {
            let notificationCenter = NSNotificationCenter.defaultCenter()
            notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
            notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
            
            self.isKeyboardObserving = false
        }
    }
    
    private func initialize() {
        
        if let screenImage = screenshotImage() {
            screenImageView.image = screenImage
        }
        
        if let className = getReportClassName() {
            reportClassName = className
        }
        
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    static func presentFeedbackViewController(viewController: UIViewController, action:((feedbackViewController: FeedbackViewController, sendInformation: SendInformation) -> Void)) {
        
        guard FeedbackUseState.using == false else {
            return
        }
        
        guard let feedbackViewController = instantiateInitialViewController() else {
            return
        }
        FeedbackUseState.using = true
        feedbackViewController.sendAction = action
        feedbackViewController.popupViewController(viewController)
    }

    private static func instantiateInitialViewController() -> FeedbackViewController?  {
        
        struct FeedbackKitStatic {
            static var onceToken: dispatch_once_t = 0
            static var storyboard: UIStoryboard?
        }
        
        // storyboard cache
        dispatch_once(&FeedbackKitStatic.onceToken) {
            let podBundle = NSBundle(forClass: FeedbackViewController.self)
            guard let url = podBundle.URLForResource("FeedbackKit", withExtension: "bundle") else {
                return
            }
            let bundle = NSBundle(URL: url)
            FeedbackKitStatic.storyboard = UIStoryboard(name: "FeedbackKit", bundle: bundle)
            
        }
        return FeedbackKitStatic.storyboard?.instantiateInitialViewController() as? FeedbackViewController
    }

    private func screenshotImage() -> UIImage? {
        let screenSize = UIScreen.mainScreen().bounds.size
        
        UIGraphicsBeginImageContextWithOptions(screenSize, false, 1.0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        let application = UIApplication.sharedApplication()
        application.keyWindow?.layer.renderInContext(context)
        let screenshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshotImage
    }
    
    private func searchReportClass(viewController: UIViewController) -> UIViewController? {
        
        let reportViewController: UIViewController = viewController
        
        if let navigationController = viewController as? UINavigationController {
            if let searchResultViewController = navigationController.viewControllers.last {
                return searchReportClass(searchResultViewController)
            }
        } else if let searchResultViewController = reportViewController.presentedViewController {
            return searchReportClass(searchResultViewController)
        }
        return reportViewController
    }
    
    private func getReportClassName() -> String? {
        guard let reportViewController = UIApplication.sharedApplication().keyWindow?.rootViewController,
            viewController = searchReportClass(reportViewController) else {
            return nil
        }
        return NSStringFromClass(viewController.dynamicType)
    }
    
    private func getParentView(viewController: UIViewController) -> UIView {
        
        // use cache
        if let parentView = self.parentView {
            return parentView
        }
        
        var sourceController: UIViewController = viewController
        while let parent = sourceController.parentViewController {
            sourceController = parent
        }
        self.parentView = sourceController.view
        return sourceController.view
    }
    
    private func popupViewController(viewController: UIViewController) {
        
        self.callerViewController = viewController
        viewController.addChildViewController(self)
        self.didMoveToParentViewController(viewController)
        
        let parentView = getParentView(viewController)
        let popupView = self.view
        popupView.frame = CGRectMake(0, 0, 300, 300)
        
        // validate already add view
        guard !parentView.subviews.contains(popupView) else {
            return
        }
        
        let overlayView = UIView(frame: parentView.bounds)
        self.overlayView = overlayView
        overlayView.backgroundColor = UIColor.clearColor()

        let effectView = EffectView(frame: CGRectMake(0, 0, parentView.bounds.size.width + 30, parentView.bounds.size.height + 30))
        self.effectView = effectView
        effectView.backgroundColor = UIColor.clearColor()
        effectView.alpha = 0
        overlayView.addSubview(effectView)
        
        // add dismiss button
        let dismissButton = UIButton(type: .Custom)
        dismissButton.backgroundColor = UIColor.clearColor()
        dismissButton.frame = overlayView.bounds
        dismissButton.addTarget(self, action: #selector(FeedbackViewController.dismissFeedbackViewController(_:)), forControlEvents: .TouchUpInside)
        
        overlayView.addSubview(dismissButton)
        
        // add popup view
        popupView.layer.shadowPath = UIBezierPath(rect: popupView.bounds).CGPath
        popupView.layer.masksToBounds = false
        popupView.layer.shadowOffset = CGSizeMake(5, 5)
        popupView.layer.shadowRadius = 5
        popupView.layer.shadowOpacity = 0.5
        popupView.layer.shouldRasterize = true
        popupView.layer.rasterizationScale = UIScreen.mainScreen().scale
        overlayView.addSubview(popupView)
        
        // add overlay view
        parentView.addSubview(overlayView)
        
        presentFeedbackViewController(parentView, popupView: popupView, overlayView: overlayView, effectView: effectView)
    }
    
    private func presentFeedbackViewController(parentView: UIView, popupView: UIView, overlayView: UIView, effectView: UIView) {
        let startRect = CGRectMake((parentView.bounds.size.width - popupView.bounds.size.width) / 2,
                                   -popupView.bounds.size.height,
                                   popupView.bounds.size.width,
                                   popupView.bounds.size.height)
        let endRect = CGRectMake((parentView.bounds.size.width - popupView.bounds.size.width) / 2, (parentView.bounds.size.height - popupView.bounds.size.height) / 2, popupView.bounds.size.width, popupView.bounds.size.height)
        popupView.frame = startRect
        
        UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            effectView.alpha = 1.0
            popupView.frame = endRect
        }) { (animation:Bool) in
            
        }
    }
    
    @objc
    private func dismissFeedbackViewController(sender: UIButton) {
        dismissFeedbackViewController()
    }
    
    func dismissFeedbackViewController() {
        
        guard let callerViewController = self.callerViewController,
            overlayView = self.overlayView,
            effectView = self.effectView else {
                return
        }
        
        let popupView = self.view
        let parentView = getParentView(callerViewController)
        
        let endRect = CGRectMake((parentView.bounds.size.width - popupView.bounds.size.width) / 2,
                                 -popupView.bounds.size.height,
                                 popupView.bounds.size.width,
                                 popupView.bounds.size.height)
        
        UIView.animateWithDuration(0.35,
                                   delay: 0,
                                   options: UIViewAnimationOptions.CurveEaseOut,
                                   animations: {
                                    effectView.alpha = 0
                                    popupView.frame = endRect
        }) { (animation:Bool) in
            overlayView.removeFromSuperview()
            
            FeedbackUseState.using = false
        }
    }
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        freeCommentTextField.endEditing(true)
        reporterField.endEditing(true)
    }
}

extension FeedbackViewController {
    
    @IBAction func tapSendButton(sender: AnyObject) {
        
        guard let action = sendAction else {
            return
        }
        
        var sendInformation = SendInformation()
        
        
        if let comment = freeCommentTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
            sendInformation.comment = comment
        }

        if let reporterName = reporterField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
            sendInformation.reporterName = reporterName
        }
        
        let selectedRowIndex = picker.selectedRowInComponent(0)
        if let selectedTitle = pickerView(picker, titleForRow: selectedRowIndex, forComponent: 0) {
            sendInformation.selectedTitle = selectedTitle
        }
        
        if let captureImage = screenImageView.image {
            sendInformation.captureImage = captureImage
        }
        
        if let reportClassName = reportClassName {
            sendInformation.className = reportClassName
        }
        
        // execute send action
        action(feedbackViewController: self, sendInformation: sendInformation)
    }
}

extension FeedbackViewController: UITextFieldDelegate {
    
    func keyboardWillShow(notification: NSNotification) {
        // get keyboard size, keyboard animation duration
        guard let userInfo = notification.userInfo,
            rect = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue(),
            duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue,
            parentView = self.parentView else {
            return
        }
        
        // already moved view
        if self.view.frame.origin.y + (self.view.frame.size.height / 2) < self.parentView?.center.y {
            return
        }
        
        var moveY = -rect.size.height
        
        if self.view.frame.maxY > (parentView.bounds.height - rect.size.height - 50) {
            moveY = (parentView.bounds.height - rect.size.height) - self.view.frame.maxY - 50
        }
        
        // keyboard animation
        UIView.animateWithDuration(duration) {
            let transform = CGAffineTransformMakeTranslation(0, moveY)
            self.view.transform = transform
        }
    }
    
    func keyboardWillHide(notification: NSNotification){
        // get keyboard animation duration
        guard let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue else {
            return
        }
        
        // keyboard animation
        UIView.animateWithDuration(duration) {
            self.view.transform = CGAffineTransformIdentity
        }
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension FeedbackViewController: UIPickerViewDelegate {
    
    public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 6
    }
    
    public func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // store user default
    }
}

extension FeedbackViewController: UIPickerViewDataSource {
    
    public func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch (row) {
            case 0:
                return "表示崩れ"
            case 1:
                return "カクカクする"
            case 2:
                return "バグかも"
            case 3:
                return "使いづらい"
            case 4:
                return "見辛い"
            default:
                return "その他"
        }
    }
}

final class EffectView: UIView {
    
    override func drawRect(rect: CGRect) {
        guard let context: CGContextRef = UIGraphicsGetCurrentContext(),
            colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB() else {
            return
        }
        
        let colors: [CGFloat] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75]
        let locations: [CGFloat] = [0.0, 1.0]
        let locationsCount: size_t = 2
        let gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount)
    
        let center: CGPoint = CGPointMake(bounds.size.width / 2, bounds.size.height / 2)
        
        let radius = min(bounds.size.width, bounds.size.height)
        CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, CGGradientDrawingOptions.DrawsBeforeStartLocation)
    }
}
