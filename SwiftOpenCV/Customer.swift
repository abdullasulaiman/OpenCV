//
//  Customer.swift
//  SwiftOpenCV
//
//  Created by Mohamed Abdulla on 20/07/15.
//  Copyright (c) 2015 WhitneyLand. All rights reserved.
//

import Foundation
import CoreData

class Customer: NSManagedObject {

    @NSManaged var custName: String
    @NSManaged var custAddress: String
    @NSManaged var custMobile: String
    @NSManaged var custFax: String
    @NSManaged var custCardImage: NSData
    @NSManaged var custOriginalScanText: String

}
