import Foundation

/// Function to call when a function is unavailable.
private func unavailable(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError("[HTMLString] \(fn) is not available.", file: file, line: line)
}

// MARK: String

public extension String {
    @available(*, unavailable, deprecated: 3.0, renamed: "addingUnicodeEntities")
    var escapingForUnicodeHTML: String {
        unavailable()
    }

    @available(*, unavailable, deprecated: 3.0, renamed: "addingASCIIEntities")
    var escapingForASCIIHTML: String {
        unavailable()
    }

    @available(*, unavailable, deprecated: 3.0, renamed: "removingHTMLEntities")
    var unescapingFromHTML: String {
        unavailable()
    }
}

// MARK: NSString

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)

    public extension NSString {
        @nonobjc
        @available(*, unavailable, deprecated: 3.0, renamed: "addingUnicodeEntities")
        func stringByEscapingForUnicodeHTML() -> NSString {
            unavailable()
        }

        @nonobjc
        @available(*, unavailable, deprecated: 3.0, renamed: "addingASCIIEntities")
        func stringByEscapingForASCIIHTML() -> NSString {
            unavailable()
        }

        @nonobjc
        @available(*, unavailable, deprecated: 3.0, renamed: "removingHTMLEntities")
        func stringByUnescapingFromHTML() -> NSString {
            unavailable()
        }
    }

#endif
