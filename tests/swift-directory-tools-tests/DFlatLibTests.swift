import Dispatch
import Foundation
import Testing
import CommonLog

@testable import SwiftDirectoryTools

/// Placeholder example test demonstrating the `Testing` framework.
@Test func example() async throws {
  // Write your test here and use APIs like `#expect(...)` to check expected conditions.
}

/// Ensures directories with ignored prefixes, such as `.git`, are not traversed.
@Test func skipsIgnoredDirectories() throws {
  let fileManager = FileManager.default
  let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: tempDir) }

  let includeDir = tempDir.appendingPathComponent("Include")
  try fileManager.createDirectory(at: includeDir, withIntermediateDirectories: true)
  let includedFile = includeDir.appendingPathComponent("file.swift")
  try "// included".write(to: includedFile, atomically: true, encoding: .utf8)

  let gitDir = tempDir.appendingPathComponent(".git")
  try fileManager.createDirectory(at: gitDir, withIntermediateDirectories: true)
  let ignoredFile = gitDir.appendingPathComponent("ignored.swift")
  try "// ignored".write(to: ignoredFile, atomically: true, encoding: .utf8)

  let files = try SwiftDirectoryTools.relevantSourceFiles(in: tempDir)
  #expect(files.count == 1)
  #expect(files.contains { $0.lastPathComponent == "file.swift" })
  #expect(!files.contains { $0.lastPathComponent == "ignored.swift" })
}

/// Ensures directories whose names end with ignored suffixes are skipped.
@Test func skipsDirectoriesWithIgnoredSuffixes() throws {
  let fileManager = FileManager.default
  let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: tempDir) }

  let includedFile = tempDir.appendingPathComponent("included.swift")
  try "// included".write(to: includedFile, atomically: true, encoding: .utf8)

  let testsDir = tempDir.appendingPathComponent("ModuleTests")
  try fileManager.createDirectory(at: testsDir, withIntermediateDirectories: true)
  let ignoredFile = testsDir.appendingPathComponent("ignored.swift")
  try "// ignored".write(to: ignoredFile, atomically: true, encoding: .utf8)

  let files = try SwiftDirectoryTools.relevantSourceFiles(in: tempDir, ignoringSuffixes: ["Tests"])
  #expect(files.count == 1)
  #expect(files.contains { $0.lastPathComponent == "included.swift" })
  #expect(!files.contains { $0.lastPathComponent == "ignored.swift" })
}

/// Ensures files with ignored suffixes are skipped.
@Test func skipsFilesWithIgnoredSuffixes() throws {
  let fileManager: FileManager = .default
  let tempDir: URL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: tempDir) }

  let includedFile: URL = tempDir.appendingPathComponent("included.swift")
  try "// included".write(to: includedFile, atomically: true, encoding: .utf8)
  let ignoredFile: URL = tempDir.appendingPathComponent("ignored.log")
  try "// ignored".write(to: ignoredFile, atomically: true, encoding: .utf8)

  let files: [URL] = try SwiftDirectoryTools.relevantSourceFiles(in: tempDir, ignoringSuffixes: [".log"])
  #expect(files.count == 1)
  #expect(files.contains { $0.lastPathComponent == "included.swift" })
  #expect(!files.contains { $0.lastPathComponent == "ignored.log" })
}

/// Ensures only files with allowed suffixes are included.
@Test func includesOnlyAllowedSuffixes() throws {
  let fileManager: FileManager = .default
  let tempDir: URL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: tempDir) }

  let swiftFile: URL = tempDir.appendingPathComponent("file.swift")
  try "// swift".write(to: swiftFile, atomically: true, encoding: .utf8)
  let mdFile: URL = tempDir.appendingPathComponent("doc.md")
  try "# doc".write(to: mdFile, atomically: true, encoding: .utf8)
  let txtFile: URL = tempDir.appendingPathComponent("note.txt")
  try "txt".write(to: txtFile, atomically: true, encoding: .utf8)

  let files: [URL] = try SwiftDirectoryTools.relevantSourceFiles(
    in: tempDir,
    allowedSuffixes: [".swift", ".md"],
  )
  #expect(files.count == 2)
  #expect(files.contains { $0.lastPathComponent == "file.swift" })
  #expect(files.contains { $0.lastPathComponent == "doc.md" })
  #expect(!files.contains { $0.lastPathComponent == "note.txt" })
}

/// Ensures source files can be concatenated into a single data buffer.
@Test func concatenatesFilesIntoData() throws {
  let fileManager = FileManager.default
  let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: tempDir) }

  let firstFile = tempDir.appendingPathComponent("one.swift")
  try "first".write(to: firstFile, atomically: true, encoding: .utf8)
  let secondFile = tempDir.appendingPathComponent("two.swift")
  try "second".write(to: secondFile, atomically: true, encoding: .utf8)

  let data = SwiftDirectoryTools.concatenateIntoSingleData(from: [firstFile, secondFile])
  let expected = "// \(firstFile.path)\nfirst\n// \(secondFile.path)\nsecond\n"
  let output = String(decoding: data, as: UTF8.self)
  #expect(output == expected)

  let scan = SwiftDirectoryTools.Scan(source: .data(data), fileCount: 2)
  #expect(scan.sourceData == data)
  #expect(scan.sourceString == expected)
}

