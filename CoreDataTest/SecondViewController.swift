//
//  DataViewController.swift
//  CoreDataTest
//
//  Created by Ross M Mooney on 10/26/15.
//  Copyright © 2015 Ross Mooney. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    
    var animatedView:UIView!

    
    override func viewDidLoad() {

    //Setup
    self.animatedView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    self.animatedView.backgroundColor = .redColor()
    self.view.addSubview(self.animatedView)
    
}

override func viewDidAppear(animated: Bool) {
    animate(true)
    
    print("Number of items: \(Data.sharedInstance.numberOfContacts())")
}

func animate(forwards: Bool) {
    UIView.animateWithDuration(2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
        if forwards {
            self.animatedView.frame = CGRect(x: 100, y: 200, width: 300, height: 200)
            self.animatedView.backgroundColor = .purpleColor()
            self.animatedView.transform = CGAffineTransformMakeRotation(340)
            
        } else {
            self.animatedView.frame = CGRect(x: 30, y: 80, width: 100, height: 70)
            self.animatedView.backgroundColor = .yellowColor()
            self.animatedView.transform = CGAffineTransformMakeRotation(54)
            
        }
        }) { _ in
            self.animate(!forwards)
    }
    
}
}
    