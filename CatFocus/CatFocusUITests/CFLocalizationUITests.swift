import XCTest

final class CFLocalizationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCoreScreensInEverySupportedLanguage() {
        let cases: [(language: String, start: String, settings: String, statsTab: String, collectionTab: String, collection: String, preset: String, run: String)] = [
            ("en", "Start", "Settings", "Stats tab", "My Cat tab", "Collection", "Training Preset", "RUN"),
            ("ja", "はじめる", "設定", "統計タブ", "わたしのルナタブ", "コレクション", "トレーニングの設定", "ランニング"),
            ("ko", "시작하기", "설정", "통계 탭", "나의 루나 탭", "컬렉션", "훈련 설정", "달리기"),
            ("zh-Hant-TW", "開始", "設定", "統計 分頁", "我的 Luna 分頁", "收藏集", "訓練設定", "跑步")
        ]

        for item in cases {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(item.language))", "UITEST_SKIP_ONBOARDING", "UITEST_RESET_PREMIUM"]
            app.launch()
            XCTAssertTrue(app.buttons[item.start].waitForExistence(timeout: 10), item.language)
            capture(app, "\(item.language)-home")

            // The row combines its localized label, value and hint for VoiceOver.
            let durationLabels = ["en": "Focus duration", "ja": "集中時間", "ko": "집중 시간", "zh-Hant-TW": "專注時間"]
            let duration = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", durationLabels[item.language]!)).firstMatch
            duration.tap()
            XCTAssertTrue(app.staticTexts[item.preset].waitForExistence(timeout: 5), item.language)
            XCTAssertTrue(app.buttons["trainingPose.training"].exists, item.language)
            capture(app, "\(item.language)-preset")
            let doneLabels = ["en": "Done", "ja": "完了", "ko": "완료", "zh-Hant-TW": "完成"]
            app.buttons[doneLabels[item.language]!].tap()

            app.buttons[item.settings].tap()
            XCTAssertTrue(app.staticTexts[item.settings].waitForExistence(timeout: 5), item.language)
            capture(app, "\(item.language)-settings")
            let closeLabels = ["en": "Close settings", "ja": "設定を閉じる", "ko": "설정 닫기", "zh-Hant-TW": "關閉設定"]
            app.buttons[closeLabels[item.language]!].tap()

            app.buttons[item.statsTab].tap()
            let activity = ["en": "Activity", "ja": "アクティビティ", "ko": "활동", "zh-Hant-TW": "活動"]
            XCTAssertTrue(app.staticTexts[activity[item.language]!].waitForExistence(timeout: 5), item.language)
            capture(app, "\(item.language)-stats")

            app.buttons[item.collectionTab].tap()
            XCTAssertTrue(app.staticTexts[item.collection].waitForExistence(timeout: 5), item.language)
            capture(app, "\(item.language)-collection")
            app.terminate()
        }
    }

    @MainActor
    func testOnboardingDialogueIsLocalizedBeforeTyping() {
        for (language, greeting) in [
            ("en", "...Wait, is someone there?"),
            ("ja", "…ん？ だれかいる？"),
            ("ko", "…잠깐, 누구 있어?"),
            ("zh-Hant-TW", "……咦，有人在嗎？")
        ] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(language))", "UITEST_OPEN_ONBOARDING"]
            app.launch()
            XCTAssertTrue(app.staticTexts[greeting].waitForExistence(timeout: 10), language)
            capture(app, "\(language)-onboarding")
            app.terminate()
        }
    }

    @MainActor
    func testContractAndResultsInEverySupportedLanguage() {
        for (language, contract, success) in [
            ("en", "PAWSOME PACT", "SUCCESS!"),
            ("ja", "にゃんとも素敵な約束", "やったね！"),
            ("ko", "루나와의 작은 약속", "해냈어요!"),
            ("zh-Hant-TW", "我們的喵喵約定", "做到了！")
        ] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(language))", "UITEST_OPEN_CONTRACT"]
            app.launch()
            XCTAssertTrue(app.staticTexts[contract].waitForExistence(timeout: 10), language)
            capture(app, "\(language)-contract")
            app.terminate()

            app.launchArguments = ["-AppleLanguages", "(\(language))", "UITEST_SKIP_ONBOARDING", "UITEST_OPEN_RESULTS"]
            app.launch()
            XCTAssertTrue(app.staticTexts[success].waitForExistence(timeout: 10), language)
            capture(app, "\(language)-results")
            app.terminate()
        }
    }

    @MainActor
    func testLanguageCanBeChangedImmediatelyAndPersistsAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "UITEST_SKIP_ONBOARDING"]
        app.launch()
        openSettings(in: app)

        let picker = app.buttons["App Language"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        XCTAssertTrue(app.staticTexts["Language"].waitForExistence(timeout: 5))
        app.buttons["language.option.ja"].tap()
        XCTAssertTrue(app.staticTexts["設定"].exists, "Settings title should change before the language page finishes dismissing")
        app.buttons["設定を閉じる"].tap()
        XCTAssertTrue(app.buttons["はじめる"].waitForExistence(timeout: 5))
        app.terminate()

        app.launchArguments = ["-AppleLanguages", "(en)", "UITEST_SKIP_ONBOARDING"]
        app.launch()
        XCTAssertTrue(app.buttons["はじめる"].waitForExistence(timeout: 5))
        openSettings(in: app)
        let japanesePicker = app.buttons["アプリの言語"]
        XCTAssertTrue(japanesePicker.waitForExistence(timeout: 5))
        japanesePicker.tap()
        XCTAssertTrue(app.staticTexts["言語"].waitForExistence(timeout: 5))
        app.buttons["language.option.system"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].exists, "Settings title should immediately return to the system language")
        XCTAssertTrue(app.staticTexts["Timer Configuration"].exists)
        app.buttons["Close settings"].tap()
        app.terminate()
    }

    @MainActor
    private func openSettings(in app: XCUIApplication) {
        let labels = ["Settings", "設定", "설정", "設定"]
        guard let button = labels.map({ app.buttons[$0] }).first(where: \.exists) else {
            XCTFail("Settings button is not available in the active app language")
            return
        }
        button.tap()
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
