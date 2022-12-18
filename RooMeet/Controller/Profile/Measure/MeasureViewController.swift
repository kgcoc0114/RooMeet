//
//  MeasureViewController.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/30.
//

import UIKit
import SceneKit
import ARKit
import Photos

class MeasureViewController: UIViewController {
    @IBOutlet weak var targetView: UIImageView!

    @IBOutlet weak var resultBackgroundView: UIView! {
        didSet {
            resultBackgroundView.backgroundColor = .mainLightColor.withAlphaComponent(0.7)
            resultBackgroundView.layer.cornerRadius = RMConstants.shared.buttonCornerRadius
        }
    }

    @IBOutlet weak var resultLabel: UILabel! {
        didSet {
            resultLabel.tintColor = .mainDarkColor
            resultLabel.font = UIFont.regularTitle1()
        }
    }

    @IBOutlet weak var backButton: UIButton! {
        didSet {
            backButton.setTitle("", for: .normal)
            backButton.backgroundColor = .mainLightColor
            backButton.tintColor = .mainDarkColor
            backButton.layer.cornerRadius = 45 / 2
            backButton.setImage(UIImage.asset(.back_dark), for: .normal)
            backButton.addTarget(self, action: #selector(backToParentPage(_:)), for: .touchUpInside)
        }
    }

    @IBOutlet weak var undoButton: UIButton! {
        didSet {
            undoButton.setTitle("", for: .normal)
            undoButton.backgroundColor = .mainLightColor
            undoButton.tintColor = .mainDarkColor
            undoButton.layer.cornerRadius = 45 / 2
            undoButton.setImage(UIImage.asset(.undo), for: .normal)
            undoButton.addTarget(self, action: #selector(undoNode(_:)), for: .touchUpInside)
        }
    }


    @IBOutlet weak var saveImageButton: UIButton! {
        didSet {
            saveImageButton.setTitle("", for: .normal)
            saveImageButton.backgroundColor = .mainLightColor
            saveImageButton.tintColor = .mainDarkColor
            saveImageButton.layer.cornerRadius = 45 / 2
            saveImageButton.setImage(UIImage.asset(.save_picture), for: .normal)
            saveImageButton.addTarget(self, action: #selector(saveImageAction(_:)), for: .touchUpInside)
        }
    }

    @IBOutlet weak var addNodeButton: UIButton! {
        didSet {
            addNodeButton.setTitle("", for: .normal)
            addNodeButton.backgroundColor = .mainLightColor
            addNodeButton.tintColor = .mainDarkColor
            addNodeButton.layer.cornerRadius = 60 / 2
            addNodeButton.setImage(UIImage.asset(.ruler), for: .normal)
            addNodeButton.addTarget(self, action: #selector(addNode(_:)), for: .touchUpInside)
        }
    }

    @IBOutlet weak var saveButton: UIButton! {
        didSet {
            saveButton.setTitle("", for: .normal)
            saveButton.backgroundColor = .mainLightColor
            saveButton.tintColor = .mainDarkColor
            saveButton.setImage(UIImage.asset(.check), for: .normal)
            saveButton.layer.cornerRadius = 45 / 2
            saveButton.addTarget(self, action: #selector(saveResult(_:)), for: .touchUpInside)
        }
    }

    @IBOutlet weak var sceneView: ARSCNView!

    private var finishButtonState = false
    var startValue = SCNVector3()
    var endValue = SCNVector3()
    let vectorZero = SCNVector3()
    var measuring = false
    private var line: LineNode?
    private var lines: [LineNode] = []
    var completion: ((Int?, String?) -> Void)?

    private var measureValue: Float? {
        didSet {
            if let measure = measureValue {
                resultLabel.text = nil
                resultLabel.attributedText = buildAttributeString(
                    value: String(format: "%.0f", measure * 100),
                    unit: "cm"
                )
            } else {
                resultLabel.attributedText = resultStr()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSceneView()
        self.navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        self.navigationController?.navigationBar.isHidden = false
    }


    private func setupSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(
            configuration,
            options: [.resetTracking, .removeExistingAnchors]
        )
        resultLabel.attributedText = resultStr()
    }

    func resultStr() -> NSAttributedString {
        let str = "長度"
        return NSAttributedString(string: str, attributes: [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ])
    }

    func updateLine() {
        if let startPos = sceneView.realWorldVector(screenPos: view.center) {
            let position = startPos
            addNodeButton.isEnabled = true
            targetView.image = UIImage.asset(.target_enable)

            guard let currentLine = line else {
                return
            }
            let length = currentLine.updatePosition(endPos: position)
            measureValue = length
            resultLabel.attributedText = buildAttributeString(value: String(format: "%.0f", length * 100), unit: "cm")
        }
    }

    private func buildAttributeString(value: String, unit: String) -> NSAttributedString {
        let main = NSMutableAttributedString()
        let value = NSMutableAttributedString(
            string: value,
            attributes: [
                NSAttributedString.Key.font: UIFont.regular(size: 60) as Any,
                NSAttributedString.Key.foregroundColor: UIColor.mainDarkColor
            ]
        )
        let unit = NSMutableAttributedString(
            string: unit,
            attributes: [
                NSAttributedString.Key.font: UIFont.regular(size: 20) as Any,
                NSAttributedString.Key.foregroundColor: UIColor.mainDarkColor
            ]
        )
        main.append(value)
        main.append(unit)
        return main
    }
}

// MARK: - ARSCNViewDelegate
extension MeasureViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateLine()
        }
    }
}

// MARK: - Target Action
@objc private extension MeasureViewController {
    func backToParentPage(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    func undoNode(_ sender: UIButton) {
        if line != nil {
            line?.removeFromParent()
            line = nil
        } else if let lineLast = lines.popLast() {
            lineLast.removeFromParent()
        }
        measureValue = nil
    }

    func addNode(_ sender: UIButton) {
        if let tmpLine = line {
            lines.append(tmpLine)
            line = nil
        } else {
            if let startPos = sceneView.realWorldVector(screenPos: view.center) {
                print(startPos)
                line = LineNode(startPos: startPos, scnView: sceneView)
            }
        }
    }

    func saveResult(_ sender: UIButton) {
        guard
            let measureValue = measureValue,
            let measureValueInt = Int(String(format: "%.0f", measureValue * 100)) else { return }
        completion?(measureValueInt, resultLabel.text)
        RMProgressHUD.showSuccess()
        navigationController?.popViewController(animated: true)
    }

    private func saveImage(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { _, error in
            if error != nil {
                RMProgressHUD.showFailure(text: "儲存資料出現問題！")
            } else {
                RMProgressHUD.showSuccess()
            }
        }
    }

    func saveImageAction(_ sender: UIButton) {
        RMProgressHUD.show()
        let image = sceneView.snapshot()
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            saveImage(image: image)
        default:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .authorized:
                    self.saveImage(image: image)
                default:
                    RMProgressHUD.showFailure(text: "需要取得您的相簿權限！")
                }
            }
        }
    }
}

extension ARSCNView {
    func realWorldVector(screenPos: CGPoint) -> SCNVector3? {
        if let query = self.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: .any) {
            let results = self.session.raycast(query)
            if let result = results.first {
                return SCNVector3.positionFromTransform(result.worldTransform)
            }
        }

        return nil
    }
}

extension SCNVector3: Equatable {
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    func distance(from vector: SCNVector3) -> Float {
        let distanceX = self.x - vector.x
        let distanceY = self.y - vector.y
        let distanceZ = self.z - vector.z

        return abs(sqrtf((distanceX * distanceX) + (distanceY * distanceY) + (distanceZ * distanceZ)))
    }

    public static func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y) && (lhs.z == rhs.z)
    }
}
