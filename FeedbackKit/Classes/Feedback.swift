//
//  Feedback.swift
//  FeedbackKit
//
//  Created by Mao Nishi on 8/17/16.
//  Copyright © 2016 Mao Nishi. All rights reserved.
//

import Foundation
import UIKit

public enum Feedback {

    public class EmailConfig {
        var toList: [String]
        var mailSubject: String?
        var ccList: [String]?
        var bccList: [String]?

        public init(to: String) {
            toList = [to]
        }

        public init(toList: [String], mailSubject: String? = nil, ccList: [String]? = nil, bccList: [String]? = nil) {
            self.toList = toList
            self.mailSubject = mailSubject
            self.ccList = ccList
            self.bccList = ccList
        }
    }

    // feedback by email
    case Email(emailConfig: EmailConfig)

    // feedback by custom action. when custom action was finished successfully, need to call 'success' method.
    case Custom(action: ((feedbackViewController: FeedbackViewController, sendInformation: SendInformation, success:(()->Void)) -> Void))

    public func show(dismissed:(()->Void)) {

        guard let callerViewController = UIApplication.sharedApplication().keyWindow?.rootViewController else {
            return
        }

        switch self {
        case .Email(let email):
            let feedbackMail = FeedbackMail()
            FeedbackViewController.presentFeedbackViewController(callerViewController, action: { (feedbackViewController: FeedbackViewController, sendInformation: SendInformation) in
                // send mail
                feedbackMail.send(email, sendInformation: sendInformation, callerViewController: feedbackViewController, mailSendCompletion: {
                    // complete send mail and dismiss feedbackview
                    feedbackViewController.dismissFeedbackViewController()
                    // callback
                    dismissed()
                })
            })
        case .Custom(let action):
            FeedbackViewController.presentFeedbackViewController(callerViewController, action: { (feedbackViewController: FeedbackViewController, sendInformation: SendInformation) in

                let success: (()->Void) = {
                    // dismiss feedbackview
                    feedbackViewController.dismissFeedbackViewController()
                    // callback
                    dismissed()
                }

                // execute custom action
                action(feedbackViewController: feedbackViewController, sendInformation: sendInformation, success: success)
            })
        }
    }

    public func addDoubleLongPressGestureRecognizer(dismissed:(()->Void)) {

        GestureFeedback.gestureFeedback.dismissed = dismissed
        GestureFeedback.gestureFeedback.feedback = self

        let gesture = UILongPressGestureRecognizer(target: GestureFeedback.gestureFeedback, action: #selector(GestureFeedback.pressGesture(_:)))
        gesture.numberOfTouchesRequired = 2
        if let window = UIApplication.sharedApplication().delegate?.window {
            if let recognizers = window?.gestureRecognizers {
                for recognizer in recognizers {
                    if recognizer is UILongPressGestureRecognizer {
                        window?.removeGestureRecognizer(recognizer)
                    }
                }
            }
            window?.addGestureRecognizer(gesture)
        }
    }
}

final class GestureFeedback: NSObject {

    var feedback: Feedback?
    var dismissed: (()->Void)?

    static let gestureFeedback = GestureFeedback()

    private override init() {

    }

    func pressGesture(sender: UIGestureRecognizer) {

        guard let feedback = feedback else {
            return
        }

        guard let dismissed = dismissed else {
            feedback.show({
                // none
            })
            return
        }
        feedback.show(dismissed)
    }
}
