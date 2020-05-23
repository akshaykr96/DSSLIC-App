//
//  FirstViewController.swift
//  DSSLICv2
//
//  Created by Akshay Kumar on 2019-08-13.
//  Copyright © 2019 SFU. All rights reserved.
//
import UIKit
import CoreML
import SDWebImage
import SDWebImageFLIFCoder
import Accelerate
import Foundation


var imagepicker = UIImagePickerController()
var input = UIImage()
var file = 1
var cvBufferInput: CVPixelBuffer? = nil

class FirstViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
    
    @IBOutlet weak var inputImg: UIImageView!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var outputImg2: UIImageView!
    @IBOutlet weak var heading1: UILabel!
    @IBOutlet weak var heading2: UILabel!
    @IBOutlet weak var heading3: UILabel!
    @IBOutlet weak var PSNR: UILabel!
    @IBOutlet weak var SSIM: UILabel!
    @IBOutlet weak var outputImg: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        heading1.text = ""
        heading2.text = ""
        heading3.text = ""
        PSNR.text = ""
        SSIM.text = ""
        let FLIFCoder = SDImageFLIFCoder.shared
        SDImageCodersManager.shared.addCoder(FLIFCoder)
        
        // Do any additional setup after loading the view.
        
    }
    

    @IBAction func Add(_ sender: Any) {
    imagepicker.delegate =  self
        inputImg.image = nil
        self.outputImg.image = nil
        self.outputImg2.image = nil
        heading1.text = ""
        heading2.text = ""
        heading3.text = ""
        PSNR.text = ""
        SSIM.text = ""
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a Photo", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action:UIAlertAction) in imagepicker.sourceType = .camera }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {(action:UIAlertAction) in imagepicker.sourceType = .photoLibrary
            self.present(imagepicker, animated: true, completion: nil )
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated:true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        input = info[.originalImage] as! UIImage
        label1.text = ""
        label2.text = ""
        let jpeg = input.jpegData(compressionQuality: 1)
        let x = UIImage(data: jpeg!)
        inputImg.image = x
        
        let size = (Double(jpeg!.count))*8.0
        let numPixels = Double((input.size.height)*(input.size.width))
        let bpp = size/numPixels
        heading1.text = "Input (bpp: "+String(format: "%.3f", bpp)+")"
        picker.dismiss(animated: true, completion: nil)
        let model = Model()
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        DispatchQueue.global().async {
            
            // 1 - Transform our UIImage to a PixelBuffer of appropriate size
            
            cvBufferInput = input.pixelBuffer(width: 768, height: 512)
            
            // 2 - Feed that PixelBuffer to the model
            let oput = try? model.prediction(input_1: cvBufferInput!)
            
            // 3 - Transform output PixelBuffer to UIImage
            
            //Intermediate output (Compressed Image)
            let inter = UIImage(pixelBuffer: oput!._104)
            
            //Recreated output (generated from Compressed image)
            let end = UIImage(pixelBuffer: oput!._164)
            
            // 4 - Resize result to the original size, then hand it back to the main thread
            let finalImage = end!.resize(size: input.size)!
            
            // Calculate Metrics
            
            
            
            //Encode as FLIF
            let data = inter!.sd_imageData(as: .FLIF)
            let FLIF = saveImage(data: data)
            let bpp2 = ((Double(data!.count))*8.0)/numPixels
            
            DispatchQueue.main.async {
                print("!!!!!")
                
                let (mse, psnr, sssim) = Metrics(input: input, finalImage: finalImage)
                print("MSE: " + String(mse))
                print("PSNR: " + String(psnr))
                self.activityIndicator.stopAnimating()
                self.heading2.text = "Generated Image"
                
                self.heading3.text = "Compressed Image (bpp: "+String(format: "%.3f", bpp2)+")"
                self.outputImg.image = finalImage
                self.outputImg2.image = inter
                self.PSNR.text = "PSNR: " + String(format: "%.3f", psnr)
                self.SSIM.text = "SSIM: " + String(format: "%.3f", sssim)
                
            }
        }
    }
    
    
}

func saveImage(data: Data?) -> URL{
    let filename = getDocumentsDirectory().appendingPathComponent("FLIF"+String(file)+".FLIF")
    file = file+1
    try! data?.write(to: filename)
    return filename
}


func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
}


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

func Metrics(input: UIImage, finalImage: UIImage)-> (Double, Double, Double) {
    let width = Int(input.size.width)
    let height = Int(input.size.height)
    let size = width*height
    
    let inputBuffer = input.pixelBufferGray(width: Int(input.size.width), height: Int(input.size.height))
    let outputBuffer = finalImage.pixelBufferGray(width: Int(finalImage.size.width), height: Int(finalImage.size.width))
    CVPixelBufferLockBaseAddress(outputBuffer!, [])
    CVPixelBufferLockBaseAddress(inputBuffer!, [])
    let inbuf = unsafeBitCast(CVPixelBufferGetBaseAddress(inputBuffer!), to: UnsafeMutablePointer<UInt8>.self)
    let outbuf = unsafeBitCast(CVPixelBufferGetBaseAddress(outputBuffer!), to: UnsafeMutablePointer<UInt8>.self)
    var accum : Double = 0.0
    for y in 0..<size {
        let value1 = Double(inbuf[y])
        let value2 = Double(outbuf[y])
        let diff = (value1-value2)
        let square = diff*diff
        accum = accum+square
        
        
    }
    CVPixelBufferUnlockBaseAddress(outputBuffer!, [])
    CVPixelBufferUnlockBaseAddress(inputBuffer!, [])
    let mse = accum/Double(size)
    let max : Double = 255.0*255.0
    let psnr = 10.0*log10(Double(max/mse))
    let ssim = Double(FSPComputeSSIMFactorBetween(input, finalImage))
    return (mse, psnr, ssim)
}


