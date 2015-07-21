//
//  MainScreenControllerTableViewController.swift
//  SwiftOpenCV
//
//  Created by Mohamed Abdulla on 20/07/15.
//  Copyright (c) 2015 WhitneyLand. All rights reserved.
//

import UIKit
import CoreData

class MainScreenControllerTableViewController: UITableViewController, UISearchResultsUpdating {
    var resultSearchController = UISearchController()
 
    var tableData = [Customer]()
    var filteredTableData = [Customer]()
    let managedObjectContext =
    (UIApplication.sharedApplication().delegate
        as AppDelegate).managedObjectContext
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
        let fetchRequest = NSFetchRequest(entityName: "Customer")
        tableData = self.managedObjectContext?.executeFetchRequest(fetchRequest, error: nil) as [Customer]
        self.tableView.reloadData()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // 1
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 2
        if (self.resultSearchController.active) {
            return self.filteredTableData.count
        }
        else {
            return self.tableData.count
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        // 3
        if (self.resultSearchController.active) {
            cell.textLabel?.text = filteredTableData[indexPath.row].custName
            return cell
        }
        else {
            cell.textLabel?.text = tableData[indexPath.row].custName
            return cell
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        /*filteredTableData.removeAll(keepCapacity: false)
        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text)
        let array = (tableData as NSArray).filteredArrayUsingPredicate(searchPredicate!)
        filteredTableData = array as [String]
        self.tableView.reloadData()*/
    }

}
