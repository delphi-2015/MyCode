//
//  ViewController.swift
//  PingTransitionDemo
//
//  Created by delphiwu on 16/9/2.
//  Copyright © 2016年 delphi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let animation = PingTransitionAnimation()
    var touchPoint = CGPointZero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func presentBtnPressed(sender: AnyObject) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PresentedViewController") as! PresentedViewController
        
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .FullScreen
        presentViewController(vc, animated: true, completion: nil)
    }
    
}

//MARK:UINavigationControllerDelegate
extension ViewController:UINavigationControllerDelegate {
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .Push {
            animation.transitionMode = .open
            animation.duration = 0.5
            animation.startPoint = touchPoint
            return animation
        } else if operation == .Pop {
            animation.transitionMode = .close
            animation.duration = 0.5
            animation.startPoint = touchPoint
            return animation
        }else {
            return nil
        }
    }
}

//MARK:UIViewControllerTransitioningDelegate
extension ViewController:UIViewControllerTransitioningDelegate {
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animation.duration = 0.5
        animation.transitionMode = .open
        animation.startPoint = touchPoint
        return animation
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animation.duration = 0.5
        animation.transitionMode = .close
        animation.startPoint = touchPoint
        return animation
    }
}

//MARK:UIGestureRecognizerDelegate
extension ViewController:UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        touchPoint = touch.locationInView(self.view)
        return false
    }
}

