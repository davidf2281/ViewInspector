import XCTest
import SwiftUI
@testable import ViewInspector

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
final class ButtonTests: XCTestCase {
    
    func testEnclosedView() throws {
        let sut = Button(action: {}, label: { Text("Test") })
        let text = try sut.inspect().button().text().string()
        XCTAssertEqual(text, "Test")
    }
    
    func testResetsModifiers() throws {
        let view = Button(action: {}, label: { Text("") }).padding()
        let sut = try view.inspect().button().text()
        XCTAssertEqual(sut.content.modifiers.count, 0)
    }
    
    func testExtractionFromSingleViewContainer() throws {
        let view = AnyView(Button(action: {}, label: { Text("") }))
        XCTAssertNoThrow(try view.inspect().anyView().button())
    }
    
    func testExtractionFromMultipleViewContainer() throws {
        let view = HStack {
            Button(action: {}, label: { Text("") })
            Button(action: {}, label: { Text("") })
        }
        XCTAssertNoThrow(try view.inspect().hStack().button(0))
        XCTAssertNoThrow(try view.inspect().hStack().button(1))
    }
    
    func testCallback() throws {
        let exp = XCTestExpectation(description: "Callback")
        let button = Button(action: {
            exp.fulfill()
        }, label: { Text("Test") })
        try button.inspect().button().tap()
        wait(for: [exp], timeout: 0.5)
    }
}

// MARK: - View Modifiers

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
final class GlobalModifiersForButton: XCTestCase {
    
    func testButtonStyle() throws {
        let sut = EmptyView().buttonStyle(PlainButtonStyle())
        XCTAssertNoThrow(try sut.inspect().emptyView())
    }
    
    func testButtonStyleInspection() throws {
        let sut1 = EmptyView().buttonStyle(PlainButtonStyle())
        let sut2 = EmptyView().buttonStyle(TestButtonStyle())
        let sut3 = EmptyView().buttonStyle(TestPrimitiveButtonStyle())
        
        XCTAssertTrue(try sut1.inspect().buttonStyle() is PlainButtonStyle)
        XCTAssertTrue(try sut2.inspect().buttonStyle() is TestButtonStyle)
        XCTAssertTrue(try sut3.inspect().buttonStyle() is TestPrimitiveButtonStyle)
    }
}

// MARK: - ButtonStyle

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
final class ButtonStyleInspectionTests: XCTestCase {
    
    func testButtonStyleConfiguration() throws {
        let sut1 = ButtonStyleConfiguration(isPressed: false)
        let sut2 = ButtonStyleConfiguration(isPressed: true)
        XCTAssertFalse(sut1.isPressed)
        XCTAssertTrue(sut2.isPressed)
    }
    
    func testPrimitiveButtonStyleConfiguration() throws {
        _ = PrimitiveButtonStyleConfiguration(onTrigger: {
            XCTFail("Not expected to be called")
        })
    }
    
    func testButtonStyle() throws {
        let sut = TestButtonStyle()
        XCTAssertEqual(try sut.inspect(isPressed: false).blur().radius, 0)
        XCTAssertEqual(try sut.inspect(isPressed: true).blur().radius, 5)
    }
    
    func testPrimitiveButtonStyleExtraction() throws {
        let sut = TestPrimitiveButtonStyle()
        XCTAssertNoThrow(
            try sut.inspect().group().view(TestPrimitiveButtonStyle.TestButton.self, 0)
        )
    }
    
    #if !os(tvOS)
    func testPrimitiveButtonStyleLabel() throws {
        let triggerExp = XCTestExpectation(description: "label.trigger()")
        triggerExp.expectedFulfillmentCount = 1
        triggerExp.assertForOverFulfill = true
        let config = PrimitiveButtonStyleConfiguration(onTrigger: {
            triggerExp.fulfill()
        })
        let view = TestPrimitiveButtonStyle.TestButton(configuration: config)
        let exp = view.inspection.inspect { view in
            let label = try view.primitiveButtonStyleLabel()
            XCTAssertEqual(try label.blur().radius, 0)
            try label.callOnTapGesture()
            let updatedLabel = try view.primitiveButtonStyleLabel()
            XCTAssertEqual(try updatedLabel.blur().radius, 5)
        }
        ViewHosting.host(view: view)
        wait(for: [exp, triggerExp], timeout: 0.1)
    }
    #endif
}

private struct TestButtonStyle: ButtonStyle {
    
    public func makeBody(configuration: TestButtonStyle.Configuration) -> some View {
        configuration.label
            .blur(radius: configuration.isPressed ? 5 : 0)
            .padding()
    }
}

private struct TestPrimitiveButtonStyle: PrimitiveButtonStyle {
    
    func makeBody(configuration: PrimitiveButtonStyle.Configuration) -> some View {
        Group {
            TestButton(configuration: configuration)
        }
    }
    
    fileprivate struct TestButton: View {
        
        let configuration: PrimitiveButtonStyle.Configuration
        @State private(set) var isPressed = false
        let inspection = Inspection<Self>()

        #if os(tvOS)
        var body: some View { EmptyView() }
        #else
        var body: some View {
            configuration.label
                .blur(radius: isPressed ? 5 : 0)
                .onTapGesture {
                    self.isPressed = true
                    self.configuration.trigger()
                }
                .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
        }
        #endif
    }
}

extension TestPrimitiveButtonStyle.TestButton: Inspectable { }
