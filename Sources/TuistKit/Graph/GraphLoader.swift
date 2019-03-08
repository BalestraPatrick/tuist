import Basic
import Foundation
import TuistCore

protocol GraphLoading: AnyObject {
    func loadProject(path: AbsolutePath) throws -> Graph
    func loadWorkspace(path: AbsolutePath) throws -> (Workspace, Graph)
}

class GraphLoader: GraphLoading {
    // MARK: - Attributes

    let linter: GraphLinting
    let printer: Printing
    let fileHandler: FileHandling
    let modelLoader: GeneratorModelLoading

    // MARK: - Init

    init(linter: GraphLinting = GraphLinter(),
         printer: Printing = Printer(),
         fileHandler: FileHandling = FileHandler(),
         modelLoader: GeneratorModelLoading) {
        self.linter = linter
        self.printer = printer
        self.fileHandler = fileHandler
        self.modelLoader = modelLoader
    }

    func loadProject(path: AbsolutePath) throws -> Graph {
        let cache = GraphLoaderCache()
        let circularDetector = GraphCircularDetector()
        let project = try Project.at(path, cache: cache, circularDetector: circularDetector, modelLoader: modelLoader)
        let entryNodes: [GraphNode] = try project.targets.map({ $0.name }).map { targetName in
            try TargetNode.read(name: targetName, path: path, cache: cache, circularDetector: circularDetector, modelLoader: modelLoader)
        }
        let graph = Graph(name: project.name,
                          entryPath: path,
                          cache: cache,
                          entryNodes: entryNodes)
        try lint(graph: graph)
        return graph
    }

    func loadWorkspace(path: AbsolutePath) throws -> (Workspace, Graph) {
        let cache = GraphLoaderCache()
        let circularDetector = GraphCircularDetector()
        let workspace = try modelLoader.loadWorkspace(at: path)

        func traverseProjects(element: Workspace.Element) throws -> [(AbsolutePath, Project)] {
            switch element {
            case .file(path: _):
                break
            case .group(name: _, contents: let contents):
                return try contents.flatMap(traverseProjects)
            case let .project(path: path):
                return [try (path, Project.at(path, cache: cache, circularDetector: circularDetector, modelLoader: modelLoader))]
            }

            return []
        }

        let projects = try workspace.elements.flatMap(traverseProjects)

        let entryNodes = try projects.flatMap { (project) -> [TargetNode] in
            try project.1.targets.map({ $0.name }).map { targetName in
                try TargetNode.read(name: targetName, path: project.0, cache: cache, circularDetector: circularDetector, modelLoader: modelLoader)
            }
        }
        let graph = Graph(name: workspace.name,
                          entryPath: path,
                          cache: cache,
                          entryNodes: entryNodes)

        try lint(graph: graph)

        return (workspace, graph)
    }

    private func lint(graph: Graph) throws {
        try linter.lint(graph: graph).printAndThrowIfNeeded(printer: printer)
    }
}
