//
//  StatusTableViewCell.swift
//  FreeAPRS
//
//  Created by James on 1/8/17.
//  Copyright © 2017 dimnsionofsound. All rights reserved.
//

import UIKit

class StatusTableViewCell: UITableViewCell {

    
    @IBOutlet weak var source: UILabel!
    @IBOutlet weak var destination: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var status: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
