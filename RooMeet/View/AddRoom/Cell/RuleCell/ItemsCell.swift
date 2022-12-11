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
    var rules: [String] = RMConstants.shared.roomHighLights
    + RMConstants.shared.roomCookingRules
    + RMConstants.shared.roomElevatorRules
    + RMConstants.shared.roomBathroomRules
    + RMConstants.shared.roomPetsRules

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

        if let tmpRemoveIndex = self.rules.firstIndex(of: "可議") {
            self.rules.remove(at: tmpRemoveIndex)
        }
    }

    func configureTitleInDetailPage() {
        titleLabel.font = UIFont.regularTitle()
        titleLabel.textColor = UIColor.mainColor
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
            normalStyle.cornerRadius = RMConstants.shared.messageCornerRadius
            normalStyle.extraSpace = CGSize.init(width: 10, height: 8)

            let selectedContent = TTGTextTagStringContent.init(text: text)
            selectedContent.textColor = lightColor
            selectedContent.textFont = UIFont.regularText()

            let selectedStyle = TTGTextTagStyle.init()
            selectedStyle.backgroundColor = mainColor
            selectedStyle.shadowColor = .clear
            selectedStyle.borderWidth = 0
            selectedStyle.extraSpace = CGSize.init(width: 10, height: 8)
            selectedStyle.cornerRadius = RMConstants.shared.messageCornerRadius

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

extension ItemsCell: RoomDetailCell {
    func configure(container: RoomDetailContainer) {
        guard
            let data = (container as? RoomTagContainer)
        else {
            return
        }

        configureTitleInDetailPage()
        configureTagView(
            ruleType: data.title,
            tags: data.tags,
            selectedTags: data.tags,
            mainColor: data.mainColor,
            lightColor: data.lightColor,
            mainLightBackgroundColor: UIColor.white,
            enableTagSelection: false)
    }
}

extension ItemsCell: IntroDataCell {
    func configure(for introScenario: IntroScenario) {
        configureTagView(
            ruleType: "要求",
            tags: self.rules,
            selectedTags: introScenario.user?.rules ?? [],
            mainColor: UIColor.mainColor,
            lightColor: UIColor.mainLightColor,
            mainLightBackgroundColor: UIColor.mainBackgroundColor,
            enableTagSelection: true
        )
    }
}

extension ItemsCell: PostCell {
    func configure(container: RMCellContainer) {
        guard let data = (container as? PostDataContainer) else { return }
        configureTagView(
            ruleType: data.section?.title ?? "",
            tags: data.tags,
            selectedTags: data.selectedTags,
            mainColor: .mainColor,
            lightColor: .mainLightColor,
            mainLightBackgroundColor: .mainBackgroundColor,
            enableTagSelection: true
        )
    }
}

class RMTag: TTGTextTag {
    var title: String?
}
