//
//  PingTransitionAnimation.swift
//  Run
//
//  Created by delphiwu on 16/8/23.
//  Copyright © 2016年 delphi. All rights reserved.
//

import UIKit

enum PingTranisionMode {
    case open, close
}

class PingTransitionAnimation: NSObject {
    var duration: NSTimeInterval = 0.0
    var startPoint: CGPoint = CGPointZero
    var transitionMode: PingTranisionMode = .open
    var bubbleColor: UIColor = UIColor.whiteColor()
    
    private var _transitionContext: UIViewControllerContextTransitioning?
}

extension PingTransitionAnimation: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let containerView = transitionContext.containerView(), fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
            return
        }
        
        _transitionContext = transitionContext
        
        var radius: CGFloat = 0.0
        
        if(startPoint.x > (containerView.bounds.size.width / 2)){
            if (startPoint.y < (containerView.bounds.size.height / 2)) {
                //第一象限
                radius = sqrt((startPoint.x * startPoint.x) + (containerView.bounds.size.height-startPoint.y)*(containerView.bounds.size.height-startPoint.y))
            }else{
                //第四象限
                radius = sqrt((startPoint.x * startPoint.x) + (startPoint.y*startPoint.y))
            }
        }else{
            if (startPoint.y < (containerView.bounds.size.height / 2)) {
                //第二象限
                radius = sqrt((containerView.bounds.size.width - startPoint.x) * (containerView.bounds.size.width - startPoint.x) + (containerView.bounds.size.height - startPoint.y)*(containerView.bounds.size.height - startPoint.y));
            }else{
                //第三象限
                radius = sqrt((containerView.bounds.size.width - startPoint.x) * (containerView.bounds.size.width - startPoint.x) + (startPoint.y*startPoint.y))
            }
        }
        
        let pingPath = UIBezierPath.init(ovalInRect: CGRectMake(startPoint.x - 2 , startPoint.y - 2, 4, 4))
        let bigPath = UIBezierPath.init(ovalInRect: CGRectMake(startPoint.x - radius, startPoint.y - radius, radius*2, radius*2))
        
        let maskLayer = CAShapeLayer()
        let maskLayerAnimation = CABasicAnimation(keyPath: "path")
        let contentView = transitionContext.containerView()
        switch transitionMode {
        case .open:
            contentView?.addSubview(fromVC.view)
            contentView?.addSubview(toVC.view)
            maskLayer.path = bigPath.CGPath
            maskLayerAnimation.fromValue = pingPath.CGPath
            maskLayerAnimation.toValue  = bigPath.CGPath
            toVC.view.layer.mask = maskLayer
        case .close:
            contentView?.addSubview(toVC.view)
            contentView?.addSubview(fromVC.view)
            maskLayer.path = pingPath.CGPath
            maskLayerAnimation.fromValue = bigPath.CGPath
            maskLayerAnimation.toValue  = pingPath.CGPath
            fromVC.view.layer.mask = maskLayer
        }
        
        maskLayerAnimation.duration = duration
        maskLayerAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        maskLayerAnimation.delegate = self
        maskLayer.addAnimation(maskLayerAnimation, forKey: "path")
        
    }
}

extension PingTransitionAnimation {
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if let transitionContext = _transitionContext{
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)?.view.layer.mask = nil
            transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)?.view.layer.mask = nil
        }
    }
}
