import Foundation
import CommonLog
import WrkstrmMain

extension SwiftDirectoryTools {
  public enum ConcatenationStyle {
    case string
    case data
  }

  public enum ConcatenatedSource {
    case string(String)
    case data(Data)
  }

  public struct Scan {
    public let source: ConcatenatedSource
    public let fileCount: Int

    public var sourceString: String {
      switch source {
      case .string(let string):
        string

      case .data(let data):
        String(decoding: data, as: UTF8.self)
      }
    }

    public var sourceData: Data {
      switch source {
      case .string(let string):
        Data(string.utf8)

      case .data(let data):
        data
      }
    }
  }
}

/// A utility library for flattening source code directories into single files.
///
/// SwiftDirectoryTools provides functionality to:
/// - Enumerate source files in directories while respecting ignore patterns
/// - Handle security-scoped directory access
/// - Concatenate multiple source files into a single file
/// - Generate combined source files with proper headers
///
/// Example usage:
/// ```swift
/// do {
///     // Get source files from a directory
///     let sourceFiles = try SwiftDirectoryTools.relevantSourceFiles(in: directoryURL)
///
///     // Combine them into a single string
///     let combined = SwiftDirectoryTools.concatenateIntoSingleString(from: sourceFiles)
///
///     // Or write directly to a file
///     try SwiftDirectoryTools.generateSingleFile(from: sourceFiles, to: outputURL)
/// } catch {
///     print("Error: \(error)")
/// }
/// ```
public enum SwiftDirectoryTools {
  /// Errors that can occur during file operations
  public enum FileError: Error {
    /// Stale bookmark data was encountered
    case staleBookmarkData(URL)
    /// Failed to access a security-scoped directory
    case unableToAccessSecurityScopedDirectory(URL)
    /// Failed to enumerate contents of a directory
    case unableToEnumerateDirectory(URL)
    /// Failed to read contents of a file
    case unableToReadFile(URL)
  }

  /// Contains ignore patterns for file enumeration
  public enum Ignore {
    /// Standard prefixes for directories and files to ignore
    ///
    /// Includes common patterns like:
    /// - Build artifacts (.build)
    /// - Version control (.git, .github)
    /// - Package management (.swiftpm)
    /// - System files (.DS_Store)
    /// - Project configuration files (.tulsiconf)
    public static let directoryIgnorePrefixes: [String] = [
      ".build",
      ".DS_Store",
      ".flf",  // Figlet font files
      ".flf2a",  // Figlet font files
      ".git",
      ".github",
      ".gitignore",
      ".json",
      ".spi",
      ".swiftpm",
      ".tulsiconf",
      ".tulsiproj",
      "BUILD",
      "LICENSE",
      "Package.resolved",
    ]
  }

  /// Gets relevant source files from a security-scoped bookmark.
  ///
  /// This method resolves a security-scoped bookmark, accesses the directory,
  /// and returns all relevant source files while respecting ignore patterns.
  ///
  /// - Parameters:
  ///   - bookmarkData: The security-scoped bookmark data for the directory
  ///   - verbose: Whether to log detailed processing information
  /// - Returns: Array of URLs for relevant source files
  /// - Throws: `FileError` if unable to access or enumerate the directory
  public static func performScanAndConcatenate(
    from bookmarkData: Data,
    verbose: Bool,
    style: ConcatenationStyle = .string,
  ) throws -> Self.Scan {
    switch bookmarkData.resolveAsBookmarkURL {
    case .success(let bookmarkURL):
      Log.verbose("Resolved bookmark data to URL: \(bookmarkURL)")
      #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
      guard bookmarkURL.startAccessingSecurityScopedResource() else {
        throw Self.FileError.unableToAccessSecurityScopedDirectory(bookmarkURL)
      }
      defer { bookmarkURL.stopAccessingSecurityScopedResource() }
      #endif
      let sourceFiles: [URL] = try relevantSourceFiles(in: bookmarkURL, verbose: verbose)
      switch style {
      case .string:
        return .init(
          source: .string(concatenateIntoSingleString(from: sourceFiles)),
          fileCount: sourceFiles.count,
        )

      case .data:
        return .init(
          source: .data(concatenateIntoSingleData(from: sourceFiles)),
          fileCount: sourceFiles.count,
        )
      }

    case .stale(let bookmarkURL):
      Log.info("Resolved bookmark data is stale for: \(bookmarkURL)")
      throw FileError.staleBookmarkData(bookmarkURL)

    case .failure(let error):
      Log.error(error)
      throw error
    }
  }

