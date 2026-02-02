import Foundation
import Logging
import CommonLog

public final class DirectoryScanningService: @unchecked Sendable {
  private let adapter: any DirectoryScanAdapter
  private let rules: DirectoryScanRuleSet
  private let options: DirectoryScanOptions
  private let log: Log
  private var sink: ((DirectoryScanEvent) -> Void)?

  public init(
    adapter: any DirectoryScanAdapter = InProcessSingleAdapter(),
    rules: [DirectoryScanRule] = [KebabCaseRule(), EmptyDirectoryRule()],
    options: DirectoryScanOptions,
    logger: Log = Log(
      system: "foundry", category: "scanning", maxExposureLevel: .trace, options: [.prod])
  ) {
    self.adapter = adapter
    self.rules = .init(rules)
    self.options = options
    self.log = logger
  }

  public func run() throws -> DirectoryScanResult {
    log.trace(
      "scan.begin roots=\(options.roots.map { $0.path }) scope=\(String(describing: options.scope))"
    )
    let result = try adapter.run(rules: rules, options: options, sink: sink)
    log.trace(
      "scan.end files=\(result.metrics.filesVisited) dirs=\(result.metrics.directoriesVisited) viol=\(result.violations.count) empty=\(result.emptyDirectories.count)"
    )
    return result
  }

  public func stream(_ handler: @escaping (DirectoryScanEvent) -> Void) {
    self.sink = handler
  }
}
