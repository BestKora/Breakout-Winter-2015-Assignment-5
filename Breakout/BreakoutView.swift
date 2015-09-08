//
//  BreakoutView.swift
//  Breakout
//
//  Created by Tatiana Kornilova on 9/4/15.
//  Copyright (c) 2015 Tatiana Kornilova. All rights reserved.
//

import UIKit
class BreakoutView: UIView {
    
    lazy var animator: UIDynamicAnimator = {UIDynamicAnimator(referenceView: self)}()

    var behavior = BreakoutBehavior()
    
    var balls = [BallView]()
    var bricks =  [Int:BrickView]()
    
    lazy var paddle: PaddleView = {
        let paddle = PaddleView(frame: CGRect(origin: CGPointZero, size: self.paddleSize))
        self.addSubview(paddle)
        return paddle
        }()
    
    var level :[[Int]]? {
        didSet {
            if let newLevel = level ,let oldLevel = oldValue{
                if newLevel == oldLevel {return}
            }
            columns = level?[0].count
            reset()
        }
    }
    
    private var columns: Int?
  
    // MARK: - LIFE CYCLE
    
    func initialize() {
        
        self.backgroundColor = UIColor.blackColor()
        animator.addBehavior(behavior)
        
     }


    override func layoutSubviews() {
        super.layoutSubviews()
             resetLayout()
    }

    private func resetLayout()
    {
        var gameBounds = self.bounds
        gameBounds.size.height *= 2.0
        behavior.addBoundary(UIBezierPath(rect: gameBounds), named: Constants.selfBoundaryId)
        
        resetPaddlePosition()
          // If needed put ball back inside breakoutView after rotation
        for ball in balls {
            if !CGRectContainsRect(self.bounds, ball.frame) {
                placeBallInCenter(ball)
                animator.updateItemUsingCurrentState(ball)
            }
        }
    }

 
    func reset()
    {
       removeBricks()
       removeAllBalls()
       createBricks()
       resetPaddleInCenter()
    }
    
    // MARK: - BALLS
  
    func addBall() {
        let ball = BallView(frame: CGRect(origin: CGPoint(x: paddle.center.x,
                                                          y: paddle.frame.minY - Constants.BallSize.height),
                                                       size: Constants.BallSize))
        balls.append(ball)
        self.behavior.addBall(ball)
    }
    
    func removeBall(ball: BallView){
        self.behavior.removeBall(ball)
        if let index = find(balls, ball) {
            balls.removeAtIndex(index)
        }
    }
    
     private  func removeAllBalls(){
        behavior.removeAllBalls()
        balls = [BallView]()
    }
    
    private func placeBallInCenter(ball: UIView) {
// ???
        let ballViewOrigin = CGPoint(x: bounds.midX - Constants.BallSize.width / 2,
            y: bounds.maxY - Constants.PaddleBottomMargin - Constants.BallSize.height / 2)
        ball.center = self.center
    }
    

    // MARK: - BRICKS
    
    private func createBricks() {
        if let arrangement = level {
            
            if arrangement.count == 0 { return }    // no rows
            if arrangement[0].count == 0 { return } // no columns
            
            let rows = arrangement.count
            let columns = arrangement[0].count
            let width = (self.bounds.size.width - 2 * Constants.BrickSpacing) / CGFloat(columns)
            
            for row in 0 ..< rows {
                let columns = arrangement[row].count
                for column in 0 ..< columns {
                    if arrangement[row][column] == 0 { continue }
                    
                    let x = Constants.BrickSpacing + CGFloat(column) * width
                    let y = Constants.BricksTopSpacing + CGFloat(row) * Constants.BrickHeight + CGFloat(row) * Constants.BrickSpacing * 2
                    let hue = CGFloat(row) / CGFloat(rows)
                    createBrick(width, x: x, y: y, hue: hue)
                }
            }
        }
    }
    
