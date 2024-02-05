import Foundation

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    public extension NSString {
        ///
        /// Returns a copy of the current `String` where every character incompatible with HTML Unicode
        /// encoding (UTF-16 or UTF-8) is replaced by a decimal HTML entity.
        ///
        /// ### Examples
        ///
        /// | String | Result | Format |
        /// |--------|--------|--------|
        /// | `&` | `&#38;` | Decimal entity (part of the Unicode special characters) |
        /// | `Σ` | `Σ` | Not escaped (Unicode compliant) |
        /// | `🇺🇸` | `🇺🇸` | Not escaped (Unicode compliant) |
        /// | `a` | `a` | Not escaped (alphanumerical) |
        ///

        @objc(stringByAddingUnicodeEntities)
        func addingUnicodeEntities() -> NSString {
            return NSString(string: String(self).addingUnicodeEntities())
        }

        ///
        /// Returns a copy of the current `String` where every character incompatible with HTML ASCII
        /// encoding is replaced by a decimal HTML entity.
        ///
        /// ### Examples
        ///
        /// | String | Result | Format |
        /// |--------|--------|--------|
        /// | `&` | `&#38;` | Decimal entity |
        /// | `Σ` | `&#931;` | Decimal entity |
        /// | `🇺🇸` | `&#127482;&#127480;` | Combined decimal entities (extented grapheme cluster) |
        /// | `a` | `a` | Not escaped (alphanumerical) |
        ///
        /// ### Performance
        ///
        /// If your webpage is unicode encoded (UTF-16 or UTF-8) use `addingUnicodeEntities` instead,
        /// as it is faster and produces a less bloated and more readable HTML.
        ///

        @objc(stringByAddingASCIIEntities)
        func addingASCIIEntities() -> NSString {
            return NSString(string: String(self).addingASCIIEntities())
        }

        ///
        /// Returns a copy of the current `String` where every HTML entity is replaced with the matching
        /// Unicode character.
        ///
        /// ### Examples
        ///
        /// | String | Result | Format |
        /// |--------|--------|--------|
        /// | `&amp;` | `&` | Keyword entity |
        /// | `&#931;` | `Σ` | Decimal entity |
        /// | `&#x10d;` | `č` | Hexadecimal entity |
        /// | `&#127482;&#127480;` | `🇺🇸` | Combined decimal entities (extented grapheme cluster) |
        /// | `a` | `a` | Not an entity |
        /// | `&` | `&` | Not an entity |
        ///

        @objc(stringByRemovingHTMLEntities)
        func removingHTMLEntities() -> NSString {
            return NSString(string: String(self).removingHTMLEntities())
        }
    }
#endif
