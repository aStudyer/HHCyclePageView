//
//  ViewController.swift
//  HHCyclePageView
//
//  Created by aStudyer on 10/10/2019.
//  Copyright (c) 2019 aStudyer. All rights reserved.
//

import UIKit
import HHCyclePageView

class ViewController: UIViewController {
    @IBOutlet weak var horCenterSwitch: UISwitch!
    private lazy var datas: [UIColor] = [UIColor]()
    private lazy var pageView: HHCyclePageView = {
        let pageView = HHCyclePageView()
        pageView.layer.borderWidth = 1
        pageView.isInfiniteLoop = true
        pageView.autoScrollInterval = 3.0
        pageView.dataSource = self
        pageView.delegate = self
        // registerClass or registerNib
        pageView.registerClass(cls: HHCyclePagerViewCell.self, withReuseIdentifier: "CellID")
        return pageView
    }()
    private lazy var pageControl: HHPageControl = {
        let pageControl = HHPageControl()
        pageControl.currentPageIndicatorSize = CGSize(width: 6, height: 6)
        pageControl.pageIndicatorSize = CGSize(width: 12, height: 6)
        pageControl.currentPageIndicatorTintColor = UIColor.red
        pageControl.pageIndicatorTintColor = UIColor.gray
        return pageControl
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "HHCyclePageView"
        view.addSubview(pageView)
        pageView.addSubview(pageControl)
        loadData()
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        pageView.frame = CGRect(x: 0, y: 64, width: view.frame.width, height: 200)
        pageControl.frame = CGRect(x: 0, y: pageView.frame.height - 26, width: pageView.frame.width, height: 26)
    }
    @IBAction func switchValueDidChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 0:
            pageView.isInfiniteLoop = sender.isOn
            pageView.updateData()
        case 1:
            pageView.autoScrollInterval = sender.isOn ? 3.0 : 0
        case 2:
            pageView.layout!.itemHorizontalCenter = sender.isOn
            UIView.animate(withDuration: 0.3) {
                self.pageView.setNeedUpdateLayout()
            }
        default:
            break
        }
    }
    @IBAction func sliderValueDidChanged(_ sender: UISlider) {
        switch sender.tag {
        case 0:
            pageView.layout!.itemSize = CGSize(width: pageView.frame.width * CGFloat(sender.value), height: pageView.frame.height * CGFloat(sender.value))
            pageView.setNeedUpdateLayout()
        case 1:
            pageView.layout!.itemSpacing = CGFloat(30 * sender.value)
            pageView.setNeedUpdateLayout()
        case 2:
            pageControl.pageIndicatorSize = CGSize(width: CGFloat(6*(1+sender.value)), height: CGFloat(6*(1+sender.value)))
            pageControl.currentPageIndicatorSize = CGSize(width: CGFloat(8*(1+sender.value)), height: CGFloat(8*(1+sender.value)))
            pageControl.pageIndicatorSpaing = CGFloat((1+sender.value)*10)
        default:
            break
        }
    }
    @IBAction func btnDidClicked(_ sender: UIButton) {
        var layoutType: HHCyclePageViewLayoutType = .normal
        switch sender.tag {
        case 0:
           layoutType = .normal
        case 1:
            layoutType = .linear
        case 2:
            layoutType = .coverflow
        default:
            break
        }
        pageView.layout!.layoutType = layoutType
        pageView.setNeedUpdateLayout()
    }
}
extension ViewController {
    private func loadData() {
        for i in 0..<7 {
            if 0 == i {
                datas.append(UIColor.red)
                continue
            }
            datas.append(UIColor(red: CGFloat(arc4random_uniform(256))/255.0, green: CGFloat(arc4random_uniform(256))/255.0, blue: CGFloat(arc4random_uniform(256))/255.0, alpha: 1.0))
        }
        pageControl.numberOfPages = datas.count
        pageView.reloadData()
    }
}
extension ViewController: HHCyclePageViewDataSource, HHCyclePageViewDelegate {
    func numberOfItems(in pageView: HHCyclePageView) -> Int {
        return datas.count
    }
    func pageView(_ pageView: HHCyclePageView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pageView.dequeueReusableCell(withReuseIdentifier: "CellID", index: index) as! HHCyclePagerViewCell
        cell.backgroundColor = datas[index]
        cell.label.text = "index->\(index)"
        return cell
    }
    func layoutForPageView(_ pageView: HHCyclePageView) -> HHCyclePageViewLayout {
        let layout = HHCyclePageViewLayout()
        layout.itemSize = CGSize(width: pageView.frame.width * 0.8, height: pageView.frame.height * 0.8)
        layout.itemSpacing = 15
        layout.itemHorizontalCenter = horCenterSwitch.isOn
        return layout
    }
    func pageView(_ pageView: HHCyclePageView, didScrollFrom from: Int, to: Int) {
        pageControl.currentPage = to
        print("from:\(from) to:\(to)")
    }
}