    private func createBrick(width: CGFloat, x: CGFloat, y: CGFloat, hue: CGFloat) {
        var frame = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: Constants.BrickHeight))
        frame = CGRectInset(frame, Constants.BrickSpacing, 0)
        
        let brick = BrickView(frame: frame, hue: hue)
        bricks[bricks.count] = brick
        
        addSubview(brick)
        behavior.addBoundary( UIBezierPath(roundedRect: brick.frame, cornerRadius: brick.layer.cornerRadius), named: (bricks.count - 1) )
    }

    
    func removeBrick(brickIndex: Int) {
        behavior.removeBoundary(brickIndex)
        
        if let brick = bricks[brickIndex] {
            UIView.transitionWithView(brick, duration: 0.3, options: .TransitionFlipFromBottom, animations: {
                brick.alpha = 0.5
                }, completion: { (success) -> Void in
                    UIView.animateWithDuration(1.0, animations: {
                        brick.alpha = 0.0
                        }, completion: { (success) -> Void in
                            brick.removeFromSuperview()
                    })
            })
            
            bricks.removeValueForKey(brickIndex)
        }
    }
    
    private func removeBrickWithoutAnimation(brickIndex: Int) {
        behavior.removeBoundary(brickIndex)
        
        if let brick = bricks[brickIndex] {
                brick.removeFromSuperview()
                bricks.removeValueForKey(brickIndex)
        }
    }
    
    func resetBricks(){
        var activeBricksSet = Set(bricks.keys)
        removeBricks()
        createBricks()
        for brick in bricks {
            var index = brick.0
             if  !activeBricksSet.contains(index) {
                 removeBrickWithoutAnimation(brick.0)
            }
        }
    }
    
    private func removeBricks() {
        if bricks.count == 0 {return}
        for brick in bricks {
            removeBrickWithoutAnimation(brick.0)
        }
    }
    
    // MARK: - PADDLE

 
    var paddleWidthPercentage :Int = 33 {
        didSet{
            if  paddleWidthPercentage == oldValue{ return}
         resetPaddleInCenter()
         }
    }
    
    private var paddleSize : CGSize {
        let width = self.bounds.size.width / 100.0 * CGFloat(paddleWidthPercentage)
        return CGSize(width: width, height: CGFloat(Constants.PaddleHeight))
    }

    func translatePaddle(translation: CGPoint) {
        var newFrame = paddle.frame
        newFrame.origin.x = max( min(newFrame.origin.x + translation.x, self.bounds.maxX - paddle.bounds.size.width), 0.0)         
        for ball in balls {
            if CGRectContainsRect(newFrame, ball.frame) {
                return
            }
        }
        paddle.frame = newFrame;
        updatePaddleBoundary()
    }
    
    func resetPaddleInCenter(){
        paddle.center = CGPointZero
        resetPaddlePosition()
    }
    
    func resetPaddlePosition() {
       paddle.frame.size = paddleSize
       if !CGRectContainsRect(self.bounds, paddle.frame) {
            paddle.center = CGPoint(x: self.bounds.midX, y: self.bounds.maxY - paddle.bounds.height - Constants.PaddleBottomMargin)
        } else {
            paddle.center = CGPoint(x: paddle.center.x, y: self.bounds.maxY - paddle.bounds.height - Constants.PaddleBottomMargin)
        }
        
        updatePaddleBoundary()
    }
    
    private func updatePaddleBoundary() {
        behavior.addBoundary(UIBezierPath(ovalInRect: paddle.frame), named: Constants.paddleBoundaryId)
    }

    struct Constants {
        static let selfBoundaryId = "selfBoundary"
        static let paddleBoundaryId = "paddleBoundary"
        static let BallSize = CGSize(width: 20, height: 20)
        static let BallSpacing: CGFloat = 3
        
        static let PaddleBottomMargin: CGFloat = 10.0
        static let PaddleHeight: Int = 15
        static let PaddleColor = UIColor.whiteColor()
        static let BrickHeight: CGFloat = 20.0
        static let BrickSpacing: CGFloat = 5.0
        static let BricksTopSpacing: CGFloat = 20.0
        static let BrickSideSpacing: CGFloat = 10.0
    }
    
}
