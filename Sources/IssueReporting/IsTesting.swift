#if os(WASI)
  public let isTesting = false
#else
  import Foundation

  /// Whether or not the current process is running tests.
  ///
  /// You can use this information to prevent application code from running when hosting tests. For
  /// example, you can wrap your app entry point:
  ///
  /// ```swift
  /// import IssueReporting
  ///
  /// @main
  /// struct MyApp: App {
  ///   var body: some Scene {
  ///     WindowGroup {
  ///       if !isTesting {
  ///         MyRootView()
  ///       }
  ///     }
  ///   }
  /// }
  ///
  /// To detect if the current task is running inside a test, use ``TestContext/current``, instead.
  public let isTesting = ProcessInfo.processInfo.isTesting

  extension ProcessInfo {
    fileprivate var isTesting: Bool {
      #if os(Android)
        // Skip's Android test runner uses swift-corelibs-xctest.
        // Detect test context via process arguments or loaded XCTest symbols.
        if arguments.contains(where: {
          $0.hasSuffix("xctest") || $0.contains("XCTest") || $0 == "--testing-library"
        }) {
          return true
        }
        // Fallback: check if XCTest symbols are loaded via dlsym
        if let handle = dlopen(nil, RTLD_LAZY),
           dlsym(handle, "XCTestCase") != nil {
          return true
        }
        // Also check swift-corelibs-xctest environment variables
        if environment.keys.contains("XCTestBundlePath") { return true }
        if environment.keys.contains("XCTestConfigurationFilePath") { return true }
        return false
      #else
        if environment.keys.contains("XCTestBundlePath") { return true }
        if environment.keys.contains("XCTestBundleInjectPath") { return true }
        if environment.keys.contains("XCTestConfigurationFilePath") { return true }
        if environment.keys.contains("XCTestSessionIdentifier") { return true }

        return arguments.contains { argument in
          let path = URL(fileURLWithPath: argument)
          return path.lastPathComponent == "swiftpm-testing-helper"
            || argument == "--testing-library"
            || path.lastPathComponent == "xctest"
            || path.pathExtension == "xctest"
        }
      #endif
    }
  }
#endif