  /// Gets relevant source files from a directory URL.
  ///
  /// This method enumerates all files in a directory and its subdirectories,
  /// filtering out files that match ignore patterns or aren't regular files.
  ///
  /// - Parameters:
  ///   - directoryURL: The URL of the directory to process
  ///   - ignoringSuffixes: Additional file suffixes to ignore
  ///   - allowedSuffixes: File suffixes that are allowed. When empty all suffixes are allowed.
  ///   - verbose: Whether to log detailed processing information
  /// - Returns: Array of URLs for relevant source files
  /// - Throws: `FileError` if unable to enumerate the directory
  public static func relevantSourceFiles(
    in directoryURL: URL,
    ignoringSuffixes: [String] = [],
    allowedSuffixes: [String] = [],
    verbose: Bool = false,
  ) throws -> [URL] {
    if verbose {
      Log.verbose("directoryURL: \(directoryURL)")
    }
    var relevantFiles: [URL] = []
    var ignoredFiles: [URL]? = verbose ? [] : nil

    let fileManager: FileManager = .default
    guard
      let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(
        at: directoryURL,
        includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
        options: [.producesRelativePathURLs],
      )
    else {
      throw Self.FileError.unableToEnumerateDirectory(directoryURL)
    }

    while let item = enumerator.nextObject() as? URL {
      if verbose {
        Log.verbose("Checking: \(item.path)")
      }
      let hasIgnoredComponent = item.pathComponents.contains { component in
        for ignoredSequence in Self.Ignore.directoryIgnorePrefixes + ignoringSuffixes
        where component.hasPrefix(ignoredSequence) || component.hasSuffix(ignoredSequence) {
          return true
        }
        return false
      }
      if hasIgnoredComponent {
        if verbose {
          ignoredFiles?.append(item)
        }
        if let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey]),
          resourceValues.isDirectory == true
        {
          enumerator.skipDescendants()
        }
        continue
      }

      guard let resourceValues = try? item.resourceValues(forKeys: [.isRegularFileKey]),
        resourceValues.isRegularFile == true
      else {
        if verbose {
          ignoredFiles?.append(item)
        }
        continue
      }

      if !allowedSuffixes.isEmpty {
        let fileName: String = item.lastPathComponent
        let isAllowed: Bool = allowedSuffixes.contains { suffix in
          fileName.hasSuffix(suffix)
        }
        if !isAllowed {
          if verbose {
            ignoredFiles?.append(item)
          }
          continue
        }
      }

