//
//  ViewController.swift
//  ImageDemo
//
//  Created by duzhe on 16/9/11.
//  Copyright © 2016年 dz. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices




class v : UIView {
    
    var i = 0
    override func displayLayer(layer: CALayer) {
        print("displayLayer")
        
//        i += 1
//        if i%2 == 0{
//            layer.frame.origin.y = self.frame.origin.y + 1
//        }else{
//            layer.frame.origin.y = self.frame.origin.y - 1
//        }
        
        
        
    }
    
}


class ViewController: UIViewController {

    @IBOutlet weak var imgV:AnimatedImageView!

    var displayLink:CADisplayLink!
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let path = NSBundle.mainBundle().pathForResource("xxx", ofType: "gif")
//        let data = NSData(contentsOfFile: path!)
//        handleGif(data!)
        let path = NSBundle.mainBundle().pathForResource("xxx", ofType: "gif")
        let data = NSData(contentsOfFile: path!)
        imgV.gifData = data
//        imgV.startAnimating()
        
//        let imgSource = CGImageSourceCreateWithData(data!, nil)
//        
//        // 分解帧
//        // 帧数
//        let count  = CGImageSourceGetCount(imgSource!)
//        var tmpArr:[UIImage] = []
//        
//        // 遍历没帧
//        for i in 0..<count{
//            
//            let imgRef = CGImageSourceCreateImageAtIndex(imgSource!, i, nil)
//            // 获取帧的img
//            let  image = UIImage(CGImage: imgRef! , scale: UIScreen.mainScreen().scale , orientation: UIImageOrientation.Up)
//            tmpArr.append(image)
//        }
//        imgV.image = tmpArr.last
//        imgV.contentMode = .ScaleAspectFit
//        imgV.animationImages = tmpArr
//        imgV.animationDuration = 1
//        imgV.animationRepeatCount = 0 // 无限循环
//        imgV.startAnimating()
//        
//        print(count)
//        displayLink = CADisplayLink(target: self , selector: #selector(ta))
//        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode )
//        displayLink.paused = true
//
//        a = v()
//        a.frame = CGRectMake(0, 100, 10, 10)
//        a.backgroundColor = UIColor.redColor()
//        self.view.addSubview(a)
//        for i in 0...10{
//            a.layer.setNeedsDisplay()
//        }
        
    }
    
    var a:v!
    
    func ta(){
        a.layer.setNeedsDisplay()
    }
    
    
    @IBAction func start(sender: AnyObject) {
        if !imgV.isAnimating() {
            imgV.startAnimating()
        }
    }
    

    @IBAction func stop(sender: AnyObject) {
        if imgV.isAnimating() {
            imgV.stopAnimating()
        }
    }
    
    func handleGif(data:NSData) {
        // kCGImageSourceShouldCache : 表示是否在存储的时候就解码
        // kCGImageSourceTypeIdentifierHint : 指明source type
        let options: NSDictionary = [kCGImageSourceShouldCache as String: NSNumber(bool: true), kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        guard let imageSource = CGImageSourceCreateWithData(data, options) else {
            return
        }
        
        // 获取gif帧数
        let frameCount = CGImageSourceGetCount(imageSource)
        var images = [UIImage]()
        
        var gifDuration = 0.0
        
        for i in 0 ..< frameCount {
            // 获取对应帧的 CGImage
            guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, options) else {
                return
            }
            if frameCount == 1 {
                // 单帧
                gifDuration = Double.infinity
            } else{
                // gif 动画
                // 获取到 gif每帧时间间隔
                guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) , gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
                    frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else
                {
                    return
                }
//                print(frameDuration)
                gifDuration += frameDuration.doubleValue
                // 获取帧的img
                let  image = UIImage(CGImage: imageRef , scale: UIScreen.mainScreen().scale , orientation: UIImageOrientation.Up)
                // 添加到数组
                images.append(image)
            }
        }
        
        print(gifDuration)
        imgV.contentMode = .ScaleAspectFit
        imgV.animationImages = images
        imgV.animationDuration = gifDuration
        imgV.animationRepeatCount = 0 // 无限循环
        imgV.startAnimating()
    }
    
    
    
  
  

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
  
    
}






