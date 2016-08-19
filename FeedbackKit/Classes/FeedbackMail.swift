//
//  FeedbackMail.swift
//  FeedbackKit
//
//  Created by Mao Nishi on 8/18/16.
//  Copyright © 2016 Mao Nishi. All rights reserved.
//

import Foundation
import MessageUI

class FeedbackMail: NSObject, MFMailComposeViewControllerDelegate {
    
    var mailSendCompletion: (() -> Void)?

    internal func send(emailConfig: Feedback.EmailConfig, sendInformation: SendInformation, callerViewController: UIViewController, mailSendCompletion: (() -> Void)) {
        
        guard MFMailComposeViewController.canSendMail() else {
            let alertController = UIAlertController(title: "error", message: "mail can not use", preferredStyle: UIAlertControllerStyle.Alert)
            callerViewController.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        self.mailSendCompletion = mailSendCompletion
        
        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = self
        mailViewController.setToRecipients(emailConfig.toList)
        if let ccList = emailConfig.ccList {
            mailViewController.setCcRecipients(ccList)
        }
        if let bccList = emailConfig.bccList {
            mailViewController.setBccRecipients(bccList)
        }
        if let subject = emailConfig.mailSubject {
            mailViewController.setSubject(subject)
        } else {
            mailViewController.setSubject("Feedbackmail")
        }
        mailViewController.setMessageBody(sendInformation.feedbackBodyMessage, isHTML: false)
        
        if let captureImageData = sendInformation.captureImageData {
            mailViewController.addAttachmentData(captureImageData, mimeType: "image/png", fileName: "feedback.png")
        }
        
        callerViewController.presentViewController(mailViewController, animated: true, completion: nil)
        
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch result {
        case MFMailComposeResultSent:
            controller.dismissViewControllerAnimated(true, completion: {
                if let mailSendCompletion = self.mailSendCompletion {
                    mailSendCompletion()
                }
            })
        case MFMailComposeResultSaved:
            fallthrough
        case MFMailComposeResultCancelled:
            controller.dismissViewControllerAnimated(true, completion: nil)
        case MFMailComposeResultFailed:
            let alertController = UIAlertController(title: "mail send error", message: "error:\(error)", preferredStyle: UIAlertControllerStyle.Alert)
            controller.presentViewController(alertController, animated: true, completion: nil)
        default:
            break
        }
    }

}