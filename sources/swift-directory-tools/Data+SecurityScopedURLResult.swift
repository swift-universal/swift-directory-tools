import Foundation

extension Data {
  /// Result type for security-scoped bookmark resolution operations.
  ///
  /// This enum captures the possible outcomes when attempting to resolve
  /// `Data` created from a security-scoped bookmark:
  /// - `success`: Resolution succeeded with a valid, non-stale URL.
  /// - `stale`: Resolution succeeded but the bookmark is stale and should be
  ///   recreated.
  /// - `failure`: Resolution failed with the associated error.
  public enum SecurityScopedURLResult {
    /// Resolution succeeded with a valid, non-stale URL.
    case success(URL)

    /// Resolution succeeded but bookmark is stale and should be recreated.
    case stale(URL)

    /// Resolution failed with the associated error.
    case failure(Error)
  }
}

#if os(macOS) || os(tvOS) || os(watchOS)
extension Data {
  /// Resolves the data as a security-scoped bookmark URL on Apple platforms.
  ///
  /// This method attempts to convert the receiver, which is expected to contain
  /// security-scoped bookmark data, into a usable `URL`. If the bookmark is
  /// stale, the `stale` result is returned to signal that a new bookmark should
  /// be created.
  ///
  /// Example:
  /// ```swift
  /// switch bookmarkData.resolveAsBookmarkURL {
  /// case .success(let url):
  ///     url.startAccessingSecurityScopedResource()
  ///     defer { url.stopAccessingSecurityScopedResource() }
  ///     // use the URL
  /// case .stale(let url):
  ///     let newBookmark = try url.bookmarkData(options: .withSecurityScope)
  ///     // store `newBookmark` for later use
  /// case .failure(let error):
  ///     print("Failed to resolve bookmark: \(error)")
  /// }
  /// ```
  public var resolveAsBookmarkURL: SecurityScopedURLResult {
    var isStale = false
    do {
      let url: URL = try URL(
        resolvingBookmarkData: self,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale,
      )
      return isStale ? .stale(url) : .success(url)
    } catch {
      return .failure(error)
    }
  }
}

extension URL {
  /// Creates security-scoped bookmark data for this URL.
  ///
  /// The returned data can later be resolved using ``Data/resolveAsBookmarkURL``.
  /// - Parameter picker: Unused placeholder for parity with the original API.
  /// - Returns: Bookmark data containing the security scope information for the URL.
  public func asSecurityScopedBokmarkData(picker _: Any) throws -> Data {
    try bookmarkData(
      options: [.withSecurityScope],
      includingResourceValuesForKeys: [
        .isDirectoryKey,
        .volumeNameKey,
        .volumeURLKey,
      ],
      relativeTo: nil,
    )
  }
}
#else
extension Data {
  /// Resolves the data as a security-scoped bookmark URL.
  ///
  /// Security-scoped bookmarks are not supported on this platform; this
  /// implementation always returns `.failure`.
  public var resolveAsBookmarkURL: SecurityScopedURLResult {
    .failure(
      NSError(
        domain: "SwiftDirectoryTools",
        code: -1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Security-scoped bookmarks are not supported on this platform."
        ],
      ))
  }
}

extension URL {
  /// Creates security-scoped bookmark data for this URL.
  ///
  /// Security-scoped bookmarks are not supported on this platform; this
  /// implementation always throws an error.
  public func asSecurityScopedBokmarkData(picker _: Any) throws -> Data {
    throw NSError(
      domain: "SwiftDirectoryTools",
      code: -1,
      userInfo: [
        NSLocalizedDescriptionKey: "Security-scoped bookmarks are not supported on this platform."
      ],
    )
  }
}
#endif
