//
//  PacketTableViewController.swift
//  FreeAPRS
//
//  Created by James on 11/25/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.

// TODO: Make a ViewModel for this if it gets too big

import UIKit

class PacketTableViewController: UITableViewController {
  
    let searchController = UISearchController(searchResultsController: nil)

    var packetDataStore : APRSPacketDataStore!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        
        packetDataStore.packetUpdates.observe { value in
            self.tableView.reloadData()
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
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
        return packetDataStore.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let packet = packetDataStore[indexPath.row]
        if packet.data == nil {
            packet.parsePacket()
        }
        
        switch packet.data?.type {
        case .some(.location):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "locationPacketCell", for: indexPath) as! LocationTableViewCell
            let cellViewModel = LocationCellViewModel(packet: packet)
            
            cell.source.text = cellViewModel.source
            cell.destination.text = cellViewModel.destination
            cell.timestamp.text = cellViewModel.timestamp
            cell.location.text = cellViewModel.location
            cell.symbol.text = cellViewModel.symbol
            cell.comment.text = cellViewModel.comment
            
            return cell
        case .some(.item):
            let cell = tableView.dequeueReusableCell(withIdentifier: "itemPacketCell", for: indexPath) as! ItemTableViewCell
            let cellViewModel = ItemCellViewModel(packet: packet)
            
            cell.source.text = cellViewModel.source
            cell.destination.text = cellViewModel.destination
            cell.timestamp.text = cellViewModel.timestamp
            cell.name.text = cellViewModel.name
            cell.location.text = cellViewModel.location
            cell.alive.text = cellViewModel.alive
            
            return cell
        case .some(.object):
            let cell = tableView.dequeueReusableCell(withIdentifier: "objectPacketCell", for: indexPath) as! ObjectTableViewCell
            let cellViewModel = ObjectCellViewModel(packet: packet)
            
            cell.source.text = cellViewModel.source
            cell.destination.text = cellViewModel.destination
            cell.timestamp.text = cellViewModel.timestamp
            cell.name.text = cellViewModel.name
            cell.location.text = cellViewModel.location
            cell.alive.text = cellViewModel.alive
            
            return cell
        case .some(.message):
            let cell = tableView.dequeueReusableCell(withIdentifier: "messageePacketCell", for: indexPath) as! MessageTableViewCell
            let cellViewModel = MessageCellViewModel(packet: packet)
            
            cell.source.text = cellViewModel.source
            cell.destination.text = cellViewModel.destination
            cell.timestamp.text = cellViewModel.timestamp
            cell.addressee.text = cellViewModel.addressee
            cell.message.text = cellViewModel.message
            cell.idNumber.text = cellViewModel.idNumber
            
            return cell
        case .some(.status):
            let cell = tableView.dequeueReusableCell(withIdentifier: "statusPacketCell", for: indexPath) as! StatusTableViewCell
            let cellViewModel = StatusCellViewModel(packet: packet)
            cell.source.text = cellViewModel.source
            cell.destination.text = cellViewModel.destination
            cell.timestamp.text = cellViewModel.timestamp
            cell.status.text = cellViewModel.status
            
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "otherPacketCell", for: indexPath) as! OtherTableViewCell
            let cellViewModel = OtherCellViewModel(packet: packet)
            cell.source.text = cellViewModel.source
            cell.destination.text = cellViewModel.destination
            cell.timestamp.text = cellViewModel.timestamp
            cell.information.text = cellViewModel.information
            
            return cell
        }
        
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

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
    
    func filterContentForSearchText(searchText: String?) {
        if searchText != nil {
            // do something
        }
    }
}

extension PacketTableViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text)
    }
}
