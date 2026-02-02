# Don't Do This: Naive Directory Walk

The following pattern uses `FileManager.enumerator(atPath:)` and manually
filters paths. It works for small cases, but it is easy to get wrong,
performs poorly at scale, and scatters traversal policy (ignores, scoping)
across call sites.

```swift
let fm = FileManager.default
guard let en = fm.enumerator(atPath: base) else { return [] }
var results: [String] = []
for case let rel as String in en where rel.hasSuffix("Package.swift") {
  let full = base.hasSuffix("/") ? base + rel : base + "/" + rel
  results.append((full as NSString).deletingLastPathComponent)
}
return results.sorted()
```

## Prefer: DirectoryScanningService (In‑process)

Use the shared scanning engine so scope (DocC‑only vs all), ignore rules, and
performance settings stay consistent across tools.

```swift
import SwiftDirectoryTools

let options = DirectoryScanOptions(scope: .docc, roots: [rootURL])
let service = DirectoryScanningService(options: options)
let result = try service.run()

// result.violations → kebab-case violations (via KebabCaseRule)
// result.emptyDirectories → directories recommended for deletion
// result.metrics → files/dirs visited and timing
```

Use rule composition to add or remove checks for different hosts (Foundry CLI,
mac app/status menu, CI) without changing traversal logic.
