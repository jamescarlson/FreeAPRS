//
//  TextFieldTableViewCell.swift
//  FreeAPRS
//
//  Created by James on 11/23/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var rightTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        //textField = UITextField()
        //let leftToSuperview = NSLayoutConstraint(
        
    }
    
    override var textLabel: UILabel? {
        get {
            return nil
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
