//
//  ViewController.swift
//  ShapeClassifier
//
//  Created by Reza Harris on 03/06/21.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var resultView: UIView!
    @IBOutlet weak var resultLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        resultLabel.text = "Take a photo or choose from library"
    }
    @IBAction func pickImageFromLibrary(_ sender: Any) {
        presentPicker(with: .photoLibrary)
    }
    @IBAction func takeImageWithCamera(_ sender: Any) {
        presentPicker(with: .camera)
    }
    
    func hideResultsView() {
        self.resultView.alpha = 0
    }
    
    func showResultsView() {
        self.resultView.alpha = 1
    }
    
    func presentPicker(with sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
        hideResultsView()
    }
    
    lazy var vnRequest: VNCoreMLRequest = {
        let vnModel = try! VNCoreMLModel(for: ShapeClassifier().model)
        let request = VNCoreMLRequest(model: vnModel) { [unowned self] request , _ in
            self.processingResult(for: request)
        }
        request.imageCropAndScaleOption = .centerCrop
        return request
    }()
    
    func classify(image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let ciImage = CIImage(image: image)!
            let imageOrientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: imageOrientation)
            try! handler.perform([self.vnRequest])
        }
    }
    
    func processingResult(for request: VNRequest) {
        DispatchQueue.main.async {
            let results = (request.results! as! [VNClassificationObservation]).prefix(2)
            self.resultLabel.text = results.map { result in
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 1
                let percentage = formatter.string(from: result.confidence * 100 as NSNumber)!
                return "\(result.identifier) \(percentage)%"
            }.joined(separator: "\n")
            self.showResultsView()
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let image = info[.originalImage] as! UIImage
        imageView.image = image
        classify(image: image)
    }
}

