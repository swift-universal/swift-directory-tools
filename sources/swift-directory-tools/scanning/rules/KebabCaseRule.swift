import Foundation

public struct KebabCaseRule: DirectoryScanRule {
  public let id: String = "kebab-case"
  public let description: String = "Filenames must be lowercase/digits/hyphens (kebab-case)."
  private let regex = try! NSRegularExpression(pattern: "^[a-z0-9]+(-[a-z0-9]+)*$")

  public init() {}

  public func apply(file url: URL) -> DirectoryScanViolation? {
    let name = url.lastPathComponent
    if name == "Info.plist" || name.hasPrefix(".") { return nil }
    let base = url.pathExtension.isEmpty ? name : String(name.dropLast(url.pathExtension.count + 1))
    let range = NSRange(location: 0, length: base.utf16.count)
    if regex.firstMatch(in: base, options: [], range: range) == nil {
      return .init(path: url.path, reason: "not kebab-case", ruleID: id)
    }
    return nil
  }
}
