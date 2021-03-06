import SwiftUI

// MARK: - ViewControlAttributesTests

@available(iOS 13.0, macOS 10.15, tvOS 13.0, *)
public extension InspectableView {
    
    func labelsHidden() throws -> Bool {
        _  = try modifierAttribute(modifierLookup: { modifier -> Bool in
            modifier.modifierType.hasPrefix("_LabeledViewStyleModifier<HiddenLabel")
        }, path: "modifier|style", type: Any.self, call: "labelsHidden")
        return true
    }
    
    func horizontalRadioGroupLayout() throws -> Bool {
        _ = try modifierAttribute(
            modifierName: "RadioGroupLayoutModifier<_HStackLayout>",
            path: "modifier|style",
            type: Any.self, call: "horizontalRadioGroupLayout")
        return true
    }
    
    #if os(macOS)
    func controlSize() throws -> ControlSize {
        let reference = EmptyView().controlSize(.regular)
        let keyPath = try Inspector.environmentKeyPath(ControlSize.self, reference)
        return try environmentModifier(keyPath: keyPath, call: "controlSize")
    }
    #endif
}
