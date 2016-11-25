//
//  SettingsTableViewController.swift
//  FreeAPRS
//
//  Created by James on 11/23/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    // MARK: - Preference Switches/Feilds
    let digipeaterSwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        //self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "defaultCellType")
        
        
        
        self.digipeaterSwitch.addTarget(self, action: #selector(changeSwtich(sender:)), for: UIControlEvents.valueChanged)
        
        
        
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 1
        } else if (section == 1) {
            return 1
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell : UITableViewCell
        
        // Configure the cell...
        if (indexPath.section == 0) {
            cell = tableView.dequeueReusableCell(withIdentifier: "swtichCell") ?? UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "switchCell")
            cell.textLabel?.text = "Filter Out Digipeated Packets"
            cell.accessoryView = digipeaterSwitch
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "spaceToneSkewCell") ?? UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "spaceToneSkewCell")
            
            cell.textLabel?.text = "Space Tone Skew Settings"
        }

        return cell
    }
    
    // MARK: - Process preference value changes
    func changeSwtich(sender: UISwitch) {
        NSLog("New value: \(sender.isOn)")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (indexPath.section == 1) {
            switch indexPath.row {
            case 0:
                //let vc = self.storyboard?.instantiateViewController(withIdentifier: "spaceToneSkewViewController")
                //navigationController?.pushViewController(vc!, animated: true)
                break
            default:
                //Do nothing
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "General"
        } else {
            return "Modem Settings"
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
