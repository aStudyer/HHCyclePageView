//
//  HHPageControl.swift
//  HHCyclePageView_Example
//
//  Created by aStudyer立 on 2019/10/14.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

public class HHPageControl: UIControl {
    public var numberOfPages: NSInteger = 0 {
        didSet{
            if numberOfPages == oldValue {
                return
            }
            if currentPage >= numberOfPages {
                currentPage = 0
            }
            updateIndicatorViews()
            if indicatorViews.count > 0 {
                setNeedsLayout()
            }
        }
    }
    /// value pinned to 0..numberOfPages-1
    public var currentPage: NSInteger = 0 {
        didSet{
            if currentPage == oldValue || indicatorViews.count <= currentPage{
                return
            }
            if !currentPageIndicatorSize.equalTo(pageIndicatorSize) {
                setNeedsLayout()
            }
            updateIndicatorViewsBehavior()
            if isUserInteractionEnabled {
                sendActions(for: .valueChanged)
            }
        }
    }
    /// hide the the indicator if there is only one page
    var hidesForSinglePage: Bool = false
    public var pageIndicatorSpaing: CGFloat = 10 {
        didSet{
            if (indicatorViews.count > 0) {
                setNeedsLayout()
            }
        }
    }
    /// center will ignore this
    var contentInset: UIEdgeInsets = .zero
    /// real content size
    private(set) var contentSize: CGSize {
        set{
            
        }
        get{
            let width = (CGFloat)(indicatorViews.count - 1) * (pageIndicatorSize.width + pageIndicatorSpaing) + pageIndicatorSize.width + contentInset.left + contentInset.right
            let height = currentPageIndicatorSize.height + contentInset.top + contentInset.bottom
            return CGSize(width: width, height: height)
        }
    }
    /// indicatorTint color
    public var pageIndicatorTintColor: UIColor = UIColor(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, alpha: 1.0) {
        didSet{
            updateIndicatorViewsBehavior()
        }
    }
    public var currentPageIndicatorTintColor: UIColor = UIColor.white {
        didSet{
            updateIndicatorViewsBehavior()
        }
    }
    /// indicator image
    var pageIndicatorImage: UIImage? {
        didSet {
            updateIndicatorViewsBehavior()
        }
    }
    var currentPageIndicatorImage: UIImage? {
        didSet {
            updateIndicatorViewsBehavior()
        }
    }
    var indicatorImageContentMode: UIView.ContentMode = .center
    /// indicator size
    public var pageIndicatorSize: CGSize = CGSize(width: 6, height: 6) {
        didSet{
            if pageIndicatorSize.equalTo(oldValue) {
                return
            }
            if currentPageIndicatorSize.equalTo(.zero) ||
                (currentPageIndicatorSize.width < pageIndicatorSize.width && currentPageIndicatorSize.height < pageIndicatorSize.height){
                currentPageIndicatorSize = pageIndicatorSize
            }
            if (indicatorViews.count > 0) {
                setNeedsLayout()
            }
        }
    }
    public var currentPageIndicatorSize: CGSize = CGSize(width: 6, height: 6) {
        didSet{
            if currentPageIndicatorSize.equalTo(oldValue) {
                return
            }
            if indicatorViews.count > 0 {
                setNeedsLayout()
            }
        }
    }
    var animateDuring: CGFloat = 0.3
    // UI
    private lazy var indicatorViews: [UIImageView] = [UIImageView]()
    // Data
    private var forceUpdate: Bool = false
    public override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
        didSet{
            if indicatorViews.count > 0 {
                setNeedsLayout()
            }
        }
    }
    public override var contentVerticalAlignment: UIControl.ContentVerticalAlignment{
        didSet{
            if indicatorViews.count > 0 {
                setNeedsLayout()
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isUserInteractionEnabled = false
    }
}
extension HHPageControl {
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if let _ = newSuperview {
            forceUpdate = true
            updateIndicatorViews()
            forceUpdate = false
        }
    }
}
// MARK: - getter setter
extension HHPageControl {
    private func setCurrentPage(currentPage: NSInteger, animate: Bool){
        if animate {
            UIView.animate(withDuration: TimeInterval(animateDuring)) {
                self.currentPage = currentPage
            }
        }else {
            self.currentPage = currentPage
        }
    }
    // MARK: - update indicator
    private func updateIndicatorViews() {
        if superview == nil && !forceUpdate {
            return
        }
        if indicatorViews.count == numberOfPages {
            updateIndicatorViewsBehavior()
            return
        }
        var indicatorViews = self.indicatorViews.count > 0 ? self.indicatorViews : Array()
        let count = indicatorViews.count
        if count < numberOfPages {
            for _ in count..<numberOfPages {
                let indicatorView = UIImageView()
                indicatorView.contentMode = indicatorImageContentMode
                addSubview(indicatorView)
                indicatorViews.append(indicatorView)
            }
        }else if count > numberOfPages {
            for index in (numberOfPages..<count).reversed(){
                let indicatorView = indicatorViews[index]
                indicatorView.removeFromSuperview()
                indicatorViews.remove(at: index)
            }
        }
        self.indicatorViews = indicatorViews
        updateIndicatorViewsBehavior()
    }
    private func updateIndicatorViewsBehavior() {
        if (0 == indicatorViews.count) || (superview == nil && !forceUpdate) {
            return
        }
        if hidesForSinglePage && (1 == indicatorViews.count) {
            let indicatorView = indicatorViews.last
            indicatorView?.isHidden = true
            return
        }
        var index = 0
        for indicatorView in indicatorViews {
            if let pageIndicatorImage = pageIndicatorImage {
                indicatorView.contentMode = indicatorImageContentMode
                indicatorView.image = currentPage == index ? currentPageIndicatorImage : pageIndicatorImage
            }else{
                indicatorView.image = nil
                indicatorView.backgroundColor = currentPage == index ? currentPageIndicatorTintColor : pageIndicatorTintColor
            }
            indicatorView.isHidden = false
            index += 1
        }
    }
}
// MARK: - layout
extension HHPageControl {
    private func layoutIndicatorViews() {
        if indicatorViews.count == 0 {
            return
        }
        var orignX: CGFloat = 0
        var centerY: CGFloat = 0
        var pageIndicatorSpaing: CGFloat = self.pageIndicatorSpaing
        let count = indicatorViews.count
        switch contentHorizontalAlignment {
        case .center:
            // ignore contentInset
            orignX = (self.frame.width - CGFloat(count - 1) * (pageIndicatorSize.width + pageIndicatorSpaing) - currentPageIndicatorSize.width) * 0.5
        case .left:
            orignX = contentInset.left
        case .right:
            orignX = self.frame.width - (CGFloat(count - 1) * (pageIndicatorSize.width + pageIndicatorSpaing) + currentPageIndicatorSize.width) - contentInset.right
        case .fill:
            orignX = contentInset.left
            if (indicatorViews.count > 1) {
                pageIndicatorSpaing = (self.frame.width - contentInset.left - contentInset.right - pageIndicatorSize.width - CGFloat(count - 1) * pageIndicatorSize.width) / (CGFloat)(count - 1)
            }
        default:
            break
        }
        switch contentVerticalAlignment {
        case .center:
            centerY = self.frame.height * 0.5
        case .top:
            centerY = contentInset.top + currentPageIndicatorSize.height * 0.5
        case .bottom:
            centerY = self.frame.height - currentPageIndicatorSize.height * 0.5 - contentInset.bottom
        case .fill:
            centerY = (self.frame.height - contentInset.top - contentInset.bottom) * 0.5 + contentInset.top
            
        default:
            break
        }
        var index = 0
        for indicatorView in indicatorViews {
            if (pageIndicatorImage != nil) {
                indicatorView.layer.cornerRadius = 0
            }else {
                indicatorView.layer.cornerRadius = currentPage == index ? currentPageIndicatorSize.height * 0.5 : pageIndicatorSize.height * 0.5
            }
            let size: CGSize = index == currentPage ? currentPageIndicatorSize : pageIndicatorSize
            indicatorView.frame = CGRect(x: orignX, y: centerY - size.height * 0.5, width: size.width, height: size.height)
            orignX += size.width + pageIndicatorSpaing
            index += 1
        }
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutIndicatorViews()
    }
}