struct AnimatedFrame {
    var image: UIImage?
    let duration: NSTimeInterval
    
    static func null() -> AnimatedFrame {
        return AnimatedFrame(image: .None, duration: 0.0)
    }
}

class Animator{
    private let maxFrameCount: Int = 100    // 最大帧数
    private var imageSource:CGImageSource!  // imageSource 处理帧相关操作
    private var animatedFrames = [AnimatedFrame]()  //
    private var frameCount = 0  // 帧的数量
    private var currentFrameIndex = 0   // 当前帧下标
    private var currentPreloadIndex = 0 // 当前预缓存帧的下标
    private var timeSinceLastFrameChange: NSTimeInterval = 0.0  // 距离上一帧改变的时间
    /// 循环次数
    private var loopCount = 0
    /// 做大间隔
    private let maxTimeStep: NSTimeInterval = 1.0
    
    
    var currentFrame: UIImage? {
        return frameAtIndex(currentFrameIndex)
    }
    
    var contentMode: UIViewContentMode = .ScaleToFill

    /**
     根据data创建 CGImageSource
     
     - parameter data: gif data
     */
    func createImageSource(data:NSData){
        let options: NSDictionary = [kCGImageSourceShouldCache as String: NSNumber(bool: true), kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        imageSource = CGImageSourceCreateWithData(data, options)
    }
    
    
    /// 准备某帧 的 frame
    func prepareFrame(index: Int) -> AnimatedFrame {
        // 获取对应帧的 CGImage
        guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index , nil) else {
            return AnimatedFrame.null()
        }
        // 获取到 gif每帧时间间隔
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index , nil) , gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else
        {
            return AnimatedFrame.null()
        }
        
        let image = UIImage(CGImage: imageRef , scale: UIScreen.mainScreen().scale , orientation: UIImageOrientation.Up)
        return AnimatedFrame(image: image, duration: Double(frameDuration) ?? 0.0)
    }
    
    /**
     预备所有frames
     */
    func prepareFrames() {
        frameCount = CGImageSourceGetCount(imageSource)
        
        if let properties = CGImageSourceCopyProperties(imageSource, nil),
            gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            loopCount = gifInfo[kCGImagePropertyGIFLoopCount as String] as? Int {
            self.loopCount = loopCount
        }
        
        // 总共帧数
        let frameToProcess = min(frameCount, maxFrameCount)
        
        animatedFrames.reserveCapacity(frameToProcess)
        
        // 相当于累加
        animatedFrames = (0..<frameToProcess).reduce([]) { $0 + pure(prepareFrame($1))}
        
        // 上面相当于这个
        //        for i in 0..<frameToProcess {
        //            animatedFrames.append(prepareFrame(i))
        //        }
        
    }
    
    /**
     根据下标获取帧
     */
    func frameAtIndex(index: Int) -> UIImage? {
        return animatedFrames[index].image
    }
    
    
    func updateCurrentFrame(duration: CFTimeInterval) -> Bool {
        // 计算距离上一帧 改变的时间 每次进来都累加 直到frameDuration  <= timeSinceLastFrameChange 时候才继续走下去
        timeSinceLastFrameChange += min(maxTimeStep, duration)
        guard let frameDuration = animatedFrames[safe: currentFrameIndex]?.duration where frameDuration <= timeSinceLastFrameChange else {
            return false
        }
        // 减掉 我们每帧间隔时间
        timeSinceLastFrameChange -= frameDuration
        let lastFrameIndex = currentFrameIndex
        currentFrameIndex += 1 // 一直累加
        // 这里取了余数
        currentFrameIndex = currentFrameIndex % animatedFrames.count
        
        if animatedFrames.count < frameCount {
            animatedFrames[lastFrameIndex] = prepareFrame(currentPreloadIndex)
            currentPreloadIndex += 1
            currentPreloadIndex = currentPreloadIndex % frameCount
        }
        return true
    }
    
    
}