      relevantFiles.append(item)
    }
    if verbose {
      Log.verbose("Found \(relevantFiles.count) relevant files in \(directoryURL.path)")
      for relevantFile in relevantFiles {
        Log.verbose("Flattening: \(relevantFile.path)")
      }
      if let ignoredFiles {
        Log.verbose("Ignored \(ignoredFiles.count) ignored files in \(directoryURL.path)")
        for ignoredFile in ignoredFiles {
          Log.verbose("Ignoring \(ignoredFile.path)")
        }
      }
    }
    return relevantFiles
  }

  /// Concatenates multiple source files into a single data buffer.
  ///
  /// Each file's contents is prefixed with a comment containing its path.
  /// Files are separated by newlines for readability.
  ///
  /// - Parameter sourceURLs: Array of URLs for the source files to combine
  /// - Returns: A `Data` object containing all file contents with headers
  static func concatenateIntoSingleData(from sourceURLs: [URL]) -> Data {
    let newline = Data("\n".utf8)

    var estimatedSize = 0
    for url in sourceURLs {
      if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
        estimatedSize += fileSize
      }
      estimatedSize += url.path.count + 4  // // + space + path + newline + trailing newline
    }

    var fileContents: Data = .init()
    fileContents.reserveCapacity(estimatedSize)

    for sourceURL in sourceURLs {
      guard let sourceData = try? Data(contentsOf: sourceURL) else {
        Log.error(Self.FileError.unableToReadFile(sourceURL))
        continue
      }

      if let headerData = "// \(sourceURL.path)\n".data(using: .utf8) {
        fileContents.append(headerData)
      }
      fileContents.append(sourceData)
      fileContents.append(newline)
    }

    return fileContents
  }

  /// Concatenates multiple source files into a single string.
  ///
  /// Each file's contents is prefixed with a comment containing its path.
  /// Files are separated by newlines for readability.
  ///
  /// - Parameter sourceURLs: Array of URLs for the source files to combine
  /// - Returns: A string containing all file contents with headers
  private static func concatenateIntoSingleString(from sourceURLs: [URL])
    -> String
  {
    var fileContents = ""
    for sourceURL in sourceURLs {
      guard let sourceContents = try? String(contentsOf: sourceURL, encoding: .utf8) else {
        Log.error(Self.FileError.unableToReadFile(sourceURL))
        continue
      }

      fileContents += """
        // \(sourceURL.path)
        \(sourceContents)

        """
    }
    return fileContents
  }

  /// Generates a single file from multiple source files.
  ///
  /// Combines the contents of multiple source files and writes them to a destination file.
  /// Each source file's contents is prefixed with a comment containing its path.
  ///
  /// NOTE: Security-scoped access is required for the source files.
  ///
  /// - Parameters:
  ///   - sourceURLs: Array of URLs for the source files to combine.
  ///   - destinationURL: The URL where the combined file should be written
  /// - Throws: An error if writing the file fails
  public static func generateSingleFile(
    from sourceURLs: [URL],
    to destinationURL: URL,
    style: ConcatenationStyle = .string,
  ) throws {
    let fileContents: String
    switch style {
    case .string:
      fileContents = concatenateIntoSingleString(from: sourceURLs)

    case .data:
      let data: Data = concatenateIntoSingleData(from: sourceURLs)
      fileContents = String(decoding: data, as: UTF8.self)
    }
    try fileContents.write(to: destinationURL, atomically: false, encoding: .utf8)
  }

  /// Creates a git patch representation for the provided source files.
  ///
  /// Each file is represented as a patch diff from `/dev/null` to its path,
  /// allowing the patch to be applied to create the file from scratch.
  /// - Parameter sourceURLs: Array of URLs for the source files to include.
  /// - Returns: A git patch string containing all files.
  public static func generateGitPatch(from sourceURLs: [URL]) -> String {
    var patch = ""
    for sourceURL in sourceURLs {
      guard let contents = try? String(contentsOf: sourceURL, encoding: .utf8) else {
        Log.error(Self.FileError.unableToReadFile(sourceURL))
        continue
      }
      let lines = contents.components(separatedBy: "\n")
      let path = sourceURL.path
      patch += "diff --git a/\(path) b/\(path)\n"
      patch += "new file mode 100644\n"
      patch += "--- /dev/null\n"
      patch += "+++ b/\(path)\n"
      let lineCount = (lines.last == "" ? lines.count - 1 : lines.count)
      patch += "@@ -0,0 +1,\(lineCount) @@\n"
      for i in 0..<lineCount {
        patch += "+\(lines[i])\n"
      }
    }
    return patch
  }

  /// Generates a git patch file from multiple source files.
  ///
  /// - Parameters:
  ///   - sourceURLs: Array of URLs for the source files to include.
  ///   - destinationURL: The URL where the patch should be written.
  /// - Throws: An error if writing the file fails.
  public static func generateGitPatch(
    from sourceURLs: [URL],
    to destinationURL: URL,
  ) throws {
    let patch: String = generateGitPatch(from: sourceURLs)
    try patch.write(to: destinationURL, atomically: false, encoding: .utf8)
  }
}
