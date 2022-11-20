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
    var previousSelection: UInt?

    weak var delegate: ItemsCellDelegate?

    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.regularSubTitle()
            titleLabel.tintColor = UIColor.mainDarkColor
        }
    }
    @IBOutlet weak var tagView: TTGTextTagCollectionView!

    override func prepareForReuse() {
        super.prepareForReuse()
        tagView.removeAllTags()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        tagView.delegate = self
    }

    func configureTitleInDetailPage() {
        titleLabel.font = UIFont.regularTitle()
        titleLabel.textColor = UIColor.main
    }

    func configureTagView(ruleType: String, tags: [String], selectedTags: [String], mainColor: UIColor, lightColor: UIColor, mainLightBackgroundColor: UIColor, enableTagSelection: Bool) {

        if tags.isEmpty {
            self.isHidden = true
            self.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.heightAnchor.constraint(equalToConstant: 0)
            ])
        }
        self.ruleType = ruleType
        titleLabel.text = ruleType
        tagView.enableTagSelection = enableTagSelection
        for text in tags {
            let content = TTGTextTagStringContent.init(text: text)
            content.textColor = .darkGray
            content.textFont = UIFont.regularText()

            let normalStyle = TTGTextTagStyle.init()
            normalStyle.backgroundColor = .white
            normalStyle.shadowColor = .clear
            normalStyle.borderWidth = 1
            normalStyle.borderColor = .lightGray
            normalStyle.extraSpace = CGSize.init(width: 8, height: 8)

            let selectedContent = TTGTextTagStringContent.init(text: text)
            selectedContent.textColor = lightColor
            selectedContent.textFont = UIFont.regularText()

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
        tagView.allSelectedTags().forEach { tag in
            guard
                let tag = tag as? RMTag,
                let title = tag.title else {
                return
            }
            selectedTags.append(title)
        }

        delegate?.itemsCell(cell: self, selectedTags: selectedTags)
    }
}

class RMTag: TTGTextTag {
    var title: String?
}
