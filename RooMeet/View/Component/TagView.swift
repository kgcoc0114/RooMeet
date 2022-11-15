//
//  TagView.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/15.
//
import TTGTags

protocol TagViewDelegate: AnyObject {
    func tagView(at index: UInt)
}

class TagView: UIView {
    var tags: [String] = []
    var textFont: CGFloat = 17
    lazy var tagView: TTGTextTagCollectionView = {
        let view = TTGTextTagCollectionView()
        return view
    }()

    weak var delegate: TagViewDelegate?

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(tagView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(tagView)
    }
    
    func configureTagView(tags: [String], mainColor: UIColor, lightColor: UIColor, mainLightBackgroundColor: UIColor) {

        tagView.delegate = self

        for text in tags {
            let content = TTGTextTagStringContent.init(text: text)
            content.textColor = mainColor
            content.textFont = UIFont.regular(size: textFont)!

            let normalStyle = TTGTextTagStyle.init()
            normalStyle.backgroundColor = mainLightBackgroundColor
            normalStyle.borderWidth = 0
            normalStyle.extraSpace = CGSize.init(width: 5, height: 5)

            let selectedContent = TTGTextTagStringContent.init(text: text)
            selectedContent.textColor = lightColor
            selectedContent.textFont = UIFont.regular(size: textFont)!
            let selectedStyle = TTGTextTagStyle.init()
            selectedStyle.backgroundColor = mainColor
            selectedStyle.borderWidth = 0
            selectedStyle.extraSpace = CGSize.init(width: 5, height: 5)

            let tag = TTGTextTag.init()
            tag.content = content
            tag.selectedContent = selectedContent
            tag.style = normalStyle
            tag.selectedStyle = selectedStyle

            tagView.addTag(tag)
        }

        tagView.reload()
    }
}

extension TagView: TTGTextTagCollectionViewDelegate {
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTap tag: TTGTextTag!, at index: UInt) {
        delegate?.tagView(at: index)
    }
}
