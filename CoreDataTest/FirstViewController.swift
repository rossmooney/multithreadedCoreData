//
//  ViewController.swift
//  CoreDataTest
//
//  Created by Ross M Mooney on 10/22/15.
//  Copyright © 2015 Ross Mooney. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    var animatedView:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.animatedView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.animatedView.backgroundColor = .redColor()
        self.view.addSubview(self.animatedView)
        
        //Load data in background (if not already doing so)
        Data.sharedInstance.loadAllTheData()
    }

    override func viewDidAppear(animated: Bool) {
        //Animate all the time
        animate(true)
    }
    
    func animate(forwards: Bool) {
        UIView.animateWithDuration(2, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            if forwards {
                self.animatedView.frame = CGRect(x: 200, y: 500, width: 500, height: 500)
                self.animatedView.backgroundColor = .orangeColor()
                self.animatedView.transform = CGAffineTransformMakeRotation(180)
                
            } else {
                self.animatedView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
                self.animatedView.backgroundColor = .greenColor()
                self.animatedView.transform = CGAffineTransformMakeRotation(360)

            }
            }) { _ in
                //Keep it going
                self.animate(!forwards)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

