//
//  HHCyclePageView.swift
//  HHCyclePageView_Example
//
//  Created by aStudyer立 on 2019/10/10.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

// pagerView scrolling direction
private enum HHCyclePageViewScrollDirection {
    case left
    case right
}
private struct HHCyclePageViewDelegateFlags {
    var pageViewDidScroll = true
    var didScrollFromIndexToNewIndex = true
    var initializeTransformAttributes = true
    var applyTransformToAttributes = true
}
private struct HHCyclePageViewDataSourceFlags {
    var cellForItemAtIndex = true
    var layoutForPageView = true
}

@objc protocol HHCyclePageViewDataSource: NSObjectProtocol {
    func numberOfItems(in pageView: HHCyclePageView) -> Int
    
    func pageView(_ pageView: HHCyclePageView, cellForItemAt index: Int) -> UICollectionViewCell

    /// return pagerView layout,and cache layout
    func layoutForPageView(_ pageView: HHCyclePageView) -> HHCyclePageViewLayout
}
@objc protocol HHCyclePageViewDelegate: NSObjectProtocol {
    @objc optional
    /// pagerView did scroll to new index page
    func pageView(_ pageView: HHCyclePageView, didScrollFrom from: Int, to: Int)
    @objc optional
    /// pagerView did selected item cell
    func pageView(_ pageView: HHCyclePageView, didSelectItemAt indexPath: IndexPath)
    @objc optional
    // custom layout
    func pageView(_ pageView: HHCyclePageView, initializeTransform attributes: UICollectionViewLayoutAttributes)
    @objc optional
    func pageView(_ pageView: HHCyclePageView, applyTransform attributes: UICollectionViewLayoutAttributes)
    
    @objc optional
    // scrollViewDelegate
    func pageViewDidScroll(_ pageView: HHCyclePageView)
    @objc optional
    func pageViewWillBeginDragging(_ pageView: HHCyclePageView)
    @objc optional
    func pageViewDidEndDragging(_ pageView: HHCyclePageView, willDecelerate decelerate: Bool)
    @objc optional
    func pageViewWillBeginDecelerating(_ pageView: HHCyclePageView)
    @objc optional
    func pageViewDidEndDecelerating(_ pageView: HHCyclePageView)
    @objc optional
    func pageViewWillBeginScrollingAnimation(_ pageView: HHCyclePageView)
    @objc optional
    func pageViewDidEndScrollingAnimation(_ pageView: HHCyclePageView)
}
private let maxSectionCount: NSInteger = 3
private let minSectionCount: NSInteger = 3