/// Ensures git patch generation includes file contents for new files.
@Test func generatesGitPatch() throws {
  let fileManager = FileManager.default
  let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: tempDir) }

  let firstFile = tempDir.appendingPathComponent("one.swift")
  try "first\n".write(to: firstFile, atomically: true, encoding: .utf8)
  let secondFile = tempDir.appendingPathComponent("two.swift")
  try "second\n".write(to: secondFile, atomically: true, encoding: .utf8)

  let patch = SwiftDirectoryTools.generateGitPatch(from: [firstFile, secondFile])
  #expect(patch.contains("diff --git a/\(firstFile.path) b/\(firstFile.path)"))
  #expect(patch.contains("+first"))
  #expect(patch.contains("diff --git a/\(secondFile.path) b/\(secondFile.path)"))
  #expect(patch.contains("+second"))
}

/// Compares performance of data vs string concatenation strategies.
@Test func dataConcatenationPerformanceComparison() throws {
  let fileManager = FileManager.default
  let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: tempDir) }

  // Test configuration constants
  let fileContentRepeatCount = 10000
  let testFileCount = 200

  // Create a set of source files with sizeable content
  let content = String(repeating: "1234567890", count: fileContentRepeatCount)
  for index in 0..<testFileCount {
    let url = tempDir.appendingPathComponent("file\(index).swift")
    try content.write(to: url, atomically: true, encoding: .utf8)
  }

  let files = try SwiftDirectoryTools.relevantSourceFiles(in: tempDir)

  func stringConcatenate(from sourceURLs: [URL]) -> String {
    var fileContents = ""
    for sourceURL in sourceURLs {
      guard let sourceContents = try? String(contentsOf: sourceURL, encoding: .utf8) else {
        continue
      }
      fileContents += """
        // \(sourceURL.path)
        \(sourceContents)

        """
    }
    return fileContents
  }

  let iterations = 20
  var dataTotal: UInt64 = 0
  var stringTotal: UInt64 = 0

  for _ in 0..<iterations {
    var start = DispatchTime.now().uptimeNanoseconds
    _ = SwiftDirectoryTools.concatenateIntoSingleData(from: files)
    dataTotal += DispatchTime.now().uptimeNanoseconds - start

    start = DispatchTime.now().uptimeNanoseconds
    _ = stringConcatenate(from: files)
    stringTotal += DispatchTime.now().uptimeNanoseconds - start
  }

  let dataAverage = Double(dataTotal) / Double(iterations)
  let stringAverage = Double(stringTotal) / Double(iterations)
  Log.info("Data concatenation average: \(dataAverage) ns")
  Log.info("String concatenation average: \(stringAverage) ns")
  let difference = stringAverage - dataAverage
  Log.info("Average difference (string - data): \(difference) ns")
  #expect(dataAverage < stringAverage)
}

/// Stress test with larger files to ensure concatenation performance scales.
@Test func heavyDataConcatenationStressTest() throws {
  let fileManager = FileManager.default
  let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? fileManager.removeItem(at: tempDir) }

  let fileContentRepeatCount = 20000
  let testFileCount = 300
  let content = String(repeating: "1234567890", count: fileContentRepeatCount)
  for index in 0..<testFileCount {
    let url = tempDir.appendingPathComponent("file\(index).swift")
    try content.write(to: url, atomically: true, encoding: .utf8)
  }

  let files = try SwiftDirectoryTools.relevantSourceFiles(in: tempDir)

  func stringConcatenate(from sourceURLs: [URL]) -> String {
    var fileContents = ""
    for sourceURL in sourceURLs {
      guard let sourceContents = try? String(contentsOf: sourceURL, encoding: .utf8) else {
        continue
      }
      fileContents += """
        // \(sourceURL.path)
        \(sourceContents)

        """
    }
    return fileContents
  }

  let iterations = 10
  var dataTotal: UInt64 = 0
  var stringTotal: UInt64 = 0

  for _ in 0..<iterations {
    var start = DispatchTime.now().uptimeNanoseconds
    _ = SwiftDirectoryTools.concatenateIntoSingleData(from: files)
    dataTotal += DispatchTime.now().uptimeNanoseconds - start

    start = DispatchTime.now().uptimeNanoseconds
    _ = stringConcatenate(from: files)
    stringTotal += DispatchTime.now().uptimeNanoseconds - start
  }

  let dataAverage = Double(dataTotal) / Double(iterations)
  let stringAverage = Double(stringTotal) / Double(iterations)
  Log.info("Heavy data concatenation average: \(dataAverage) ns")
  Log.info("Heavy string concatenation average: \(stringAverage) ns")
  #expect(dataAverage < stringAverage)
}
