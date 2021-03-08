import XCTest
@testable import PNetwork

final class PNetworkTests: XCTestCase {
    
    func testBannerModule() {
        let expec = expectation(description: "teste")
        
        
        wait(for: [expec], timeout: 10.0)
    }

    static var allTests = [
        ("testBannerModule", testBannerModule),
    ]
}
