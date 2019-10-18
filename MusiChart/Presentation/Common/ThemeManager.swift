//
//  ThemeManager.swift
//  MusiChart
//
//  Created by Stella on 11.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation

protocol ThemeManaging {
    
    var tintColor: UIColor { get }
    var navigationBarColor: UIColor { get }
}

final class ThemeManager: ThemeManaging {
    
    func applyTheme(to window: UIWindow?) {
        
        // Set the tint color of the tab bar items
        window?.tintColor = self.tintColor
        
        // Remove shadow (line below) of the navigation bar
        UINavigationBar.appearance().shadowImage = UIImage()
        
        // Remove shadow (line above) of the tab bar
        UITabBar.appearance().shadowImage = UIImage()
    }
    
    var tintColor: UIColor {
        
        return UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
    }
    
    var navigationBarColor: UIColor {
        
        return UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 0.3)
    }
}