extension Array {
    subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : .None
    }
}

public class AnimatedImageView : UIImageView {
    
    /// 防止循环引用
    class TargetProxy {
        private weak var target: AnimatedImageView?
        
        init(target: AnimatedImageView) {
            self.target = target
        }
        
        @objc func onScreenUpdate() {
            target?.updateFrame()
        }
    }
    
    // 是否自动播放
    public var autoPlayAnimatedImage = true
    
    /// `Animator` 对象 将帧和指定图片存储内存中
    private var animator: Animator?
    
    /// displayLink 为懒加载 避免还没有加载好的时候使用了 造成异常
    private var displayLinkInitialized: Bool = false

    
    // NSRunLoopCommonModes UITrackingRunLoopMode
    public var runLoopMode = NSDefaultRunLoopMode {
        willSet {
            if runLoopMode == newValue {
                return
            } else {
                stopAnimating()
                displayLink.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: runLoopMode)
                displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: newValue)
                startAnimating()
            }
        }
    }
    
    
    private lazy var displayLink: CADisplayLink = {
        self.displayLinkInitialized = true
        let displayLink = CADisplayLink(target: TargetProxy(target: self), selector: #selector(TargetProxy.onScreenUpdate))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: self.runLoopMode)
        displayLink.paused = true
        return displayLink
    }()
    
    private func updateFrame() {
        if animator?.updateCurrentFrame(displayLink.duration) ?? false {
            // 此方法会触发 displayLayer
            layer.setNeedsDisplay()
        }
    }
    
    
    private func didMove() {
        if autoPlayAnimatedImage && animator != nil {
            if let _ = superview, _ = window {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
    
    
    public override var image: UIImage?{
        didSet{
            if image != oldValue {
                reset()
            }
            setNeedsDisplay()
            layer.setNeedsDisplay()
        }
    }
    
    
    public var gifData:NSData?{
        didSet{
            if let gifData = gifData {
                animator = nil
                animator = Animator()
                
                animator?.createImageSource(gifData)
                animator?.prepareFrames()
                
                didMove()
                setNeedsDisplay()
                layer.setNeedsDisplay()
            }
        }
    }
    
    
//    // MARK: - Override
//    override public var image: UImage? {
//        didSet {
//            if image != oldValue {
//                reset()
//            }
//            setNeedsDisplay()
//            layer.setNeedsDisplay()
//        }
//    }
    
    deinit {
        if displayLinkInitialized {
            displayLink.invalidate()
        }
    }
    
    override public func isAnimating() -> Bool {
        if displayLinkInitialized {
            return !displayLink.paused
        } else {
            return super.isAnimating()
        }
    }
    
    /// Starts the animation.
    override public func startAnimating() {
        if self.isAnimating() {
            return
        } else {
            displayLink.paused = false
        }
    }
    
    /// Stops the animation.
    override public func stopAnimating() {
        super.stopAnimating()
        if displayLinkInitialized {
            displayLink.paused = true
        }
    }
    
    
    override public func displayLayer(layer: CALayer) {
        if let currentFrame = animator?.currentFrame {
            layer.contents = currentFrame.CGImage
        } else {
            layer.contents = image?.CGImage
        }
    }
    
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        didMove()
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        didMove()
    }
    
    private func reset() {
        animator = nil
        animator = Animator()
        let path = NSBundle.mainBundle().pathForResource("xxx", ofType: "gif")
        let data = NSData(contentsOfFile: path!)
        animator?.createImageSource(data!)
        animator?.prepareFrames()
        
        didMove()
    }
}



private func pure<T>(value: T) -> [T] {
    return [value]
}

