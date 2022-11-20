//
//  MultipleChooseViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/18.
//

import UIKit
import TTGTags

class MultipleChooseViewController: RMButtomSheetViewController {
    enum EntryPage {
        case intro
        case post

        var title: String {
            switch self {
            case .intro:
                return ""
            case .post:
                return "設施"
            }
        }
    }

    var completion: (([String]) -> Void)?
    var options: [String] = []

    lazy var titleLabel: UILabel! = {
        let label = UILabel()
        label.font = UIFont.bold(size: 18)
        label.textColor = UIColor.mainColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()


    lazy var tagView: TTGTextTagCollectionView! = {
        let view = TTGTextTagCollectionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        tagView.delegate = self
        defaultHeight = 300
        currentContainerHeight = 300

        setupBaseView()
        setupBaseConstraints()
    }

    func configureLayout() {
        containerView.addSubview(titleLabel)
        containerView.addSubview(tagView)

        // Set static constraints
        NSLayoutConstraint.activate([
            // titleLabel
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            // countyTableView
            tagView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            tagView.trailingAnchor.constraint(equalTo: containerView.centerXAnchor),
            tagView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tagView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)
        ])
    }

    func configureTagView(
        entryPage: EntryPage,
        tags: [String],
        selectedTags: [String],
        mainColor: UIColor,
        lightColor: UIColor, mainLightBackgroundColor: UIColor
    ) {
        titleLabel.text = entryPage.title

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
            tag.selected = selectedTags.contains(text)
            tagView.addTag(tag)
        }

        tagView.reload()
    }
}

extension MultipleChooseViewController: TTGTextTagCollectionViewDelegate {
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTap tag: TTGTextTag!, at index: UInt) {
        var selectedTags: [String] = []

        tagView.allSelectedTags().forEach({ tag in
            guard let tag = tag as? RMTag else {
                return
            }
            selectedTags.append(tag.title!)
        })

        completion?(selectedTags)
    }
}
