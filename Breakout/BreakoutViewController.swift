//
//  BreakoutViewController.swift
//  Breakout
//
//  Created by Tatiana Kornilova on 9/4/15.
//  Copyright (c) 2015 Tatiana Kornilova. All rights reserved.
//

import UIKit
import CoreMotion

class BreakoutViewController: UIViewController, BreakoutCollisionBehaviorDelegate {

    @IBOutlet var breakoutView: BreakoutView!{
        didSet{
            breakoutView.initialize()
            breakoutView.paddleWidthPercentage = settings.paddleWidth
            breakoutView.level = settings.level
            breakoutView.launchSpeedModifier = settings.ballSpeedModifier
     }
    }
    
    @IBOutlet var ballsLeftLabel: UILabel!
    @IBOutlet var scoreLabel: UILabel!
    
    private var maxBalls: Int = Settings().maxBalls {
        didSet { ballsLeftLabel?.text = "⦁".repeat(maxBalls - ballsUsed) }
    }
    
    private var ballsUsed = 0 {
        didSet { ballsLeftLabel?.text = "⦁".repeat(maxBalls - ballsUsed) }
    }
    
    private var score = 0 {
        didSet{ scoreLabel?.text = "\(score)" }
    }
    
    private var ballVelocity = [CGPoint]()
    private var gameViewSizeChanged = true
    
    private let motionManager = CMMotionManager()
    private let settings = Settings()

    // MARK: - LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        breakoutView.behavior.breakoutCollisionDelegate = self
        breakoutView.addGestureRecognizer( UITapGestureRecognizer(target: self, action: "launchBall:") )
        breakoutView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "panPaddle:"))
        motionManager.accelerometerUpdateInterval = 0.01

    }
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadSettings()
        // Restart balls when tabbing back to Breakout game
/*
        if !ballVelocity.isEmpty {
            for i in 0..<breakoutView.behavior.balls.count {
                breakoutView.behavior.startBall(breakoutView.behavior.balls[i], velocity: ballVelocity[i])
            }
        }
 */
        breakoutView.ballVelocity = ballVelocity
        
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        AppDelegate.Motion.Manager.stopAccelerometerUpdates()
        // Stop balls
/*
        ballVelocity = []
        for ball in breakoutView.behavior.balls {
            ballVelocity.append(breakoutView.behavior.stopBall(ball))
        }
*/
        ballVelocity = breakoutView.ballVelocity
    }

   
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        gameViewSizeChanged = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Переустановка при вращении
        if gameViewSizeChanged {
            gameViewSizeChanged = false
            breakoutView.resetLayout()

        }
    }
    
  // MARK: - LoAD SEIITINGS
    
   private func loadSettings() {
        
        // Setup accelerometer
        if settings.controlWithTilt {
            let motionManager = AppDelegate.Motion.Manager
            if motionManager.accelerometerAvailable {
                motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue())
                    { (data, error) -> Void in
                        self.breakoutView.translatePaddle( CGPoint(x: Const.maxPaddleSpeed * data.acceleration.x, y: 0.0) )
                }
            }
        }
        maxBalls = settings.maxBalls
    
        breakoutView.paddleWidthPercentage = settings.paddleWidth
        breakoutView.level = settings.level
        breakoutView.launchSpeedModifier = settings.ballSpeedModifier
        
    }
    
    // MARK: - RESET GAME
   private func resetGame()
    {
        breakoutView.reset()
        ballsUsed = 0
        score = 0
    }
    
    // MARK: - Hit BRICK

    func ballHitBrick(behavior: UICollisionBehavior, ball: BallView, brickIndex: Int) {
       breakoutView.removeBrick(brickIndex)
        score++
        if breakoutView.bricks.count == 0 {
            breakoutView.removeAllBalls()
            showGameEndedAlert(true, message: "Выигрыш!")
        }
    }
    
    // MARK: - Ball LEFT
 
    func ballLeftPlayingField(ball: BallView)
    {
        if(ballsUsed == maxBalls) { // the last ball just left the playing field
             showGameEndedAlert(false, message: "Нет мячиков!")
        }
        breakoutView.removeBall(ball)
    }
    
    // MARK: - ALERT
    
    private func showGameEndedAlert(playerWon: Bool, message: String) {
        let title = playerWon ? Const.congratulationsTitle : Const.gameOverTitle
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)

        alert.addAction(UIAlertAction(title: "Ok", style: .Default) {
            (action) in
              self.resetGame()
            })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) {
            (action) in
            // do nothing
            })
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)}
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true;
    }
    // on device shake
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        breakoutView.pushBalls()
    }

   // MARK: - GESTURES
    
   //---- ОБРАБОТКА ЖЕСТОВ
    func launchBall(gesture: UITapGestureRecognizer){
        if gesture.state == .Ended {
            if ballsUsed < maxBalls {
                ballsUsed++;
                breakoutView.addBall()
            } else {
                breakoutView.pushBalls()
            }
        }
    }
    
    func panPaddle(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            breakoutView.translatePaddle(gesture.translationInView(breakoutView))
            gesture.setTranslation(CGPointZero, inView: breakoutView)
        default: break
        }
    }
    
    private struct Const {
        static let gameOverTitle = "Game over!"
        static let congratulationsTitle = "Congratulations!"
 /*
        static let minBallLaunchAngle = 210
        static let maxBallLaunchAngle = 330
        static let minLaunchSpeed = CGFloat(0.2)
        static let maxLaunchSpeed = CGFloat(0.8)
        static let pushSpeed = CGFloat(0.05)
  */
        static let maxPaddleSpeed = 25.0
    }
}
