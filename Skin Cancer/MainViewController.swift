//
//  MainViewController.swift
//  Skin Cancer
//
//  Created by Blintsov Sergey on 07/09/2018.
//  Copyright © 2018 Blintsov Sergey. All rights reserved.
//

import UIKit
import CoreML
import Vision

class MainViewController: UIViewController {
    
    @IBOutlet weak var scene: UIImageView!
    @IBOutlet weak var answerLabel: UILabel!
    
    @IBAction func camButtonTapped(_ sender: Any) {
        let imagePicker = UIImagePickerController() // 1
        imagePicker.delegate = self // 2
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera // 3
        
        // для выбора только фотокамеры, не для записи видео
        imagePicker.showsCameraControls = true // 4
        
        self.present(imagePicker, animated: true, completion: nil) // 5
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        super.viewDidLoad()
        
        guard let image = UIImage(named: "train_night") else {
            fatalError("no starting image")
        }
        
        scene.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("couldn't convert UIImage to CIImage")
        }
        
        detectScene(image: ciImage)
    }
        // Do any additional setup after loading the view.

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MainViewController {
    @IBAction func pickImage(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .savedPhotosAlbum
        present(pickerController, animated: true)
    }
}
extension MainViewController: UINavigationControllerDelegate {
    
}

extension MainViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("couldn't load image from Photos")
        }
        
        scene.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("couldn't convert UIImage to CIImage")
        }
        
        detectScene(image: ciImage)
        
    }
}

extension MainViewController {
    func detectScene(image: CIImage) {
        answerLabel.text = "detecting scene..."
        
        // Load the ML model through its generated class
        guard let model = try? VNCoreMLModel(for: melanoma().model) else {
            fatalError("can't load Places ML model")
        }
        
        // Create a Vision request with completion handler
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("unexpected result type from VNCoreMLRequest")
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.answerLabel.text = "\(Int(topResult.confidence * 100))% it's a \(topResult.identifier)"
            }
        }
        
        // Run the Core ML GoogLeNetPlaces classifier on global dispatch queue
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
        
    }
}

