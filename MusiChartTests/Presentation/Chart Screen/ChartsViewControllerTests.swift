//
//  ChartsViewControllerTests.swift
//  MusiChartTests
//
//  Created by Stella on 31.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
@testable import MusiChart

class ChartsViewControllerTests: XCTestCase {
    
    var chartsVC: ChartsViewController!
    
    var window: UIWindow!
    
    var chartsViewModelSpy: ChartsViewModelSpy!
    
    override func setUp() {
        super.setUp()
        
        self.window = UIWindow()
        
        setupChrtsViewController()
    }
    
    private func setupChrtsViewController() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        chartsVC = storyboard.instantiateViewController(withIdentifier: "ChartsViewController") as? ChartsViewController

        self.chartsViewModelSpy = ChartsViewModelSpy(rxLastFM: RxLastFMServiceProviderSpy(),
                                                     settingsManager: SettingsManagerSpy(),
                                                     stationsManager: StationsManagerSpy())
        chartsVC.bindViewModel(to: chartsViewModelSpy)
    }
    
    private func loadView() {
        self.window.addSubview(chartsVC.view)
        RunLoop.current.run(until: Date())
    }
    
    func testInit() {
        loadView()
        
        XCTAssertNotNil(chartsVC.realNameLabel)
        XCTAssertNotNil(chartsVC.scrobblesCountLabel)
        XCTAssertNotNil(chartsVC.scrobblingDateLabel)
        XCTAssertNotNil(chartsVC.lastFMLabel)
        XCTAssertNotNil(chartsVC.demoTitle)
        XCTAssertNotNil(chartsVC.chartDemoView)
        XCTAssertNotNil(chartsVC.lastFMLabel)
        XCTAssertNotNil(chartsVC.demoLabel)
        XCTAssertNotNil(chartsVC.topArtistImage)
        XCTAssertNotNil(chartsVC.topArtistLabel)
        XCTAssertNotNil(chartsVC.pieChart)
        XCTAssertNotNil(chartsVC.background)
        XCTAssertNotNil(chartsVC.scrollView)
        XCTAssertNotNil(chartsVC.shareButton)
        XCTAssertNotNil(chartsVC.pieChartItems)
        XCTAssertNotNil(chartsVC.colorArray)
        XCTAssertNotNil(chartsVC.artistTableView)
        XCTAssertNotNil(chartsVC.artistCellViewModels)
        XCTAssertNotNil(chartsVC.chartDemoView)
    }
    
    func testRefreshData() {
        chartsVC.refreshData(for: "user")
        
        XCTAssertTrue(chartsViewModelSpy.updatePlaycountActionCalled)
        XCTAssertTrue(chartsViewModelSpy.getOverallTopArtistCalled)
        
        XCTAssertTrue(chartsViewModelSpy.getTopArtistsActionCalled)
    }

}
