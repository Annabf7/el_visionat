import 'package:google_sign_in/google_sign_in.dart';

void main() {
  final ensureConstructorExists = GoogleSignIn(scopes: ['email']);
  print('GoogleSignIn instantiated: $ensureConstructorExists');
}
