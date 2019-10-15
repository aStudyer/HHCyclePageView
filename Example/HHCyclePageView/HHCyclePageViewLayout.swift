//
//  HHCyclePageViewLayout.swift
//  HHCyclePageView_Example
//
//  Created by aStudyer立 on 2019/10/10.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

struct HHCyclePageTransformLayoutDelegateFlags {
    var apply = true
    var initialize = true
}

enum HHCyclePageViewLayoutType {
    case normal
    case linear
    case coverflow
}

enum HHCyclePageViewLayoutDirection {
    case left
    case center
    case right
}

@objc protocol HHCyclePageViewLayoutDelegate: NSObjectProtocol {
    /// initialize layout attributes
    func initialize(_ layout: HHCyclePageTransformLayout, attributes: UICollectionViewLayoutAttributes)
    /// apply layout attributes
    func apply(_ layout: HHCyclePageTransformLayout, attributes: UICollectionViewLayoutAttributes)
}

class HHCyclePageViewLayout: NSObject {
    var itemSize: CGSize = .zero
    var itemSpacing: CGFloat = 0
    var sectionInset: UIEdgeInsets = .zero
    var layoutType: HHCyclePageViewLayoutType = .normal
    
    var minimumScale: CGFloat = 0.8
    var minimumAlpha: CGFloat = 1.0
    var maximumAngle: CGFloat = 0.2
    
    var isInfiniteLoop: Bool = true
    var rateOfChange: CGFloat = 0.4
    
    var adjustSpacingWhenScroling: Bool = true
    /// pageView cell item vertical centering
    var itemVerticalCenter: Bool = true
    /// first and last item horizontalc enter, when isInfiniteLoop is NO
    var itemHorizontalCenter: Bool = true
    
    weak var pageView: UIView?
    
    /// sectionInset
    var middleSectionInset: UIEdgeInsets {
        get{
            if (itemVerticalCenter) {
                let verticalSpace = (pageView!.frame.height - itemSize.height) * 0.5
                return UIEdgeInsets(top: verticalSpace, left: 0, bottom: verticalSpace, right: itemSpacing)
            }
            return sectionInset
        }
    }
    var lastSectionInset: UIEdgeInsets {
        get{
            if (itemVerticalCenter) {
                let verticalSpace = (pageView!.frame.height - itemSize.height) * 0.5
                return UIEdgeInsets(top: verticalSpace, left: 0, bottom: verticalSpace, right: sectionInset.right)
            }
            return UIEdgeInsets(top: sectionInset.top, left: 0, bottom: sectionInset.bottom, right: sectionInset.right)
        }
    }
     var firstSectionInset: UIEdgeInsets {
        get{
            if (itemVerticalCenter) {
                let verticalSpace = (pageView!.frame.height - itemSize.height) * 0.5
                return UIEdgeInsets(top: verticalSpace, left: sectionInset.left, bottom: verticalSpace, right: itemSpacing)
            }
            return UIEdgeInsets(top: sectionInset.top, left: sectionInset.left, bottom: sectionInset.bottom, right: itemSpacing)
        }
    }
    var onlyOneSectionInset: UIEdgeInsets {
        get{
            let leftSpace = !isInfiniteLoop && itemHorizontalCenter ? (pageView!.frame.width - itemSize.width) * 0.5 : sectionInset.left
            let rightSpace = !isInfiniteLoop && itemHorizontalCenter ? (pageView!.frame.width - itemSize.width) * 0.5 : sectionInset.right
            if (itemVerticalCenter) {
                let verticalSpace = (pageView!.frame.height - itemSize.height) * 0.5
                return UIEdgeInsets(top: verticalSpace, left: leftSpace, bottom: verticalSpace, right: rightSpace)
            }
            return UIEdgeInsets(top: sectionInset.top, left: leftSpace, bottom: sectionInset.bottom, right: rightSpace)
        }
    }
}

class HHCyclePageTransformLayout: UICollectionViewFlowLayout {
    var layout: HHCyclePageViewLayout? {
        didSet {
            layout?.pageView = collectionView
            itemSize = layout?.itemSize ?? super.itemSize
            minimumInteritemSpacing = layout?.itemSpacing ?? super.minimumInteritemSpacing
            minimumLineSpacing = layout?.itemSpacing ?? super.minimumLineSpacing
        }
    }
    weak var delegate: HHCyclePageViewLayoutDelegate? {
        didSet{
            delegateFlags.initialize = delegate?.responds(to: #selector(HHCyclePageViewLayoutDelegate.initialize(_:attributes:))) ?? false
            delegateFlags.apply = delegate?.responds(to: #selector(HHCyclePageViewLayoutDelegate.apply(_:attributes:))) ?? false
        }
    }
    private lazy var delegateFlags: HHCyclePageTransformLayoutDelegateFlags = HHCyclePageTransformLayoutDelegateFlags()
    
    override init() {
        super.init()
        scrollDirection = .horizontal
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scrollDirection = .horizontal
    }
}

// MARK: - 私有方法
extension HHCyclePageTransformLayout {
    private func direction(_ centerX: CGFloat) -> HHCyclePageViewLayoutDirection {
        var direction: HHCyclePageViewLayoutDirection = .right
        let contentCenterX = collectionView!.contentOffset.x + collectionView!.frame.width * 0.5
        if abs(centerX - contentCenterX) < 0.5 {
            direction = .center
        }else if centerX < contentCenterX {
            direction = .left
        }
        return direction;
    }
}

// MARK: - layout
extension HHCyclePageTransformLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return (layout?.layoutType == .normal) ? super.shouldInvalidateLayout(forBoundsChange: newBounds) : true
    }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if delegateFlags.apply || layout?.layoutType != .normal {
            let attributes_array = super.layoutAttributesForElements(in: rect)!
            let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
            for attributes in attributes_array {
                if !(visibleRect.intersects(attributes.frame)) {
                    continue
                }
                if delegateFlags.apply {
                    delegate?.apply(self, attributes: attributes)
                }else {
                    apply(attributes)
                }
            }
            return attributes_array
        }
        return super.layoutAttributesForElements(in: rect)
    }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        if delegateFlags.initialize, let attributes = attributes {
            delegate?.initialize(self, attributes: attributes)
        }else if layout?.layoutType != .normal, let attributes = attributes {
            initialize(attributes)
        }
        return attributes
    }
}

