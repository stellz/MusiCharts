//
//  TabBarController.swift
//  MusiChart
//
//  Created by Stella on 18.02.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import Foundation
import UIKit

class TabBarController: UITabBarController {
    
    let rxLastFM = RxLastFMServiceProvider()
    let settingsManager = SettingsManager(settingsRepo: SettingsRepository())
    let stationsManager = StationsManager(stationsRepo: StationsRepository(stationsProvider: StationsProvider()))
    let themeManager = ThemeManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupControllers()
    }
    
    private func setupControllers() {
        viewControllers?.forEach({ controller in
            
            switch controller {
            case is ChartsViewController:
                setupChartsController(controller)
            case is SettingsViewController:
                setupSettingsController(controller)
            case is UINavigationController:
                guard let controller = controller as? UINavigationController else { return }
                controller.viewControllers.forEach({ controller in
                    if controller.isKind(of: StationsViewController.self) {
                        setupStationsController(controller)
                    }
                })
            default:
                break
            }
        })
    }
    
    private func setupChartsController(_ controller: UIViewController) {
        let chartsVC = controller as? ChartsViewController
        let chartsViewModel = ChartsViewModel(rxLastFM: rxLastFM,
                                              settingsManager: settingsManager,
                                              stationsManager: stationsManager)
        chartsVC?.bindViewModel(to: chartsViewModel)
    }
    
    private func setupSettingsController(_ controller: UIViewController) {
        let settingsVC = controller as? SettingsViewController
        let settingsViewModel = SettingsViewModel(rxLastFM: rxLastFM, settingsManager: settingsManager)
        settingsVC?.bindViewModel(to: settingsViewModel)
    }
    
    private func setupStationsController(_ controller: UIViewController) {
        let stationsVC = controller as? StationsViewController
        let stationsViewModel = StationsViewModel(rxLastFM: RxLastFMServiceProvider(),
                                                  stationsManager: stationsManager,
                                                  settingsManager: settingsManager,
                                                  themeManager: themeManager,
                                                  player: MusiChartPlayer())
        stationsVC?.bindViewModel(to: stationsViewModel)
    }
}
