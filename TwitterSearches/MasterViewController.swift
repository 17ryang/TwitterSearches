//
//  MasterViewController.swift
//  TwitterSearches
//
//  Created by Risako Yang on 2/26/15.
//  Copyright (c) 2015 Risako Yang. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController,
    ModelDelegate, UIGestureRecognizerDelegate {

    var detailViewController: DetailViewController? = nil
    var objects = NSMutableArray()
    let twitterSearchURL = "htpp://mobile.twitter.con/search/?q="

    var model: Model! = nil        //! implicitly wrapper optional ? question mark optional --> not assigning anything (nil now but assigned something later but doesnt have to me), ! --> has to be assigned a non nil value later
    
    func modelDataChanged() {
        tableView.reloadData() //usecall method modelDataChanged with model 

    }

    //configure size
    override func awakeFromNib() {
        super.awakeFromNib() //overrides method
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false //item in master liste can stay selected or unselected when you click between master and view, false insures that it is not cleared, UI decision
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0) //sets size of the masterlist
        }
    }

    override func viewDidLoad() { //overriding method, then super.method check documentation
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addButtonPressed:")//selector: prefixcontrol drag from button to code and create ivaction, programmatically
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers //list of viewcontrollers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController //assigning to this property
        }
        
        model = Model(delegate: self)
        model.synchronize()
    }
    
    func addButtonPressed(sender: AnyObject){ //selector to get called when you call the cross to add another variable to the list
        displayAddEditSearchAlert(isNew: true, index: nil)
    }
    
    func tableViewCellLongPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began && !tableView.editing {
            let cell = sender.view as UITableViewCell
        
            if let indexPath = tableView.indexPathForCell(cell){
                displayLongPressOptions(indexPath.row)
            }
        }
    }
    
    func displayLongPressOptions(row: Int){
        let alertController = UIAlertController(title: "Options", message: "Edit or Share your search", preferredStyle: UIAlertControllerStyle.Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let editAction = UIAlertAction(title: "Edit", style: UIAlertActionStyle.Default, handler: {(action)in
            self.displayAddEditSearchAlert(isNew: false, index: row)})
        alertController.addAction(editAction)
        
        let shareAction = UIAlertAction(title: "Share", style: UIAlertActionStyle.Default, handler: {(action) in self.shareSearch(row)})
        alertController.addAction(shareAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
            
    func displayAddEditSearchAlert(# isNew: Bool, index: Int?) {
        let alertController = UIAlertController(title: isNew ? "Add Search" : "Edit Search", message: isNew ? "" : "Modify your query", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addTextFieldWithConfigurationHandler({(textField) in
            if isNew {
                textField.placeholder = "Enter Twitter search query"
            } else {
                textField.text = self.model.queryForTagAtIndex(index!)
            }
        })
        
        alertController.addTextFieldWithConfigurationHandler({(textField) in
            if isNew {
                textField.placeholder = "Tag your query"
            } else {
                textField.text = self.model.tagAtIndex(index!)
                textField.enabled = false
                textField.textColor = UIColor.lightGrayColor()
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.Default, handler: {(action) in
            let query = (alertController.textFields?[0] as UITextField).text
            let tag = (alertController.textFields?[1] as UITextField).text
            
            if !query.isEmpty && !tag.isEmpty {
                self.model.saveQuery(query, forTag: tag, syncToCloud: true)

                if isNew{
                    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }
        })
        alertController.addAction(saveAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func shareSearch(index: Int) {
        let message = "Check out the results of this Twitter search"
        let urlString = twitterSearchURL + urlEncodeString(model.queryForTagAtIndex(index)!)
        let itemsToShare = [message, urlString] //putting message and string into array
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        objects.insertObject(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                let query = String(model.queryForTagAtIndex(indexPath.row)!)
                controller.detailItem = NSURL(string: twitterSearchURL + urlEncodeString(query))
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // returns a URL encoded version of the qery String
    func urlEncodeString(string: String) -> String {
        return string.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    }
    
    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        cell.textLabel!.text = model.tagAtIndex(indexPath.row)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "tableViewCellLongPressed")
        longPressGestureRecognizer.minimumPressDuration = 0.5
        cell.addGestureRecognizer(longPressGestureRecognizer)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            model.deleteSearchAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

