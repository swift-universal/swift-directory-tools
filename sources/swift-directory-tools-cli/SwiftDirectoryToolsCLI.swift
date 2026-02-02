import ArgumentParser
import SwiftDirectoryTools
import Foundation
import WrkstrmFoundation
import CommonLog

@main
struct SwiftDirectoryToolsCLI: AsyncParsableCommand {
  static let configuration: CommandConfiguration = .init(
    commandName: "swift-directory-tools",
    abstract: "🗂️ Harmonize your project's text-based files into a single, unified score.",
    version: "0.1.3",
  )

  @Argument(help: "The path to the directory containing the text-based files.")
  var sourceDirectories: [String]

  @Option(
    name: .shortAndLong,
    help: "The path to the output file. Make sure to include the file name and extension (.txt).",
  )
  var outputPath: String

  @Option(
    name: [.short, .customLong("prefix")],
    parsing: .upToNextOption,
    help:
      "Only include files whose names start with the given prefixes.",
  )
  var prefixes: [String] = []

  @Option(
    name: [.customShort("x"), .customLong("ignore-suffix")],
    parsing: .upToNextOption,
    help: "Ignore files whose names end with the given suffixes.",
  )
  var ignoredSuffixes: [String] = []

  @Option(
    name: [.customShort("a"), .customLong("allow-suffix")],
    parsing: .upToNextOption,
    help: "Only include files whose names end with the given suffixes.",
  )
  var allowedSuffixes: [String] = []

  enum ConcatenationStyleOption: String, ExpressibleByArgument {
    case string
    case data

    var libraryStyle: SwiftDirectoryTools.ConcatenationStyle {
      switch self {
      case .string: .string
      case .data: .data
      }
    }
  }

  @Option(
    name: .shortAndLong,
    help:
      "Concatenation style used before writing the final text output. Options are 'string' (default) or 'data'.",
  )
  var style: ConcatenationStyleOption = .string

  @Flag(
    name: .long,
    help: "Enable performance monitoring using WrkstrmPerformance.",
  )
  var monitorPerformance: Bool = false

  func run() async throws {
    //    let start = monitorPerformance ? uptimeNanoseconds() : nil

    let expandedSourceDirectoriesURLs: [URL] = sourceDirectories.map {
      URL(fileURLWithPath: $0.homeExpandedString())
    }
    let outputURL = URL(fileURLWithPath: outputPath.homeExpandedString())

    let defaultIgnoredSuffixes: [String] = [".h", ".m", "README", "Package.swift", "Tests"]
    let combinedIgnoredSuffixes: [String] = defaultIgnoredSuffixes + ignoredSuffixes
    let sourceURLs = expandedSourceDirectoriesURLs.reduce(into: [URL]()) { partialSourceURLs, url in
      if let outputURLs = try? SwiftDirectoryTools.relevantSourceFiles(
        in: url,
        ignoringSuffixes: combinedIgnoredSuffixes,
        allowedSuffixes: allowedSuffixes,
      ) {
        partialSourceURLs.append(contentsOf: outputURLs)
      }
    }
    let filteredSourceURLs: [URL] =
      if prefixes.isEmpty {
        sourceURLs
      } else {
        sourceURLs.filter { url in
          let fileName: String = url.lastPathComponent
          return prefixes.contains { prefix in fileName.hasPrefix(prefix) }
        }
      }
    try SwiftDirectoryTools.generateSingleFile(
      from: filteredSourceURLs,
      to: outputURL,
      style: style.libraryStyle,
    )

    //    if let start {
    //      TimeMonitor.recordPreciseMeasurement(name: "swift_directory_tools_run", start: start)
    //    }
    print("Single file generated at: \(outputURL.path)")
  }
}