// MARK: - transform
extension HHCyclePageTransformLayout {
    private func initialize(_ attributes: UICollectionViewLayoutAttributes) {
        switch layout?.layoutType ?? .normal {
        case .linear:
            applyLinearTransform(attributes, scale: layout?.minimumScale ?? 0, alpha: layout?.minimumAlpha ?? 0)
            break
        case .coverflow:
            applyCoverflowTransform(attributes, angle: layout?.maximumAngle ?? 0, alpha: layout?.minimumAlpha ?? 0)
            break
            
        default:
            break
        }
    }
    
    private func apply(_ attributes: UICollectionViewLayoutAttributes) {
        switch layout?.layoutType ?? .normal {
        case .linear:
            applyLinearTransform(attributes)
            break
        case .coverflow:
            applyCoverflowTransform(attributes)
            break
        default:
            break
        }
    }
}

// MARK: - LinearTransform
extension HHCyclePageTransformLayout {
    private func applyLinearTransform(_ attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView = collectionView, let layout = layout else {
            return
        }
        let collectionViewWidth = collectionView.frame.width
        if collectionViewWidth <= 0 {
            return
        }
        let centetX = collectionView.contentOffset.x + collectionViewWidth * 0.5
        let delta = abs(attributes.center.x - centetX)
        let scale = max(1 - delta / collectionViewWidth * layout.rateOfChange, layout.minimumScale)
        let alpha = max(1 - delta / collectionViewWidth, layout.minimumAlpha)
        applyLinearTransform(attributes, scale: scale, alpha: alpha)
    }
    private func applyLinearTransform(_ attributes: UICollectionViewLayoutAttributes, scale: CGFloat, alpha: CGFloat) {
        guard let layout = layout else {
            return
        }
        var alpha = alpha
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        if (layout.adjustSpacingWhenScroling) {
            let direction = self.direction(attributes.center.x)
            var translate: CGFloat = 0
            switch (direction) {
            case .left:
                translate = 1.15 * attributes.size.width * (1 - scale) * 0.5
            case .right:
                translate = -1.15 * attributes.size.width * (1 - scale) * 0.5
            case .center:
                alpha = 1.0
            }
            transform = transform.translatedBy(x: translate, y: 0)
        }
        attributes.transform = transform
        attributes.alpha = alpha
    }
}

// MARK: - CoverflowTransform
extension HHCyclePageTransformLayout {
    private func applyCoverflowTransform(_ attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView = collectionView, let layout = layout else {
            return
        }
        let collectionViewWidth = collectionView.frame.width
        if (collectionViewWidth <= 0) {
            return
        }
        let centetX = collectionView.contentOffset.x + collectionViewWidth * 0.5
        let delta = abs(attributes.center.x - centetX)
        let angle = min(delta / collectionViewWidth * (1 - layout.rateOfChange), layout.maximumAngle)
        let alpha = max(1 - delta / collectionViewWidth, layout.minimumAlpha)
        
        applyCoverflowTransform(attributes, angle: angle, alpha: alpha)
    }
    private func applyCoverflowTransform(_ attributes: UICollectionViewLayoutAttributes, angle: CGFloat, alpha: CGFloat) {
        let direction = self.direction(attributes.center.x)
        var angle = angle
        var alpha = alpha
        var transform3D = CATransform3DIdentity
        transform3D.m34 = -0.002
        var translate: CGFloat = 0
        switch (direction) {
        case .left:
            translate = (1 - cos(angle * 1.2 * CGFloat.pi)) * attributes.size.width
        case .right:
            translate = -(1 - cos(angle * 1.2 * CGFloat.pi)) * attributes.size.width
            angle = -angle;
        case .center:
            angle = 0
            alpha = 1
        }
        transform3D = CATransform3DRotate(transform3D, CGFloat.pi * angle, 0, 1, 0)
        if let _ = layout?.adjustSpacingWhenScroling {
            transform3D = CATransform3DTranslate(transform3D, translate, 0, 0)
        }
        attributes.transform3D = transform3D;
        attributes.alpha = alpha;
    }
}
