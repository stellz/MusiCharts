//
//  MusiChartUITests.swift
//  MusiChartUITests
//
//  Created by Stella on 11/7/16.
//  Copyright © 2016 Magpie Studio Ltd. All rights reserved.
//

import XCTest

class MusiChartUITests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    func testInitialTabBarView() {
        
        XCTAssertTrue(app.tabBars.firstMatch.exists)
        
        XCTAssertTrue(app.buttons["Charts"].exists)
        XCTAssertTrue(app.buttons["Player"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
        
        XCTAssertTrue(app.buttons["Charts"].isSelected)
        
        XCTAssertFalse(app.buttons["Player"].isSelected)
        XCTAssertFalse(app.buttons["Settings"].isSelected)
    }
    
    func testChartViewControllerInitialState() {
        
        app.tabBars.firstMatch.buttons.element(boundBy: 0).tap()
        
        XCTAssertTrue(app.buttons["Charts"].isSelected)
        
        XCTAssertFalse(app.buttons["Player"].isSelected)
        XCTAssertFalse(app.buttons["Settings"].isSelected)
        
        XCTAssertTrue(app.staticTexts["Last.fm"].exists)
        XCTAssertTrue(app.staticTexts["Explore Top Music Powered by your Scrobbles"].exists)
        let predicate = NSPredicate(format: "label LIKE 'The music you listened in the last 7 days will appear here. Log in to Last.fm and listen to some tunes to discover your recent musical mood ♫♪'")
        let label = app.staticTexts.element(matching: predicate)
        XCTAssert(label.exists)
        XCTAssertTrue(app.staticTexts["Top artist of all time:"].exists)
        
        let chartTable = app.tables.element(boundBy: 0)
        XCTAssertEqual(chartTable.cells.count, 0, "There should be 0 rows initially")
    }
    
    func testStationsViewControllerInitialState() {
        
        app.tabBars.firstMatch.buttons.element(boundBy: 1).tap()
        
        XCTAssertTrue(app.buttons["Player"].isSelected)
        
        XCTAssertFalse(app.buttons["Charts"].isSelected)
        XCTAssertFalse(app.buttons["Settings"].isSelected)
        
        XCTAssertTrue(app.buttons["Add"].exists)
        XCTAssertTrue(app.buttons["Edit"].exists)
        
        XCTAssertTrue(app.staticTexts["Choose a station to begin."].exists)
        
        assertInitialStations()
        
        let cellCount = 9
        XCTAssertEqual(app.cells.count, cellCount)
        
        let texts = app.cells.staticTexts.count
        XCTAssertEqual(texts, cellCount * 2)
        
        let firstStation = app.cells.element(boundBy: 0)
        let stationName = firstStation.children(matching: .staticText).element(boundBy: 0).label
        
        firstStation.tap()
        waitForStationToLoad()
        
        let backButton = app.buttons.element(boundBy: 3)
        backButton.tap()
        
        print(app.buttons.debugDescription)
        let pauseButton = app.buttons.element(boundBy: 5)
        
        pauseButton.tap()
        let nowPlayingButton = app.buttons.element(boundBy: 6)
        //XCTAssertFalse(nowPlayingButton.isEnabled)
        
        let text = "Station Paused."
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        XCTAssertTrue(app.staticTexts.containing(predicate).count > 0)
        
        let playButton = app.buttons.element(boundBy: 5)
        
        playButton.tap()
        XCTAssertTrue(nowPlayingButton.isEnabled)
        XCTAssertFalse(app.staticTexts.containing(predicate).count > 0)
        let predicate1 = NSPredicate(format: "label CONTAINS[c] %@", stationName)
        XCTAssertTrue(app.staticTexts.containing(predicate1).count > 0)
        
        nowPlayingButton.tap()
        XCTAssertTrue(app.staticTexts["\(stationName)"].exists)
        print(app.navigationBars.debugDescription)
        app.navigationBars["Radio Swiss Jazz"].buttons["Back"].tap()
        
        nowPlayingButton.tap()
        
        let volume = app.sliders.element(boundBy: 0)
        
        volume.adjust(toNormalizedSliderPosition: 0.2)
        volume.adjust(toNormalizedSliderPosition: 0.8)
        volume.adjust(toNormalizedSliderPosition: 0.5)
    }
    
    func assertInitialStations() {
        
        XCTAssertTrue(app.staticTexts["Radio Swiss Jazz"].exists)
        XCTAssertTrue(app.staticTexts["Jazz, soul and blues around the clock"].exists)
        
        XCTAssertTrue(app.staticTexts["Rockstep Radio"].exists)
        XCTAssertTrue(app.staticTexts["Music for Swing Dancers"].exists)
        
        XCTAssertTrue(app.staticTexts["BeatBasement"].exists)
        XCTAssertTrue(app.staticTexts["Where Hip Hop Really Lives"].exists)
        
        XCTAssertTrue(app.staticTexts["WeFunk Radio"].exists)
        XCTAssertTrue(app.staticTexts["Strictly the finest in hip hop, funk & soul"].exists)
        
        XCTAssertTrue(app.staticTexts["Groove Salad"].exists)
        XCTAssertTrue(app.staticTexts["A nicely chilled plate of ambient beats and grooves"].exists)
        
        XCTAssertTrue(app.staticTexts["Ibiza Sonica Radio"].exists)
        XCTAssertTrue(app.staticTexts["Cultura de radio"].exists)
        
        XCTAssertTrue(app.staticTexts["Radio NOVA"].exists)
        XCTAssertTrue(app.staticTexts["Radio NOVA – 'Just Listen'"].exists)
        
        XCTAssertTrue(app.staticTexts["8Radio"].exists)
        XCTAssertTrue(app.staticTexts["Playing the music we like."].exists)
        
        XCTAssertTrue(app.staticTexts["Grunge90"].exists)
        XCTAssertTrue(app.staticTexts["The best of grunge from yesterday to today. Sprinkled with metal."].exists)
    }
    
    func waitForStationToLoad() {
        self.expectation(
            for: NSPredicate(format: "exists == 0"),
            evaluatedWith: app.staticTexts["Loading Station..."],
            handler: nil)
        self.waitForExpectations(timeout: 25.0, handler: nil)
        
    }
    
    func testSettingsControllerInitialState() {
        
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()
        
        XCTAssertTrue(app.buttons["Settings"].isSelected)
        
        XCTAssertFalse(app.buttons["Player"].isSelected)
        XCTAssertFalse(app.buttons["Charts"].isSelected)
        
        XCTAssertTrue(app.buttons["Login"].exists)
        XCTAssertFalse(app.buttons["Login"].isEnabled)
        
        XCTAssertTrue(app.staticTexts["Last.fm"].exists)
        XCTAssertTrue(app.staticTexts["Sleep timer"].exists)
        XCTAssertTrue(app.staticTexts["Scrobble tracks"].exists)
        XCTAssertTrue(app.staticTexts["Scrobble radio station name"].exists)
        
        let usernameTextField = app.textFields.element(boundBy: 0)
        XCTAssertEqual(usernameTextField.placeholderValue!, "Username")
        let passwordSecureTextField = app.secureTextFields.element(boundBy: 0)
        XCTAssertEqual(passwordSecureTextField.placeholderValue!, "Password")
        
        usernameTextField.tap()
        usernameTextField.typeText("blue_mushroom")
        //passwordSecureTextField.tap()
        tapElementAndWaitForKeyboardToAppear(element: passwordSecureTextField)
        passwordSecureTextField.typeText("wrong_password")
        
        XCTAssertTrue(app.buttons["Login"].isEnabled)
    
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
}

extension XCTestCase {
    
    func tapElementAndWaitForKeyboardToAppear(element: XCUIElement) {
        let keyboard = XCUIApplication().keyboards.element
        while true {
            element.tap()
            if keyboard.exists {
                break
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }
    }
}
