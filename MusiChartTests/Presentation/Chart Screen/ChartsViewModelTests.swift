//
//  ChartsViewModelTests.swift
//  MusiChartTests
//
//  Created by Stella on 18.03.19.
//  Copyright © 2019 Magpie Studio Ltd. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
import RxBlocking
@testable import MusiChart

class ChartsViewModelTests: XCTestCase {
    
    var chartsViewModel: ChartsViewModel!
    
    var rxLastFM: RxLastFMServiceProviderSpy!
    var settingsManager: SettingsManagerSpy!
    var stationsManager: StationsManagerSpy!
    
    var scheduler: TestScheduler!
    var subscriptions: CompositeDisposable!
    
    override func setUp() {
        super.setUp()
        
        rxLastFM = RxLastFMServiceProviderSpy()
        settingsManager = SettingsManagerSpy()
        stationsManager = StationsManagerSpy()
        
        chartsViewModel = ChartsViewModel(rxLastFM: rxLastFM, settingsManager: settingsManager, stationsManager: stationsManager)
        
        scheduler = TestScheduler(initialClock: 0)
        subscriptions = CompositeDisposable()
    }
    
    func testInit() {
        XCTAssertNotNil(chartsViewModel.rxLastFM)
        XCTAssertNotNil(chartsViewModel.settingsManager)
        XCTAssertNotNil(chartsViewModel.stationsManager)
        XCTAssertNotNil(chartsViewModel.usernameObs)
        XCTAssertNotNil(chartsViewModel.playcount)
        XCTAssertNotNil(chartsViewModel.registeredSince)
        XCTAssertNotNil(chartsViewModel.realName)
        XCTAssertNotNil(chartsViewModel.isConnected)
        
        XCTAssertNotNil(chartsViewModel.updatePlaycountAction)
        XCTAssertNotNil(chartsViewModel.getTopArtistsAction)
        XCTAssertNotNil(chartsViewModel.getOverallTopArtistAction)
    }
    
    func testUpdatePlaycountAction() {
        
        let observer = scheduler.createObserver(String?.self)
        
        scheduler.scheduleAt(100, action: {
            _ = self.subscriptions.insert(self.chartsViewModel
                .updatePlaycountAction
                .elements
                .subscribe(observer))
        })
        
        scheduler.scheduleAt(200, action: {
            self.chartsViewModel
                .updatePlaycountAction
                .execute("user")
            
        })
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.count, 1)
        
    }
    
    func testGetTopArtistsAction() {
        
        let observer = scheduler.createObserver([ArtistCellViewModel]?.self)
        
        scheduler.scheduleAt(100, action: {
            _ = self.subscriptions.insert(self.chartsViewModel
                .getTopArtistsAction
                .elements
                .subscribe(observer))
        })
        
        let userData = (username: "user", period: LastFM.Period.week, limit: 5)
        
        scheduler.scheduleAt(200, action: {
            self.chartsViewModel
                .getTopArtistsAction
                .execute(userData)
            
        })
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.count, 1)
        
        guard let artistCellViewModels = observer.events.first?.value.element else {
            XCTFail("\(#file) \(#function) top artists are nil")
            return
        }
        
        let topArtists = artistCellViewModels!.map { artistCellViewModel in
            return Artist(name: artistCellViewModel.name, plays: artistCellViewModel.plays, imageURL: artistCellViewModel.imageURL)
        }
    
        XCTAssertNotNil(topArtists)
        XCTAssertFalse(topArtists.isEmpty)
        XCTAssertEqual(topArtists, ChartsTestSeeds.topArtists)
    }
    
    func testGetOverallTopArtistAction() {
        
        let observer = scheduler.createObserver(Artist?.self)
        
        scheduler.scheduleAt(100, action: {
            _ = self.subscriptions.insert(self.chartsViewModel
                .getOverallTopArtistAction
                .elements
                .subscribe(observer))
        })
        
        scheduler.scheduleAt(200, action: {
            self.chartsViewModel
                .getOverallTopArtistAction
                .execute("user")
            
        })
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.count, 1)
        
        guard let overallTopArtist = observer.events.first?.value.element else {
            XCTFail("\(#file) \(#function) overall top artist is nil")
            return
        }
        
        XCTAssertNotNil(overallTopArtist)
        XCTAssertEqual(overallTopArtist!, ChartsTestSeeds.overallTopArtist)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        scheduler.scheduleAt(1000, action: {
            self.subscriptions.dispose()
        })
        super.tearDown()
    }
}
