import Basic
import Foundation
import Utility

/// Command that outputs the version of the tool.
public class VersionCommand: NSObject, Command {

    // MARK: - Command

    /// Command name.
    public static let command = "version"

    /// Command description.
    public static let overview = "Outputs the current version of xpm."

    /// Context
    let context: CommandsContexting

    /// Version fetcher.
    let version: () -> String

    /// Initializes the command with the argument parser.
    ///
    /// - Parameter parser: argument parser.
    public required init(parser: ArgumentParser) {
        parser.add(subparser: VersionCommand.command, overview: VersionCommand.overview)
        context = CommandsContext()
        version = VersionCommand.currentVersion
    }

    /// Initializes the command with the context.
    ///
    /// - Parameter context: command context.
    /// - Parameter version: version fetcher.
    init(context: CommandsContexting,
         version: @escaping () -> String) {
        self.context = context
        self.version = version
    }

    /// Runs the command.
    ///
    /// - Parameter arguments: input arguments.
    /// - Throws: throws an error if the execution fails.
    public func run(with _: ArgumentParser.Result) {
        context.printer.print(version())
    }

    /// Returns the current application version.
    ///
    /// - Returns: current application version.
    static func currentVersion() -> String {
        guard let appPath = try? ResourceLocator().appPath() else { return "" }
        guard let appBundle = Bundle(path: appPath.asString) else { return "" }
        let info = appBundle.infoDictionary ?? [:]
        return (info["CFBundleShortVersionString"] as? String) ?? ""
    }
}
