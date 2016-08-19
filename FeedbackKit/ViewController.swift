//
//  ViewController.swift
//  FeedbackKit
//
//  Created by Mao Nishi on 8/15/16.
//  Copyright © 2016 Mao Nishi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // You can add '2 finger long press gesture'.
        // And You can show feedback view by '2 finger long press'.
        let emailConifg = Feedback.EmailConfig(to: "hoge@hogehogehoge.jp")
        Feedback.Email(emailConfig: emailConifg).addDoubleLongPressGestureRecognizer {
            print("dismissed")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showFeedbackViewController(sender: AnyObject) {

        // show feedback view by myself
        let emailConifg = Feedback.EmailConfig(to: "hoge@hogehogehoge.jp")
        Feedback.Email(emailConfig: emailConifg).show {
            print("dismissed")
        }
    }
}
