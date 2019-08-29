//
//  ViewController.swift
//  WhatWeSee
//
//  Created by Novák Bernadett on 2019. 08. 26..
//  Copyright © 2019. Novák Bernadett. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController , UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    let cameraPicker = UIImagePickerController()
    let photoPicker = UIImagePickerController()
    @IBOutlet weak var textLabelForWiki: UILabel!

    @IBOutlet weak var takeText: UILabel!
    @IBOutlet weak var leavesTop: UIImageView!
    @IBOutlet weak var photoText: UILabel!
    @IBOutlet weak var cameraIcon: UIImageView!
    @IBOutlet weak var leavesBottom: UIImageView!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"


    
    @IBOutlet weak var recognizerImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoPicker.delegate = self
        photoPicker.sourceType = .photoLibrary
        photoPicker.allowsEditing = false
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
    }
    
    func getFlowerData(flowerName : String){
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters : parameters).responseJSON{
            response in
            if response.result.isSuccess {
                let flowerData : JSON = JSON(response.result.value!)
                let temp = flowerData["query"]["pageids"][0].stringValue
                let result = flowerData["query"]["pages"][temp]["extract"].stringValue
                let flowerImage = flowerData["query"]["pages"][temp]["thumbnail"]["source"].stringValue
                self.recognizerImageView.sd_setImage(with: URL(string: flowerImage))
                self.textLabelForWiki.text = result
                
            }else {
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedimage = info[.originalImage] as? UIImage {
            guard let ciiImage = CIImage(image: userPickedimage) else{fatalError()}
            detect(image: ciiImage)
        }
        
        cameraPicker.dismiss(animated: true, completion: nil)
        photoPicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        takeText.isHidden = true
        leavesTop.isHidden = true
        photoText.isHidden = true
        cameraIcon.isHidden = true
        leavesBottom.isHidden = true
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("can't load ML model")
        }
    
        let handler = VNImageRequestHandler(ciImage: image)
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results?.first as? VNClassificationObservation else{
                fatalError()
            }
            self.navigationItem.title = results.identifier.capitalized
            self.getFlowerData(flowerName: results.identifier)

        }
        do { try handler.perform([request]) }
        catch { print(error) }
    }

    @IBAction func cameraIconTapped(_ sender: UIBarButtonItem) {
        present(cameraPicker, animated: true, completion: nil)
    }
    
    @IBAction func folderIconTapped(_ sender: UIBarButtonItem) {
        present(photoPicker, animated: true, completion: nil)
    }
}

