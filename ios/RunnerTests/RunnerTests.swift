import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testMainBundleHasExpectedBundleIdentifier() {
    let bundleId = Bundle.main.bundleIdentifier
    XCTAssertNotNil(bundleId, "Host Runner bundleIdentifier must not be nil")
    XCTAssertFalse(bundleId?.isEmpty ?? true, "Host Runner bundleIdentifier must not be empty")
    XCTAssertEqual(bundleId, "com.snoozefriend.snoozemate")
  }

  func testMainBundleInfoPlistHasVersionStrings() {
    let info = Bundle.main.infoDictionary
    XCTAssertNotNil(info, "Host Runner Info.plist dictionary must be present")

    let shortVersion = info?["CFBundleShortVersionString"] as? String
    let buildVersion = info?["CFBundleVersion"] as? String

    XCTAssertNotNil(shortVersion, "CFBundleShortVersionString must exist in Info.plist")
    XCTAssertFalse(shortVersion?.isEmpty ?? true, "CFBundleShortVersionString must not be empty")

    XCTAssertNotNil(buildVersion, "CFBundleVersion must exist in Info.plist")
    XCTAssertFalse(buildVersion?.isEmpty ?? true, "CFBundleVersion must not be empty")
  }

}
