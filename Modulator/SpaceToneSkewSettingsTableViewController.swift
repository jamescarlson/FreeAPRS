//
//  SpaceToneSkewSettingsTableViewController.swift
//  FreeAPRS
//
//  Created by James on 11/23/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import UIKit

class SpaceToneSkewSettingsTableViewController: UITableViewController {
    
    @IBAction func spaceToneSkewEdited(_ sender: UITextField) {
        guard let text = sender.text else {
            return
        }
        
        guard let skewValue = Float(text) else {
            sender.text = "1.0"
            return
        }
        
        let index = sender.tag
        
        if var previousSpaceToneSkews = UserDefaults.standard.value(forKey: "spaceToneSkews") as? [Float] {
            previousSpaceToneSkews[index] = skewValue
            UserDefaults.standard.setValue(previousSpaceToneSkews, forKey: "spaceToneSkews")
        }
        
        let thisIndexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [thisIndexPath], with: .fade)
        
        sender.resignFirstResponder()
    }
    
    @IBAction func editAction(_ sender: UIBarButtonItem) {
        setEditing(!isEditing, animated: true)
    }
    
    @IBAction func addRow(_ sender: AnyObject) {
        if var previousSpaceToneSkews = UserDefaults.standard.value(forKey: "spaceToneSkews") as? [Float] {
            previousSpaceToneSkews.append(1.0)
            
            UserDefaults.standard.setValue(previousSpaceToneSkews, forKey: "spaceToneSkews")
            
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
        
        //self.tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: "textFieldCell")
        
        //self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "textFieldCellType")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        guard let spaceToneSkews = UserDefaults.standard.array(forKey: "spaceToneSkews") as? [Float] else {
            NSLog("Could not retrieve space tone skews in numberOfRowsPerSection")
            return 0
        }
        
        return spaceToneSkews.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "textFieldCell", for: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell else {
            let cell = UITableViewCell()
            cell.textLabel?.text = "Invalid Cell returned"
            return cell
        }

        // Configure the cell...
        
        guard let textField = cell.textField else {
            NSLog("Failed to get text view")
            return cell
        }
        
        guard let textLabel = cell.rightTextLabel else {
            NSLog("Failed to get text label")
            return cell
        }
        
        guard let spaceToneSkews = UserDefaults.standard.value(forKey: "spaceToneSkews") as? [Float] else {
            NSLog("Failed to get user defaults for tone skews")
            return cell
        }
        
        let thisSkew = spaceToneSkews[indexPath.row]
        
        textField.tag = indexPath.row
        textField.text = String(describing: thisSkew)
        
        let db = 20.0 * log10f(thisSkew)
        
        textLabel.text = String(format: "%.2f", db) + " dB"

        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        var spaceToneSkews = UserDefaults.standard.value(forKey: "spaceToneSkews") as! [Float]
        
        if editingStyle == .delete {
            // Delete the row from the data source
            
            spaceToneSkews.remove(at: indexPath.row)
            
            UserDefaults.standard.set(spaceToneSkews, forKey: "spaceToneSkews")
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            
            spaceToneSkews.append(1.0)
        }    
    }

    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        if var previousSpaceToneSkews = UserDefaults.standard.value(forKey: "spaceToneSkews") as? [Float] {
            
            let moveValue = previousSpaceToneSkews[fromIndexPath.row]
            previousSpaceToneSkews.remove(at: fromIndexPath.row)
            previousSpaceToneSkews.insert(moveValue, at: to.row)
            
            UserDefaults.standard.setValue(previousSpaceToneSkews, forKey: "spaceToneSkews")
        }

    }
 

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
