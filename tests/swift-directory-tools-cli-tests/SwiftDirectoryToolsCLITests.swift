import SwiftDirectoryTools
import Foundation
import Testing

@testable import SwiftDirectoryToolsCLI

struct SwiftDirectoryToolsCLITests {
  @Test func testGenerateSingleFile() throws {
    let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
    let sourceFiles: [URL] = [
      tempDirectoryURL.appendingPathComponent("file1.swift"),
      tempDirectoryURL.appendingPathComponent("file2.md"),
      tempDirectoryURL.appendingPathComponent("file3.yaml"),
    ]

    try sourceFiles.forEach { (url: URL) in
      let content = "This is the content of \(url.lastPathComponent)"
      try content.write(to: url, atomically: true, encoding: .utf8)
    }

    let outputURL: URL = tempDirectoryURL.appendingPathComponent("ProjectScore.txt")
    try SwiftDirectoryTools.generateSingleFile(
      from: sourceFiles,
      to: outputURL,
      style: .string,
    )

    let generatedContent: String = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(generatedContent.contains("// \(sourceFiles[0].path)"))
    #expect(generatedContent.contains("// \(sourceFiles[1].path)"))
    #expect(generatedContent.contains("// \(sourceFiles[2].path)"))
  }

  @Test func generateSingleFileDataStyle() throws {
    let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
    let sourceFiles: [URL] = [
      tempDirectoryURL.appendingPathComponent("file1.swift"),
      tempDirectoryURL.appendingPathComponent("file2.md"),
    ]

    try sourceFiles.forEach { (url: URL) in
      let content = "This is the content of \(url.lastPathComponent)"
      try content.write(to: url, atomically: true, encoding: .utf8)
    }

    let outputURL: URL = tempDirectoryURL.appendingPathComponent("ProjectScoreData.txt")
    try SwiftDirectoryTools.generateSingleFile(
      from: sourceFiles,
      to: outputURL,
      style: .data,
    )

    let generatedContent: String = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(generatedContent.contains("// \(sourceFiles[0].path)"))
    #expect(generatedContent.contains("// \(sourceFiles[1].path)"))
  }

  @Test func prefixFiltering() async throws {
    let tempDir: URL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let agentsURL: URL = tempDir.appendingPathComponent("AGENTS.md")
    try "agents".write(to: agentsURL, atomically: true, encoding: .utf8)

    let agencyURL: URL = tempDir.appendingPathComponent("AGENCY.md")
    try "agency".write(to: agencyURL, atomically: true, encoding: .utf8)

    let otherURL: URL = tempDir.appendingPathComponent("OTHER.md")
    try "other".write(to: otherURL, atomically: true, encoding: .utf8)

    let outputURL: URL = tempDir.appendingPathComponent("Filtered.txt")
    let command: SwiftDirectoryToolsCLI = try SwiftDirectoryToolsCLI.parse([
      tempDir.path,
      "--output-path",
      outputURL.path,
      "--prefix",
      "AGEN",
    ])
    try await command.run()

    let generatedContent: String = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(generatedContent.contains("// \(agentsURL.path)"))
    #expect(generatedContent.contains("// \(agencyURL.path)"))
    #expect(!generatedContent.contains("// \(otherURL.path)"))
  }

  @Test func allowSuffixFiltering() async throws {
    let tempDir: URL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let swiftURL: URL = tempDir.appendingPathComponent("file.swift")
    try "swift".write(to: swiftURL, atomically: true, encoding: .utf8)
    let mdURL: URL = tempDir.appendingPathComponent("file.md")
    try "md".write(to: mdURL, atomically: true, encoding: .utf8)

    let outputURL: URL = tempDir.appendingPathComponent("Allowed.txt")
    let command: SwiftDirectoryToolsCLI = try SwiftDirectoryToolsCLI.parse([
      tempDir.path,
      "--output-path",
      outputURL.path,
      "--allow-suffix",
      ".md",
    ])
    try await command.run()

    let generatedContent: String = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(generatedContent.contains("// \(mdURL.path)"))
    #expect(!generatedContent.contains("// \(swiftURL.path)"))
  }

  @Test func ignoreSuffixFiltering() async throws {
    let tempDir: URL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let swiftURL: URL = tempDir.appendingPathComponent("file.swift")
    try "swift".write(to: swiftURL, atomically: true, encoding: .utf8)
    let mdURL: URL = tempDir.appendingPathComponent("file.md")
    try "md".write(to: mdURL, atomically: true, encoding: .utf8)

    let outputURL: URL = tempDir.appendingPathComponent("Ignored.txt")
    let command: SwiftDirectoryToolsCLI = try SwiftDirectoryToolsCLI.parse([
      tempDir.path,
      "--output-path",
      outputURL.path,
      "--ignore-suffix",
      ".md",
    ])
    try await command.run()

    let generatedContent: String = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(generatedContent.contains("// \(swiftURL.path)"))
    #expect(!generatedContent.contains("// \(mdURL.path)"))
  }
}