class HHCyclePageView: UIView {
    var curIndexCell: UICollectionViewCell? {
        return collectionView.cellForItem(at: indexPath)
    }
    var visibleCells: [UICollectionViewCell] {
        return collectionView.visibleCells
    }
    var visibleIndexs: [IndexPath] {
        return collectionView.indexPathsForVisibleItems
    }
    /// will be automatically resized to track the size of the pagerView
    var backgroundView: UIView? {
        set{
            collectionView.backgroundView = newValue
        }
        get{
            return collectionView.backgroundView
        }
    }
    weak var dataSource: HHCyclePageViewDataSource?{
        didSet{
            guard let dataSource = dataSource else {
                return
            }
            dataSourceFlags.cellForItemAtIndex = dataSource.responds(to: #selector(HHCyclePageViewDataSource.pageView(_:cellForItemAt:)))
            dataSourceFlags.layoutForPageView = dataSource.responds(to: #selector(HHCyclePageViewDataSource.layoutForPageView(_:)))
        }
    }
    weak var delegate: HHCyclePageViewDelegate?{
        didSet{
            if let delegate = delegate {
                delegateFlags.pageViewDidScroll = delegate.responds(to: #selector(HHCyclePageViewDelegate.pageViewDidScroll(_:)))
                delegateFlags.didScrollFromIndexToNewIndex = delegate.responds(to: #selector(HHCyclePageViewDelegate.pageView(_:didScrollFrom:to:)))
                delegateFlags.initializeTransformAttributes = delegate.responds(to: #selector(HHCyclePageViewDelegate.pageView(_:initializeTransform:)))
                delegateFlags.applyTransformToAttributes = delegate.responds(to: #selector(HHCyclePageViewDelegate.pageView(_:applyTransform:)))
                let transformLayout = collectionView.collectionViewLayout as! HHCyclePageTransformLayout
                transformLayout.delegate = delegateFlags.applyTransformToAttributes ? self : nil
            }
        }
    }
    private var delegateFlags = HHCyclePageViewDelegateFlags()
    private var dataSourceFlags = HHCyclePageViewDataSourceFlags()
    /// page view, don't set dataSource and delegate
    private(set) lazy var collectionView: UICollectionView = {
        let layout = HHCyclePageTransformLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        layout.delegate = delegateFlags.applyTransformToAttributes ? self : nil
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = UIScrollView.DecelerationRate(rawValue: UIScrollView.DecelerationRate.RawValue(1-0.0076))
        if #available(iOS 10.0, *) {
            collectionView.isPrefetchingEnabled = false
        }
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    /// page view layout
    private var _layout: HHCyclePageViewLayout?
    var layout: HHCyclePageViewLayout? {
        set{
            _layout = newValue
        }
        get{
            if _layout == nil {
                if dataSourceFlags.layoutForPageView, let dataSource = dataSource {
                    _layout = dataSource.layoutForPageView(self)
                    _layout!.isInfiniteLoop = isInfiniteLoop
                }
                if let lay = _layout, lay.itemSize.width <= 0 || lay.itemSize.height <= 0 {
                    _layout = nil
                }
            }
            return _layout;
        }
    }
    /// is infinite cycle pageview
    var isInfiniteLoop: Bool = true
    /// pageView automatic scroll time interval, default 0,disable automatic
    var autoScrollInterval: CGFloat = 0{
        didSet{
            removeTimer()
            if autoScrollInterval > 0 && superview != nil {
                addTimer()
            }
        }
    }
    var reloadDataNeedResetIndex: Bool = false
    /// current page index
    private var curIndex: NSInteger{
        get{
            return indexPath.item
        }
    }
    private(set) var indexPath: IndexPath = IndexPath(row: -1, section: -1)
    // scrollView property
    private(set) var contentOffset: CGPoint {
        set{
            
        }
        get{
            return collectionView.contentOffset
        }
    }
    private var tracking: Bool {
        return collectionView.isTracking
    }
    private var dragging: Bool {
        return collectionView.isDragging
    }
    private var decelerating: Bool {
        return collectionView.isDecelerating
    }

    private var timer: Timer?
    
    // Data
    private var numberOfItems: NSInteger = 0
    private var dequeueSection: NSInteger = 0
    private var beginDragIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    private var firstScrollIndex: NSInteger = -1
    
    private var needClearLayout: Bool = false
    private var didReloadData: Bool = false
    private var didLayout: Bool = false
    private var needResetIndex: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(collectionView)
    }
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            removeTimer()
        }else{
            removeTimer()
            if autoScrollInterval > 0 {
                addTimer()
            }
        }
    }
    deinit {
        (collectionView.collectionViewLayout as! HHCyclePageTransformLayout).delegate = nil
        collectionView.delegate = nil;
        collectionView.dataSource = nil;
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let needUpdateLayout = !collectionView.frame.equalTo(self.bounds)
        collectionView.frame = self.bounds
        if indexPath.section < 0 || needUpdateLayout, numberOfItems > 0 || didReloadData {
            didLayout = true
            setNeedUpdateLayout()
        }
    }
}
// MARK: - timer
extension HHCyclePageView {
    private func addTimer() {
        if timer != nil || autoScrollInterval <= 0 {
            return
        }
        timer = Timer(timeInterval: TimeInterval(autoScrollInterval), target: self, selector: #selector(timerFired(timer:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
    private func removeTimer() {
        if timer == nil {
            return
        }
        timer!.invalidate()
        timer = nil
    }
    @objc private func timerFired(timer: Timer) {
        if superview == nil || window == nil || numberOfItems == 0 || tracking {
            return
        }
        scrollToNearlyIndex(atDirection: .right, animate: true)
    }
}
extension HHCyclePageView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return isInfiniteLoop ? maxSectionCount : 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfItems = dataSource?.numberOfItems(in: self) ?? 0
        return numberOfItems;
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        dequeueSection = indexPath.section
        if dataSourceFlags.cellForItemAtIndex, let dataSource = dataSource {
            return dataSource.pageView(self, cellForItemAt: indexPath.item)
        }
        assert(false, "pagerView cellForItemAtIndex: is nil!")
        return UICollectionViewCell()
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = delegate,
            let _ = collectionView.cellForItem(at: indexPath),
            delegate.responds(to: #selector(HHCyclePageViewDelegate.pageView(_:didSelectItemAt:))) {
            delegate.pageView!(self, didSelectItemAt: indexPath)
        }
    }
}
extension HHCyclePageView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if !isInfiniteLoop {
            return self.layout?.onlyOneSectionInset ?? .zero
        }
        if 0 == section {
            return self.layout?.firstSectionInset ?? .zero
        }else if maxSectionCount - 1 == section {
            return self.layout?.lastSectionInset ?? .zero
        }
        return self.layout?.middleSectionInset ?? .zero
    }
}
extension HHCyclePageView: HHCyclePageViewLayoutDelegate {
    func initialize(_ layout: HHCyclePageTransformLayout, attributes: UICollectionViewLayoutAttributes) {
        if delegateFlags.initializeTransformAttributes {
            delegate!.pageView!(self, initializeTransform: attributes)
        }
    }
    func apply(_ layout: HHCyclePageTransformLayout, attributes: UICollectionViewLayoutAttributes) {
        if delegateFlags.applyTransformToAttributes {
            delegate?.pageView!(self, applyTransform: attributes)
        }
    }
}
extension HHCyclePageView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !didLayout {
            return
        }
        let newIndexPath = caculateIndexPath()
        if numberOfItems <= 0 || !isValidIndexPath(newIndexPath) {
            print("inVlaidIndexSection:(\(newIndexPath.item),\(newIndexPath.section))!")
        }
        let indexPath = self.indexPath
        self.indexPath = newIndexPath
        if delegateFlags.pageViewDidScroll {
            delegate?.pageViewDidScroll!(self)
        }
        if delegateFlags.didScrollFromIndexToNewIndex && !(indexPath.elementsEqual(self.indexPath)) {
            delegate?.pageView!(self, didScrollFrom: max(indexPath.item, 0), to: self.indexPath.item)
        }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if autoScrollInterval > 0 {
            removeTimer()
        }
        beginDragIndexPath = caculateIndexPath()
        if let delegate = delegate, delegate.responds(to: #selector(HHCyclePageViewDelegate.pageViewWillBeginDragging(_:))) {
            delegate.pageViewWillBeginDragging!(self)
        }
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if abs(velocity.x) < 0.35 || !(beginDragIndexPath.elementsEqual(self.indexPath)) {
            targetContentOffset.pointee.x = caculateOffsetX(at: self.indexPath)
            return
        }
        var direction: HHCyclePageViewScrollDirection = .right
        if (scrollView.contentOffset.x < 0 && targetContentOffset.pointee.x <= 0) || ((targetContentOffset.pointee.x < scrollView.contentOffset.x) && (scrollView.contentOffset.x < (scrollView.contentSize.width - scrollView.frame.width))) {
            direction = .left
        }
        let indexPath = nearlyIndexPath(forIndexPath: self.indexPath, atDirection: direction)
        targetContentOffset.pointee.x = caculateOffsetX(at: indexPath)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if autoScrollInterval > 0 {
            addTimer()
        }
        if let delegate = delegate, delegate.responds(to: #selector(HHCyclePageViewDelegate.pageViewDidEndDragging(_:willDecelerate:))) {
            delegate.pageViewDidEndDragging!(self, willDecelerate: decelerate)
        }
    }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if let delegate = delegate, delegate.responds(to: #selector(HHCyclePageViewDelegate.pageViewWillBeginDecelerating(_:))) {
            delegate.pageViewWillBeginDecelerating!(self)
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        recyclePagerViewIfNeed()
        if let delegate = delegate, delegate.responds(to: #selector(HHCyclePageViewDelegate.pageViewDidEndDecelerating(_:))) {
            delegate.pageViewDidEndDecelerating!(self)
        }
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        recyclePagerViewIfNeed()
        if let delegate = delegate, delegate.responds(to: #selector(HHCyclePageViewDelegate.pageViewDidEndScrollingAnimation(_:))) {
            delegate.pageViewDidEndScrollingAnimation!(self)
        }
    }
}
// MARK: - page index
extension HHCyclePageView {
    private func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        return indexPath.item >= 0 && indexPath.item < numberOfItems && indexPath.section >= 0 && indexPath.section < maxSectionCount
    }
    private func nearlyIndexPath(atDirection direction: HHCyclePageViewScrollDirection) -> IndexPath {
        return nearlyIndexPath(forIndexPath: indexPath, atDirection: direction)
    }
    private func nearlyIndexPath(forIndexPath indexPath: IndexPath, atDirection direction: HHCyclePageViewScrollDirection) -> IndexPath {
        if (indexPath.item < 0 || indexPath.item >= numberOfItems) {
            return indexPath
        }
        
        if (!isInfiniteLoop) {
            if (direction == .right && indexPath.item == numberOfItems - 1) {
                return autoScrollInterval > 0 ? IndexPath(item: 0, section: 0) : indexPath
            } else if (direction == .right) {
                return IndexPath(item: indexPath.item + 1, section: 0)
            }
            if (indexPath.item == 0) {
                return autoScrollInterval > 0 ? IndexPath(item: numberOfItems - 1, section: 0) : indexPath
            }
            return IndexPath(item: indexPath.item - 1, section: 0)
        }
        if (direction == .right) {
            if (indexPath.item < numberOfItems - 1) {
                return IndexPath(item: indexPath.item + 1, section: indexPath.section)
            }
            if (indexPath.section >= maxSectionCount - 1) {
                return IndexPath(item: indexPath.item, section: maxSectionCount - 1)
            }
            
            return IndexPath(item: 0, section: indexPath.section + 1)
        }
        
        if (indexPath.item > 0) {
            return IndexPath(item: indexPath.item - 1, section: indexPath.section)
        }
        if (indexPath.section <= 0) {
            return IndexPath(item: indexPath.item, section: 0)
        }
        return IndexPath(item: numberOfItems - 1, section: indexPath.section - 1)
    }
    private func caculateIndexPath() -> IndexPath {
        guard numberOfItems > 0, let layout = layout else {
            return IndexPath(item: 0, section: 0)
        }
        let transformLayout = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
        let offsetX = collectionView.contentOffset.x
        let leftEdge = isInfiniteLoop ? layout.sectionInset.left : layout.onlyOneSectionInset.left
        let width = collectionView.frame.width
        let middleOffset = offsetX + width * 0.5
        let itemWidth = transformLayout.itemSize.width + transformLayout.minimumInteritemSpacing
        var curIndex = 0
        var curSection = 0
        if (middleOffset - leftEdge >= 0) {
            var itemIndex: Int = Int((middleOffset - leftEdge + transformLayout.minimumInteritemSpacing * 0.5) / itemWidth)
            if (itemIndex < 0) {
                itemIndex = 0
            }else if (itemIndex >= numberOfItems * maxSectionCount) {
                itemIndex = numberOfItems * maxSectionCount - 1
            }
            curIndex = itemIndex % numberOfItems
            curSection = itemIndex / numberOfItems
        }
        return IndexPath(item: curIndex, section: curSection)
    }
    private func caculateOffsetX(at indexPath: IndexPath) -> CGFloat {
        guard numberOfItems > 0, let layout = layout else {
            return 0
        }
        let transformLayout = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
        let edge = isInfiniteLoop ? layout.sectionInset : layout.onlyOneSectionInset
        let width = collectionView.frame.width
        let itemWidth = transformLayout.itemSize.width + transformLayout.minimumInteritemSpacing
        var offsetX: CGFloat = 0
        if !isInfiniteLoop && !layout.itemHorizontalCenter && indexPath.item == numberOfItems - 1 {
            offsetX = edge.left + itemWidth * (CGFloat(indexPath.item) + CGFloat(indexPath.section * numberOfItems)) - (width - itemWidth) -  transformLayout.minimumInteritemSpacing + edge.right
        }else {
            offsetX = edge.left + itemWidth * (CGFloat)(indexPath.item + indexPath.section * numberOfItems) - transformLayout.minimumInteritemSpacing * 0.5 - (width - itemWidth) * 0.5
        }
        return max(offsetX, 0)
    }
    private func resetPageView(atIndex index: NSInteger) {
        var tmp = index
        if didLayout && firstScrollIndex >= 0 {
            tmp = firstScrollIndex
            firstScrollIndex = -1
        }
        if tmp < 0 {
            return
        }
        if tmp >= numberOfItems {
            tmp = 0
        }
        scrollToItem(atIndexPath: IndexPath(item: tmp, section: isInfiniteLoop ? maxSectionCount/3 : 0), animate: false)
        if !isInfiniteLoop && indexPath.item < 0 {
            scrollViewDidScroll(collectionView)
        }
    }
    private func recyclePagerViewIfNeed() {
        if !isInfiniteLoop {
            return
        }
        if (indexPath.section > maxSectionCount - minSectionCount) ||
            indexPath.section < minSectionCount {
            resetPageView(atIndex: indexPath.item)
        }
    }
}
// MARK: - configure layout
extension HHCyclePageView {
    private func updateLayout() {
        guard let layout = layout else {
            return
        }
        layout.isInfiniteLoop = isInfiniteLoop
        (collectionView.collectionViewLayout as! HHCyclePageTransformLayout).layout = layout
    }
    private func clearLayout() {
        if needClearLayout {
            layout = nil
            needClearLayout = false
        }
    }
    private func setNeedClearLayout() {
        needClearLayout = true
    }
    func setNeedUpdateLayout() {
        guard let _ = layout else {
            return
        }
        clearLayout()
        updateLayout()
        collectionView.collectionViewLayout.invalidateLayout()
        resetPageView(atIndex: indexPath.item < 0 ? 0 : indexPath.item)
    }
}
// MARK: - not clear layout
extension HHCyclePageView {
    func updateData() {
        updateLayout()
        numberOfItems = dataSource?.numberOfItems(in: self) ?? 0
        collectionView.reloadData()
        if !didLayout && !collectionView.frame.isEmpty && indexPath.item < 0 {
            didLayout = true
        }
        let needResetIndex = self.needResetIndex && reloadDataNeedResetIndex
        self.needResetIndex = false
        if needResetIndex {
            removeTimer()
        }
        let index = ((indexPath.item < 0 && !collectionView.frame.isEmpty) || needResetIndex) ? 0 : indexPath.item
        resetPageView(atIndex: index)
        if needResetIndex {
            addTimer()
        }
    }
    private func scrollToNearlyIndex(atDirection direction: HHCyclePageViewScrollDirection, animate: Bool) {
        let indexPath = nearlyIndexPath(atDirection: direction)
        scrollToItem(atIndexPath: indexPath, animate: animate)
    }
    private func scrollToItem(atIndex index: NSInteger, animate: Bool){
        if !didLayout && didReloadData {
            firstScrollIndex = index
        }else {
            firstScrollIndex = -1
        }
        if !isInfiniteLoop {
            scrollToItem(atIndexPath: IndexPath(item: index, section: 0), animate: animate)
            return
        }
        scrollToItem(atIndexPath: IndexPath(item: index, section: index >= curIndex ? indexPath.section : indexPath.section + 1), animate: animate)
    }
    private func scrollToItem(atIndexPath indexPath: IndexPath, animate: Bool) {
        if numberOfItems <= 0 || !isValidIndexPath(indexPath) {
            return
        }
        if animate, let delegate = delegate, delegate.responds(to: #selector(HHCyclePageViewDelegate.pageViewWillBeginScrollingAnimation(_:))) {
            delegate.pageViewWillBeginScrollingAnimation!(self)
        }
        let offset = caculateOffsetX(at: indexPath)
        collectionView.setContentOffset(CGPoint(x: offset, y: collectionView.contentOffset.y), animated: animate)
    }
    func registerClass(cls: AnyClass, withReuseIdentifier identifier: String) {
        collectionView.register(cls, forCellWithReuseIdentifier: identifier)
    }
    func registerNib(nib: UINib, withReuseIdentifier identifier: String) {
        collectionView.register(nib, forCellWithReuseIdentifier: identifier)
    }
    func dequeueReusableCell(withReuseIdentifier identifier: String, index: NSInteger) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: IndexPath(item: index, section: dequeueSection));
        return cell
    }
}
// MARK: - public
extension HHCyclePageView {
    func reloadData() {
        didReloadData = true
        needResetIndex = true
        setNeedClearLayout()
        clearLayout()
        updateData()
    }
}
