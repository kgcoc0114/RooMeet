//
//  ItemsCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/15.
//

import UIKit
import TTGTags

protocol ItemsCellDelegate: AnyObject {
    func itemsCell(cell: ItemsCell, selectedTags: [String])
}


class ItemsCell: UICollectionViewCell {
    static let reuseIdentifier = "\(ItemsCell.self)"
    var tags: [String] = []
    var ruleType: String = ""
    var textFont: CGFloat = 15
    var previousSelection: UInt?

    weak var delegate: ItemsCellDelegate?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagView: TTGTextTagCollectionView!

    override func prepareForReuse() {
        super.prepareForReuse()
        tagView.removeAllTags()
    }

    override func awakeFromNib() {
        tagView.delegate = self
    }

    func configureTagView(ruleType: String, tags: [String], selectedTags: [String], mainColor: UIColor, lightColor: UIColor, mainLightBackgroundColor: UIColor, enableTagSelection: Bool) {
        titleLabel.text = ruleType
        tagView.enableTagSelection = enableTagSelection
        for text in tags {
            let content = TTGTextTagStringContent.init(text: text)
            content.textColor = .darkGray
            content.textFont = UIFont.regular(size: textFont)!

            let normalStyle = TTGTextTagStyle.init()
            normalStyle.backgroundColor = .white
            normalStyle.shadowColor = .clear
            normalStyle.borderWidth = 1
            normalStyle.borderColor = .lightGray
            normalStyle.extraSpace = CGSize.init(width: 8, height: 8)

            let selectedContent = TTGTextTagStringContent.init(text: text)
            selectedContent.textColor = lightColor
            selectedContent.textFont = UIFont.regular(size: textFont)!
            let selectedStyle = TTGTextTagStyle.init()
            selectedStyle.backgroundColor = mainColor
            selectedStyle.shadowColor = .clear
            selectedStyle.borderWidth = 0
            selectedStyle.extraSpace = CGSize.init(width: 8, height: 8)

            let tag = RMTag.init()
            tag.title = text
            tag.content = content
            tag.selectedContent = selectedContent
            tag.style = normalStyle
            tag.selectedStyle = selectedStyle
            if enableTagSelection {
                tag.selected = selectedTags.contains(text)
            }
            tagView.addTag(tag)
        }

        tagView.reload()
    }
}

extension ItemsCell: TTGTextTagCollectionViewDelegate {
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTap tag: TTGTextTag!, at index: UInt) {
        var selectedTags: [String] = []

        tagView.allSelectedTags().forEach({ tag in
            guard let tag = tag as? RMTag else {
                return
            }
            selectedTags.append(tag.title!)
        })

        delegate?.itemsCell(cell: self, selectedTags: selectedTags)
    }
}

class RMTag: TTGTextTag {
    var title: String?
}
