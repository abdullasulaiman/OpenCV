//
//  AddCustomerControllerViewController.swift
//  SwiftOpenCV
//
//  Created by Mohamed Abdulla on 20/07/15.
//  Copyright (c) 2015 WhitneyLand. All rights reserved.
//

import UIKit
import CoreData

class AddCustomerControllerViewController: UIViewController {

    @IBOutlet weak var custName: UITextField!
    @IBOutlet weak var custAddress: UITextField!
    @IBOutlet weak var custMobileNumber: UITextField!
    @IBOutlet weak var custFax: UITextField!
    @IBOutlet weak var custTextScan: UITextView!
    
    let managedObjectContext =
    (UIApplication.sharedApplication().delegate
        as AppDelegate).managedObjectContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func saveCustomer(sender: AnyObject) {
        
        let entityDescription =
        NSEntityDescription.entityForName("Customer",
            inManagedObjectContext: managedObjectContext!)
        
        let customer = Customer(entity: entityDescription!,
            insertIntoManagedObjectContext: managedObjectContext)
        
        customer.custName = custName.text
        customer.custAddress = custAddress.text
        customer.custMobile = custMobileNumber.text
        customer.custFax = custFax.text
        customer.custOriginalScanText = custTextScan.text
        
        var error: NSError?
        
        managedObjectContext?.save(&error)
        var message:String?
        if let err = error {
            message = err.localizedFailureReason
        } else {
            custName.text = ""
            custName.text = ""
            custMobileNumber.text = ""
            custFax.text = ""
            custTextScan.text = ""
            message = "Customer Data Saved"
        }
        
        let alertController = UIAlertController(title: "Customer Info", message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
