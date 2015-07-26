//
//  ImagePickerViewController.swift
//  SwiftOpenCV
//
//  Created by Mohamed Abdulla on 23/07/15.
//  Copyright (c) 2015 WhitneyLand. All rights reserved.
//

import UIKit

class ImagePickerViewController: UIViewController, MAImagePickerControllerDelegate
{

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openImagePickerControl(sender: AnyObject) {
        var imagePicker:MAImagePickerController  = MAImagePickerController()
        imagePicker.delegate = self
        let type = MAImagePickerControllerSourceType.Camera
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    func imagePickerDidCancel() {

    }
    
    func imagePickerDidChooseImageWithPath(path: String!) {
    
    }

}
