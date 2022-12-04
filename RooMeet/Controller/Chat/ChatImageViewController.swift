//
//  ChatImageViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/12/4.
//

import UIKit

class ChatImageViewController: UIViewController {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        let imageDoubleTapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(onImageDoubleTap(tapGestureRecognizer:)))
        imageDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(imageDoubleTapGestureRecognizer)
        return imageView
    }()

    lazy var backButton: UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .mainLightColor
        button.tintColor = .mainDarkColor
        button.layer.cornerRadius = 45 / 2
        button.setImage(UIImage.asset(.back_dark), for: .normal)
        button.addTarget(self, action: #selector(backToParentPage(_:)), for: .touchUpInside)
        return button
    }()


    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.scrollsToTop = false
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    var imageURL: String

    init(imageURL: String) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        imageView.loadImage(imageURL, placeHolder: UIImage.asset(.room_placeholder))

        view.addSubview(scrollView)
        view.addSubview(backButton)
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 45),
            backButton.heightAnchor.constraint(equalToConstant: 45),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            // Pin the scrollView to the view
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            // Pin the imageView to the scrollView's content edges
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set min zoom at the point where the image just fits within the view
        scrollView.minimumZoomScale = min(scrollView.bounds.width / imageView.bounds.width, 1)
        // Set max zoom at the point where the image just fills the scroll content vertically
        scrollView.maximumZoomScale = min(scrollView.bounds.height / imageView.bounds.height, 1)
        // Begin at min zoom
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // show entire image
        updateZoomSizeFor(size: view.bounds.size)
    }

    func updateZoomSizeFor(size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let scale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = scale
        scrollView.zoomScale = scale
    }

    func configure(imageURL: String) {
        self.imageURL = imageURL
    }

    @objc private func onImageDoubleTap(tapGestureRecognizer: UITapGestureRecognizer) {
        guard tapGestureRecognizer.state == .ended else { return }
        if scrollView.zoomScale < scrollView.maximumZoomScale {
            // Zoom in when not yet fully zoomed in
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        } else {
            // Zoom out
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }

    @objc func backToParentPage(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension ChatImageViewController: UIScrollViewDelegate {
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let topInset = (scrollView.bounds.height - imageView.frame.height) / 2
        let leftInset = (scrollView.bounds.width - imageView.frame.width) / 2
        scrollView.contentInset = .init(top: max(topInset, 0), left: max(leftInset, 0), bottom: 0, right: 0)
    }

    // set imageView as zoom object
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset _: UnsafeMutablePointer<CGPoint>) {
        // swipe to dismiss
        let absV: (x: CGFloat, y: CGFloat) = (abs(velocity.x), abs(velocity.y))

        let verticallyBouncing: Bool = absV.y > absV.x && scrollView.contentOffset.y < 0

        if max(absV.x, absV.y) > 1 && verticallyBouncing {
            self.dismiss(animated: true)
        }
    }
}
