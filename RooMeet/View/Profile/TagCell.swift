//
//  TagCell.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/11.
//

import UIKit
import TTGTags

protocol TagCellDelegate: AnyObject {
    func tagCell(cell: TagCell, selectedTags: [String])
}

class TagCell: UICollectionViewCell {
    static let identifier = "TagCell"
    @IBOutlet weak var tagView: TTGTextTagCollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    var tags: [String] = []
    var selectedTags: [String] = []
    weak var delegate: TagCellDelegate?

    @IBOutlet weak var tagButton: UIButton! {
        didSet {
            tagButton.isEnabled = false
            tagButton.layer.cornerRadius = RMConstants.shared.tagCornerRadius
            tagButton.titleLabel!.font = UIFont.regular(size: 12)
            tagButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        tagView.delegate = self
    }

    func configureCell(data: String) {
        tagButton.setTitle(data, for: .normal)
    }

    func configureTagView(
        tags: [String],
        selectedTags: [String],
        mainColor: UIColor,
        lightColor: UIColor, mainLightBackgroundColor: UIColor
    ) {
//        titleLabel.text = "找房要求"
        for text in tags {
            let content = TTGTextTagStringContent.init(text: text)
            content.textColor = .darkGray
            content.textFont = UIFont.regular(size: 14)!

            let normalStyle = TTGTextTagStyle.init()
            normalStyle.backgroundColor = .white
            normalStyle.shadowColor = .clear
            normalStyle.borderWidth = 1
            normalStyle.borderColor = .lightGray
            normalStyle.extraSpace = CGSize.init(width: 8, height: 8)

            let selectedContent = TTGTextTagStringContent.init(text: text)
            selectedContent.textColor = lightColor
            selectedContent.textFont = UIFont.regular(size: 14)!
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

            tagView.addTag(tag)
        }

        tagView.reload()
    }
}

extension TagCell: TTGTextTagCollectionViewDelegate {
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTap tag: TTGTextTag!, at index: UInt) {
        var selectedTags: [String] = []

        tagView.allSelectedTags().forEach({ tag in
            guard let tag = tag as? RMTag else {
                return
            }
            selectedTags.append(tag.title!)
        })

        delegate?.tagCell(cell: self, selectedTags: selectedTags)
    }
}
