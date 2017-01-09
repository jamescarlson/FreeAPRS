//
//  StoryboardInjection.swift
//  FreeAPRS
//
//  Created by James on 1/8/17.
//  Copyright © 2017 dimnsionofsound. All rights reserved.
//

import Foundation

import SwinjectStoryboard

extension SwinjectStoryboard {
    class func setup() {
        defaultContainer.register(AudioIOManager.self) { _ in AudioIOManager() }
    }
}
