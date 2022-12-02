//
//  LineNode.swift
//  RooMeet
//
//  Created by kgcoc on 2022/11/30.
//

import Foundation
import SceneKit
import ARKit


class LineNode: NSObject {
    let startNode: SCNNode
    let endNode: SCNNode
    var lineNode: SCNNode?
    let textNode: SCNNode
    let sceneView: ARSCNView?

    init(
        startPos: SCNVector3,
        scnView: ARSCNView,
        color: (start: UIColor, end: UIColor) = (UIColor.green, UIColor.red),
        font: UIFont = UIFont.boldSystemFont(ofSize: 10)
    ) {
        self.sceneView = scnView

        let scale = 1 / 400.0 // 缩放比例
        let scaleVector = SCNVector3(scale, scale, scale)

        func buildSCNSphere(color: UIColor) -> SCNSphere {
            let dot = SCNSphere(radius: 1)
            dot.firstMaterial?.diffuse.contents = color
            dot.firstMaterial?.lightingModel = .constant
            dot.firstMaterial?.isDoubleSided = true
            return dot
        }


        startNode = SCNNode(geometry: buildSCNSphere(color: color.start))
        startNode.scale = scaleVector
        startNode.position = startPos
        self.sceneView?.scene.rootNode.addChildNode(startNode)

        endNode = SCNNode(geometry: buildSCNSphere(color: color.end))
        endNode.scale = scaleVector

        lineNode = nil

        let text = SCNText(string: "", extrusionDepth: 0.1)
        text.font = font
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.firstMaterial?.isDoubleSided = true
        textNode = SCNNode(geometry: text)
        let textScale = 1 / 500.0
        textNode.scale = SCNVector3(textScale, textScale, textScale)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeFromParent()
    }

    public func updatePosition(endPos: SCNVector3) -> Float {
        if endNode.parent == nil {
            sceneView?.scene.rootNode.addChildNode(endNode)
        }
        endNode.position = endPos

        let posStart = startNode.position
        let middle = SCNVector3(
            (posStart.x + endPos.x) / 2.0,
            (posStart.y + endPos.y) / 2.0,
            (posStart.z + endPos.z) / 2.0
        )

        guard let text = textNode.geometry as? SCNText else {
            return 0
        }

        let length = endPos.distance(from: startNode.position)
        text.string = String(format: "%.0f", length * 100) + "cm"
        textNode.setPivot()
        textNode.position = middle
        if textNode.parent == nil {
            sceneView?.scene.rootNode.addChildNode(textNode)
        }

        lineNode?.removeFromParentNode()
        lineNode = lineBetweenNodeA(nodeA: startNode, nodeB: endNode)
        if let lineNode = lineNode {
            sceneView?.scene.rootNode.addChildNode(lineNode)
        }
        return length
    }

    func removeFromParent() {
        startNode.removeFromParentNode()
        endNode.removeFromParentNode()
        lineNode?.removeFromParentNode()
        textNode.removeFromParentNode()
    }

    // MARK: - Private

    private func lineBetweenNodeA(nodeA: SCNNode, nodeB: SCNNode) -> SCNNode {
        guard let sceneView = sceneView else {
            return SCNNode()
        }
        return CylinderLine(
            parent: sceneView.scene.rootNode,
            vector1: nodeA.position,
            vector2: nodeB.position,
            radius: 0.001, // 圆形截面的半径
            radSegmentCount: 16,// 圓柱體的斷面，越多越平滑
            color: UIColor.white
        )
    }

    func buildAttributeString(value: String, unit: String) -> NSAttributedString {
        let main = NSMutableAttributedString()
        let value = NSMutableAttributedString(
            string: value,
            attributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 60),
                NSAttributedString.Key.foregroundColor: UIColor.mainDarkColor
            ])
        let unit = NSMutableAttributedString(
            string: unit,
            attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20),
                NSAttributedString.Key.foregroundColor: UIColor.mainDarkColor
            ])
        main.append(value)
        main.append(unit)
        return main
    }
}

class CylinderLine: SCNNode {
    init(parent: SCNNode, vector1: SCNVector3, vector2: SCNVector3, radius: CGFloat, radSegmentCount: Int, color: UIColor) {
        super.init()

        let  height = vector1.distance(from: vector2)
        position = vector1
        let nodeV2 = SCNNode()
        nodeV2.position = vector2
        parent.addChildNode(nodeV2)

        let zAlign = SCNNode()
        zAlign.eulerAngles.x = Float(CGFloat.pi / 2)

        let cylinder = SCNCylinder(radius: radius, height: CGFloat(height))
        cylinder.radialSegmentCount = radSegmentCount
        cylinder.firstMaterial?.diffuse.contents = color

        let nodeCyl = SCNNode(geometry: cylinder)
        nodeCyl.position.y = -height / 2
        zAlign.addChildNode(nodeCyl)

        addChildNode(zAlign)

        constraints = [SCNLookAtConstraint(target: nodeV2)]
    }

    override init() {
        super.init()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension SCNNode {
    func setPivot() { // 旋轉文字方向
        let minVec = self.boundingBox.min
        let maxVec = self.boundingBox.max
        // SCNVector3Make only works with Float
        let bound = SCNVector3Make(maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z)
        self.pivot = SCNMatrix4MakeTranslation(bound.x / 2, bound.y, bound.z / 2)
    }
}
