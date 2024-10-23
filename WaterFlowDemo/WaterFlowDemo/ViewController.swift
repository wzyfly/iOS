//
//  ViewController.swift
//  WaterFlowDemo
//
//  Created by wangzhiyi on 2024/10/23.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CollectionWaterfallLayoutProtocol  {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let waterfallLayout = CollectionWaterfallLayout()
        waterfallLayout.delegate = self
        waterfallLayout.insets = .init(top: 20, left: 10, bottom: 30, right: 10);
        
        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: waterfallLayout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")
        collectionView.isScrollEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        
        self.view.addSubview(collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
        let tag = 8888
        var label = cell.contentView.viewWithTag(tag) as? UILabel
        if label == nil {
            label = UILabel()
            label!.textColor = .white
            label!.tag = tag
            cell.contentView.addSubview(label!)
        }
        label?.text = "\(indexPath.section) - \(indexPath.row)"
        label?.sizeToFit()
        
        let randomInt = Int.random(in: 0...3)
        let colors = [UIColor.red, UIColor.green, UIColor.purple, UIColor.blue]
        cell.contentView.backgroundColor = colors[randomInt]
        return cell
    }
    
    // MARK: - - CollectionWaterfallLayout delegate
    
    func collectionViewLayout(_ layout: CollectionWaterfallLayout, heightForItemAt indexPath: IndexPath) -> CGFloat {
        let randomInt = Int.random(in: 3...50) + 20
        return CGFloat(randomInt)
    }
    
    func collectionViewLayout(_ layout: CollectionWaterfallLayout, heightForSupplementaryViewAt indexPath: IndexPath) -> CGFloat {
        return 20
    }
    
    
    func collectionViewLayout(_ layout: CollectionWaterfallLayout, configAtSection section: Int) -> CollectionWaterfallSectionConfig {
        let config = CollectionWaterfallSectionConfig.default()
        config.columns = UInt(section + 2)
        config.xSpacing = CGFloat(5 * section)
        config.ySpacing = 10
        return config
    }
}

