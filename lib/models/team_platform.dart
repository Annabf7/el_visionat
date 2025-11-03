// Conditional export: use the generated/annotated Team model on native platforms,
// and the lightweight stub on web so we avoid needing code generation there.
export 'team_io.dart' if (dart.library.html) 'team_stub.dart';
