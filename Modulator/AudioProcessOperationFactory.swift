//
//  AudioProcessOperationFactory.swift
//  FreeAPRS
//
//  Created by James on 11/22/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

protocol AudioProcessOperationFactory {
    func getOperation() -> AudioProcessOperation
}
