//
//  ViewController.swift
//  SwiftOpenCV
//
//  Created by Lee Whitney on 10/28/14.
//  Copyright (c) 2014 WhitneyLand. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var selectedImage : UIImage!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTakePictureTapped(sender: AnyObject) {
        
        var sheet: UIActionSheet = UIActionSheet();
        let title: String = "Please choose an option";
        sheet.title  = title;
        sheet.delegate = self;
        sheet.addButtonWithTitle("Choose Picture");
        sheet.addButtonWithTitle("Take Picture");
        sheet.addButtonWithTitle("Cancel");
        sheet.cancelButtonIndex = 2;
        sheet.showInView(self.view);
    }
    
    func actionSheet(sheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int) {
        var imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        switch buttonIndex{
            
        case 0:
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.presentViewController(imagePicker, animated: true, completion: nil)
            break;
        case 1:
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.presentViewController(imagePicker, animated: true, completion: nil)
            break;
        default:
            break;
        }
    }
    
    
    @IBAction func onDetectTapped(sender: AnyObject) {
        
        var progressHud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        progressHud.labelText = "Detecting..."
        progressHud.mode = MBProgressHUDModeIndeterminate
        
        var processingImage = scaleImage(selectedImage, maxDimension:640)
        
        var ocr = SwiftOCR(fromImage: processingImage)
        ocr.recognize()
        
        imageView.image = ocr.groupedImage
        
        progressHud.hide(true);
    }
    
    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSizeMake(maxDimension, maxDimension)
        var scaleFactor:CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    
    func grayScaleImage(image:UIImage) -> UIImage {
        let imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
        let colorSpace = CGColorSpaceCreateDeviceGray();
        
        let width = UInt(image.size.width)
        let height = UInt(image.size.height)
        let context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpace, .allZeros);
        CGContextDrawImage(context, imageRect, image.CGImage!);
        
        let imageRef = CGBitmapContextCreateImage(context);
        let newImage = UIImage(CGImage: imageRef)
        return newImage!
    }
    
    @IBAction func onRecognizeTapped(sender: AnyObject) {
        if((self.selectedImage) != nil){
            var progressHud = MBProgressHUD.showHUDAddedTo(view, animated: true)
            progressHud.labelText = "Detecting..."
            progressHud.mode = MBProgressHUDModeIndeterminate
            
            dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
                var ocr = SwiftOCR(fromImage: self.selectedImage)
                ocr.recognize()
                
                dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    self.imageView.image = self.selectedImage
                    
                    progressHud.hide(true);
                    
                    var dprogressHud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                    dprogressHud.labelText = "Recognizing..."
                    dprogressHud.mode = MBProgressHUDModeIndeterminate
                    
                    var text = ocr.recognizedText
                    
                    self.performSegueWithIdentifier("ShowRecognition", sender: text);
                    
                    dprogressHud.hide(true)
                })
            })
        }else {
            var alert = UIAlertView(title: "SwiftOCR", message: "Please select image", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
        }
    }
    
    
    func cropBusinessCardForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        var businessCard: CIImage
        businessCard = image.imageByApplyingFilter("CIPerspectiveTransformWithExtent",
            withInputParameters: [
                "inputExtent": CIVector(CGRect: image.extent()),
                "inputTopLeft": CIVector(CGPoint: topLeft),
                "inputTopRight": CIVector(CGPoint: topRight),
                "inputBottomLeft": CIVector(CGPoint: bottomLeft),
                "inputBottomRight": CIVector(CGPoint: bottomRight)
            ])
        businessCard = image.imageByCroppingToRect(businessCard.extent())
        return businessCard
    }
    
    func crop(image: CIImage) -> CIImage? {
        var resultImage: CIImage?
        var detector = prepareRectangleDetector();
        // Get the detections
        let features = detector.featuresInImage(image)
        for feature in features as [CIRectangleFeature] {
            resultImage = cropBusinessCardForPoints(image, topLeft: feature.topLeft, topRight: feature.topRight,
                bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
        }
        return resultImage
    }
    
    func prepareRectangleDetector() -> CIDetector {
        let options: [String : AnyObject] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 2.0]
        return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)
    }
    
    func performRectangleDetection(image: CIImage) -> CIImage? {
        var resultImage: CIImage?
        var detector = prepareRectangleDetector();
            let features = detector.featuresInImage(image)
            for feature in features as [CIRectangleFeature] {
                resultImage = drawHighlightOverlayForPoints(image, topLeft: feature.topLeft, topRight: feature.topRight,
                    bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
            }
        
        return resultImage
    }
    
    func drawHighlightOverlayForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint,
        bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
            var overlay = CIImage(color: CIColor(red: 1 , green: 0, blue: 0, alpha: 0.2))
            overlay = overlay.imageByCroppingToRect(image.extent())
            return overlay.imageByCompositingOverImage(image)
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
        /*var ciimage = CIImage(image: image)
        var newImage = performRectangleDetection(ciimage)
        selectedImage = UIImage(CIImage: newImage!)*/
        var _image = image //scaleImage(image, maxDimension:1280)
        var ciimage = CIImage(image: image)
        var newImage = crop(ciimage)
        
        let filter = CIFilter(name: "CILanczosScaleTransform")
        filter.setValue(newImage, forKey: "inputImage")
        filter.setValue(1, forKey: "inputScale")
        filter.setValue(1, forKey: "inputAspectRatio")
        let outputImage = filter.valueForKey("outputImage") as CIImage
        
        /*var overlay = CIImage(color: CIColor(red: 1 , green: 0, blue: 0, alpha: 0.2))
        overlay = overlay.imageByCroppingToRect(outputImage.extent())
        overlay = overlay.imageByCompositingOverImage(outputImage)
        _image = UIImage(CIImage: overlay!)!*/
        
        _image = UIImage(CIImage: outputImage)
        
        /*var ciimage = CIImage(image: _image)
        var newImage = performRectangleDetection(ciimage)
        _image = UIImage(CIImage: newImage!)!*/
        
        /*let filter = CIFilter(name: "CILanczosScaleTransform")
        filter.setValue(_image, forKey: "inputImage")
        filter.setValue(0.5, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let outputImage = filter.valueForKey("outputImage") as CIImage
        
        let context = CIContext(options: nil)
        let scaledImage = UIImage(CGImage: context.createCGImage(outputImage, fromRect: outputImage.extent()))*/
        
        var fimage = _image.fixOrientation()
        var size = CGSizeMake(fimage.size.width / 2, fimage.size.height / 2 )
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        fimage.drawInRect(CGRectMake(0, 0, size.width, size.height))
        _image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        

        /*var ciimage = CIImage(image: image)
        var newImage = crop(ciimage)
        var _image = UIImage(CIImage: newImage!, scale: 1, orientation: UIImageOrientation.Down)*/
        selectedImage = _image
        picker.dismissViewControllerAnimated(true, completion: nil)
        imageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var vc =  segue.destinationViewController as DetailViewController
        vc.recognizedText = sender as String!
    }
}

