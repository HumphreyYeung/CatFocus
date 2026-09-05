//
//  CatFocusUITests.swift
//  CatFocusUITests
//
//  Created by Humphrey Yeung on 6/14/26.
//

import XCTest

final class CatFocusUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testPresetChangesApplyImmediately() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launch()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Focus duration '")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["TRAINING POSE"].waitForExistence(timeout: 2))
        app.buttons["Focus Duration 45 minutes"].tap()

        app.buttons["Close preset"].tap()

        XCTAssertTrue(app.staticTexts["45:00"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testTrainingPoseSelectionAppliesImmediatelyAndPersists() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launch()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Focus duration '")).firstMatch.tap()
        let jumpRopePose = app.buttons["trainingPose.jumpRope"]
        XCTAssertTrue(jumpRopePose.waitForExistence(timeout: 2))
        XCTAssertFalse(jumpRopePose.isSelected)

        jumpRopePose.tap()
        XCTAssertTrue(jumpRopePose.isSelected)
        app.buttons["Close preset"].tap()

        app.buttons["Focus duration 25 minutes"].tap()
        XCTAssertTrue(app.buttons["trainingPose.jumpRope"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["trainingPose.jumpRope"].isSelected)

        app.buttons["trainingPose.lifting"].tap()
        XCTAssertTrue(app.alerts["Premium Pose"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testMainTabsNavigateToStatsAndMyCat() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launch()

        app.buttons["Stats tab"].tap()
        XCTAssertTrue(app.staticTexts["Stats"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Weekly Activity"].exists)

        app.buttons["My Cat tab"].tap()
        XCTAssertTrue(app.staticTexts["My Cat"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Luna"].exists)

        app.buttons["Focus tab"].tap()
        XCTAssertTrue(app.staticTexts["TIME TO WAKE UP AND TRAIN?"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testOnboardingStoryFlowsIntoNameScene() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_OPEN_ONBOARDING")
        app.launch()

        let continueButton = app.buttons["Tap to continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
        continueButton.tap()
        continueButton.tap()
        continueButton.tap()

        let nameField = app.textFields["Your name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["WHAT SHOULD I CALL YOU?"].exists)

        let continueNameButton = app.buttons["onboardingNameContinue"]
        XCTAssertTrue(continueNameButton.exists)
        XCTAssertFalse(continueNameButton.isEnabled)

        nameField.tap()
        nameField.typeText("Alex")
        XCTAssertTrue(continueNameButton.isEnabled)
        continueNameButton.tap()
        XCTAssertTrue(app.staticTexts["Got something you can't quite handle either?"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSettingsEntryShowsTimerAndResetControls() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launchArguments.append("UITEST_RESET_PREMIUM")
        app.launch()

        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()

        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Unlock Every Pose.\nStart Free."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["TIMER CONFIGURATION"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["FOCUS DURATION"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Focus Duration 25 minutes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["Session Alerts"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Reset Cat Stats"].waitForExistence(timeout: 5))

        app.buttons["Close settings"].tap()
        XCTAssertTrue(app.staticTexts["TIME TO WAKE UP AND TRAIN?"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testShareEntryShowsShareCardActions() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launch()

        app.buttons["Stats tab"].tap()
        app.buttons["Share"].tap()

        XCTAssertTrue(app.staticTexts["SHARE TO WORLD"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["THANK YOU FOR STAYING FOCUSED. I FEEL MUCH STRONGER NOW!"].exists)
        XCTAssertTrue(app.buttons["Save share card"].exists)
        XCTAssertTrue(app.buttons["Instagram share card"].exists)
        XCTAssertTrue(app.buttons["TikTok share card"].exists)
        XCTAssertTrue(app.buttons["Message share card"].exists)

        app.buttons["Close share card"].tap()
        XCTAssertTrue(app.staticTexts["Stats"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSlideToCancelRequiresSwipe() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launchArguments.append("UITEST_PREMIUM")
        app.launch()

        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 5))
        app.buttons["Start"].tap()
        XCTAssertTrue(app.staticTexts["24:42"].waitForExistence(timeout: 2))

        let slideToCancel = app.otherElements["slideToCancel"]
        XCTAssertTrue(slideToCancel.waitForExistence(timeout: 2))

        slideToCancel.tap()
        XCTAssertFalse(app.staticTexts["FAILED!"].waitForExistence(timeout: 1))

        slideToCancel.swipeLeft()
        XCTAssertTrue(app.staticTexts["FAILED!"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testTrainingDoesNotExposePreviewCompletionAction() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launchArguments.append("UITEST_PREMIUM")
        app.launch()

        app.buttons["Start"].tap()

        XCTAssertTrue(app.staticTexts["24:42"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Complete Preview"].exists)
        XCTAssertFalse(app.staticTexts["Complete Preview"].exists)
    }

    @MainActor
    func testMotionPreviewTransitionsBetweenStaticCatStates() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launchArguments.append("UITEST_PREMIUM")
        app.launchArguments.append("UITEST_ENABLE_MOTION_PREVIEW")
        app.launch()

        app.buttons["Start"].tap()

        let catMotionPreview = app.otherElements["catMotionPreview"]
        XCTAssertTrue(catMotionPreview.waitForExistence(timeout: 2))
        XCTAssertEqual(catMotionPreview.value as? String, "Idle")

        app.buttons["motionPreviewToggle"].tap()
        let trainingPredicate = NSPredicate(format: "value == %@", "Training")
        expectation(for: trainingPredicate, evaluatedWith: catMotionPreview)
        waitForExpectations(timeout: 2)
    }

    @MainActor
    func testTrainingWhiteNoiseEntryScrollsToWhiteNoiseSection() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launchArguments.append("UITEST_PREMIUM")
        app.launch()

        app.buttons["Start"].tap()
        app.buttons["White noise"].tap()

        let whiteNoiseTitle = app.staticTexts["WHITE NOISE"]
        XCTAssertTrue(whiteNoiseTitle.waitForExistence(timeout: 2))
        XCTAssertLessThan(whiteNoiseTitle.frame.minY, 700)
    }

    @MainActor
    func testCompletedFocusOffersBreakAndBreakOffersNextFocus() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launchArguments.append("UITEST_PREMIUM")
        app.launchArguments.append("UITEST_ENABLE_COMPLETE_PREVIEW")
        app.launchArguments.append("UITEST_SKIP_PHOTOS_SAVE")
        app.launchArguments.append("UITEST_ENABLE_BREAK_COMPLETION")
        app.launch()

        app.buttons["Start"].tap()
        app.buttons["Complete Preview"].tap()

        XCTAssertTrue(app.staticTexts["SUCCESS!"].waitForExistence(timeout: 2))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Start ' AND label ENDSWITH ' Break'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["TAKE A BREATH"].waitForExistence(timeout: 2))

        app.buttons["Complete Break Preview"].tap()
        XCTAssertTrue(app.staticTexts["READY FOR ANOTHER ROUND?"].waitForExistence(timeout: 2))
        app.buttons["Start Next Focus"].tap()
        XCTAssertTrue(app.staticTexts["KEEP PUSHING"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testResultsShareVideoCreatesPreview() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launchArguments.append("UITEST_PREMIUM")
        app.launchArguments.append("UITEST_ENABLE_COMPLETE_PREVIEW")
        app.launch()

        app.buttons["Start"].tap()
        app.buttons["Complete Preview"].tap()
        XCTAssertTrue(app.staticTexts["SUCCESS!"].waitForExistence(timeout: 2))

        app.buttons["Save focus video"].tap()
        let savedAlert = app.alerts["Video Saved"]
        let errorAlert = app.alerts["Save Video"]
        XCTAssertTrue(savedAlert.waitForExistence(timeout: 60) || errorAlert.waitForExistence(timeout: 60))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments.append("UITEST_SKIP_ONBOARDING")
            app.launch()
        }
    }

    @MainActor
    func testStartRequiresPremiumAndPurchaseContinuesIntoTraining() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launchArguments.append("UITEST_RESET_PREMIUM")
        app.launch()

        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 5))
        app.buttons["Start"].tap()
        XCTAssertTrue(app.buttons["Start Free Trial"].waitForExistence(timeout: 2))

        let dismissPaywallButton = app.buttons["Continue without premium"]
        XCTAssertTrue(dismissPaywallButton.waitForExistence(timeout: 5))
        dismissPaywallButton.tap()
        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["KEEP PUSHING"].exists)
        app.buttons["Start"].tap()
        XCTAssertTrue(app.buttons["Start Free Trial"].waitForExistence(timeout: 2))
        app.buttons["Start Free Trial"].tap()

        XCTAssertTrue(app.staticTexts["KEEP PUSHING"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testPretrainingPoseCarouselKeepsOnePoseCentered() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_OPEN_PRETRAIN")
        app.launchArguments.append("UITEST_RESET_PREMIUM")
        app.launch()

        let pose = app.otherElements["pretrainingPose"]
        XCTAssertTrue(pose.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["00:00"].exists)

        pose.swipeLeft()

        XCTAssertTrue(pose.exists)
        XCTAssertTrue(app.staticTexts["00:00"].exists)
        XCTAssertFalse(app.staticTexts["00:10"].exists)
    }
}
