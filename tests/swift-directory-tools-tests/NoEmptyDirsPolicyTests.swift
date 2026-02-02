import Foundation
import Testing

@testable import SwiftDirectoryTools

@Test("NoEmptyDirsPolicy modes: strictZero vs ignoreNoise vs custom")
func noEmptyDirs_modes() async throws {
  let fm = FileManager.default
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "noempty-\(UUID().uuidString)")
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)

  let a = tmp.appendingPathComponent("A")  // contains .DS_Store only
  let b = tmp.appendingPathComponent("B")  // contains .gitkeep only
  let c = tmp.appendingPathComponent("C")  // contains file.txt
  try fm.createDirectory(at: a, withIntermediateDirectories: true)
  try fm.createDirectory(at: b, withIntermediateDirectories: true)
  try fm.createDirectory(at: c, withIntermediateDirectories: true)
  fm.createFile(
    atPath: a.appendingPathComponent(".DS_Store").path, contents: Data(), attributes: nil)
  fm.createFile(
    atPath: b.appendingPathComponent(".gitkeep").path, contents: Data(), attributes: nil)
  fm.createFile(
    atPath: c.appendingPathComponent("file.txt").path, contents: Data("x".utf8), attributes: nil)

  let emptyResult = DirectoryScanResult(
    violations: [], emptyDirectories: [],
    metrics: .init(filesVisited: 0, directoriesVisited: 0, duration: 0, start: .now, end: .now))

  // strictZero: .DS_Store and .gitkeep count as content → no empties
  let pStrict = NoEmptyDirsPolicy(mode: .strictZero, roots: [tmp])
  #expect(pStrict.evaluate(result: emptyResult).isEmpty)

  // ignoreNoise: ignore .DS_Store → A is empty; B not empty; C not empty
  let pNoise = NoEmptyDirsPolicy(mode: .ignoreNoise, roots: [tmp])
  let noiseFindings = pNoise.evaluate(result: emptyResult)
  #expect(noiseFindings.count == 1)

  // custom: keep .gitkeep → B is empty; A not empty (unless .DS_Store added to ignore)
  let pCustom = NoEmptyDirsPolicy(mode: .custom(ignore: [], keep: [".gitkeep"]), roots: [tmp])
  let customFindings = pCustom.evaluate(result: emptyResult)
  #expect(customFindings.count == 1)
}
