# 🗂️ Swift Directory Tools: Harmonize Your Project Files

Swift Directory Tools is a command-line tool designed to aggregate and harmonize your project's
text-based files into a single, unified "score". It's the perfect solution for developers looking
to simplify code sharing, documentation, and AI-assisted development.

## 🔑 Key Features

- 📂 **File Aggregation**: Scans directories and subdirectories for text-based files.
- 🔄 **Content Merging**: Combines contents of all found files into a single output file.
- 📝 **Source Tracking**: Preserves original file paths for easy traceability.
- 🛠 **Command-Line Interface**: Built with Swift's ArgumentParser for easy integration.
- 🔍 **Flexible Input**: Handles various text-based file types (Swift, Markdown, YAML, etc.).

## 📦 Installation

### 🛠 Swift Package Manager

Add SwiftDirectoryTools as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/swift-universal/swift-directory-tools.git", .upToNextMajor(from: "0.1.0"))
]
```

Include SwiftDirectoryTools in your target dependencies:

```swift
targets: [
    .target(name: "YourTarget", dependencies: ["SwiftDirectoryTools"]),
]
```

## 📚 Usage

To use Swift Directory Tools, simply run the following command in your terminal:

```bash
swift-directory-tools /path/to/your/project --output /path/to/output/ProjectScore.txt
```

This will generate a single `ProjectScore.txt` file containing all the text-based files from your project, each preceded by its file path.

## 💼 Why Use Swift Directory Tools?

1. 📚 **Comprehensive Code Sharing**: Easily share entire SPM packages or multiple packages in a single file.
2. 🧠 **Context Preservation**: Maintain the context of each code snippet or document with included file paths.
3. 🚀 **Efficiency**: Faster to upload and process a single file than numerous individual files.
4. 🔄 **Version Control Friendly**: Easily track changes to your entire codebase by comparing different "scores".
5. 📊 **Documentation Integration**: Include both code and documentation in a single file for a complete package overview.

## 🎨 Customization

Swift Directory Tools offers several options for customization:

- `--prefix`: Include only files whose names start with the given prefixes.
- `--allow-suffix`: Only include files whose names end with the given suffixes.
- `--ignore-suffix`: Ignore files whose names end with the given suffixes.

## 🤝 Contributing

We welcome contributions to Swift Directory Tools! Here's how you can help:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

## 📬 Contact

Your Name - [@yourtwitter](https://twitter.com/yourtwitter) - <email@example.com>

Project Link: [https://github.com/swift-universal/swift-directory-tools](https://github.com/swift-universal/swift-directory-tools)

## 💖 Acknowledgments

- Thanks to all contributors who have helped shape Swift Directory Tools.
- Inspired by the need for efficient code sharing in AI-assisted development.

---

Happy harmonizing with Swift Directory Tools! 🎵📄✨
