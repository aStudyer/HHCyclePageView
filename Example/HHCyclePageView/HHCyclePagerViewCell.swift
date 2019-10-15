
//
//  HHCyclePagerViewCell.swift
//  HHCyclePageView_Example
//
//  Created by aStudyer立 on 2019/10/15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class HHCyclePagerViewCell: UICollectionViewCell {
    private(set) lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        addSubview(label)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        addSubview(label)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
}
