import Carbon
import AppKit

/// 키보드 단축키를 표현하는 모델
struct KeyShortcut: Codable, Equatable, Hashable {
    let keyCode: UInt16
    let modifiers: UInt32  // Carbon modifier flags

    /// 사람이 읽을 수 있는 단축키 문자열 (예: "⌃1", "⌥⇧A")
    var displayString: String {
        var parts = ""
        if modifiers & UInt32(controlKey) != 0 { parts += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { parts += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { parts += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { parts += "⌘" }
        parts += keyCodeToString(keyCode)
        return parts
    }

    /// CGEvent의 modifier flags에서 KeyShortcut 생성
    init(keyCode: UInt16, cgFlags: CGEventFlags) {
        self.keyCode = keyCode
        var carbonMods: UInt32 = 0
        if cgFlags.contains(.maskControl) { carbonMods |= UInt32(controlKey) }
        if cgFlags.contains(.maskAlternate) { carbonMods |= UInt32(optionKey) }
        if cgFlags.contains(.maskShift) { carbonMods |= UInt32(shiftKey) }
        if cgFlags.contains(.maskCommand) { carbonMods |= UInt32(cmdKey) }
        self.modifiers = carbonMods
    }

    /// NSEvent의 modifier flags에서 KeyShortcut 생성
    init(keyCode: UInt16, nsFlags: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        var carbonMods: UInt32 = 0
        if nsFlags.contains(.control) { carbonMods |= UInt32(controlKey) }
        if nsFlags.contains(.option) { carbonMods |= UInt32(optionKey) }
        if nsFlags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if nsFlags.contains(.command) { carbonMods |= UInt32(cmdKey) }
        self.modifiers = carbonMods
    }

    /// modifier가 1개 이상 포함되어 있는지 확인
    var hasModifier: Bool {
        modifiers != 0
    }

    /// CGEvent와 매칭되는지 확인
    func matches(keyCode: UInt16, cgFlags: CGEventFlags) -> Bool {
        guard self.keyCode == keyCode else { return false }
        let relevantFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskShift, .maskCommand]
        let eventMods = cgFlags.intersection(relevantFlags)

        var expectedFlags = CGEventFlags()
        if modifiers & UInt32(controlKey) != 0 { expectedFlags.insert(.maskControl) }
        if modifiers & UInt32(optionKey) != 0 { expectedFlags.insert(.maskAlternate) }
        if modifiers & UInt32(shiftKey) != 0 { expectedFlags.insert(.maskShift) }
        if modifiers & UInt32(cmdKey) != 0 { expectedFlags.insert(.maskCommand) }

        return eventMods == expectedFlags
    }
}

// MARK: - keyCode → 문자열 변환

private func keyCodeToString(_ keyCode: UInt16) -> String {
    // 일반적인 키 코드 매핑
    let mapping: [UInt16: String] = [
        0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
        0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
        0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
        0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
        0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
        0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
        0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
        0x25: "L", 0x26: "J", 0x28: "K", 0x2C: "/", 0x2D: "N",
        0x2E: "M", 0x2F: ".", 0x27: "'", 0x29: ";", 0x2A: "\\",
        0x2B: ",",
        // 특수 키
        0x24: "↩", 0x30: "⇥", 0x31: "Space", 0x33: "⌫",
        0x35: "⎋", 0x7A: "F1", 0x78: "F2", 0x63: "F3",
        0x76: "F4", 0x60: "F5", 0x61: "F6", 0x62: "F7",
        0x64: "F8", 0x65: "F9", 0x6D: "F10", 0x67: "F11",
        0x6F: "F12",
        0x7E: "↑", 0x7D: "↓", 0x7B: "←", 0x7C: "→",
    ]
    return mapping[keyCode] ?? "Key\(keyCode)"
}
