import '../source/source.dart';
import '../error/error.dart';
import 'ast.dart' show AstNode, ImportDecl;

/// Contains the resolved fullname of a import statement
class ImportInfo {
  final String fullName;

  final String? alias;

  final List<String>? showList;

  ImportInfo(this.fullName, [this.alias, this.showList]);

  ImportInfo.fromAst(ImportDecl stmt, String fullName)
      : this(fullName, stmt.alias, stmt.showList);
}

/// The parse result of a single file
class HTAstModule {
  final HTSource source;

  String get fullName => source.fullName;

  SourceType get type => source.type;

  final String libraryName;

  final bool isLibraryEntry;

  /// The bytecode, stores as uint8 list
  final List<AstNode> nodes;

  final List<ImportDecl> imports;

  final List<HTError> errors;

  HTAstModule(this.source, this.nodes, this.libraryName,
      {this.isLibraryEntry = false,
      this.imports = const [],
      this.errors = const []});
}
