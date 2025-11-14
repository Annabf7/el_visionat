📘 flutter_guidelines.md — Estàndards Flutter

Aquesta guia estableix les normes de desenvolupament Flutter + Dart per assegurar que tot el codi segueix un estil consistent, escalable i professional.
És un document referent directe per Copilot.

1. Principis generals

UI → simple, declarativa i predictible

No lògica dins dels widgets

Tot estat global es gestiona amb Provider + ChangeNotifier

Cada feature és completament autocontenida

Codi optimitzat per testing, reusabilitat i mantenibilitat

2. Estructura i organització del codi

Cada feature segueix exactament aquesta estructura:

feature_name/
models/
services/
providers/
pages/
widgets/
utils/
index.dart
README.md

Regles:

UI només dins pages i widgets

Providers només per estat i gestió del flux

Services per lògica de negoci i accés a Firebase

Models sense lògica, només dades i serialització

Widgets → sempre petits i reutilitzables

3. Estil de codi Flutter
   3.1 Format

línia màxima → 100 caràcters

espais → 2

blocs: sempre amb {}

constructors llargs → multiline

3.2 Noms

Widgets → PascalCase

Fitxers → snake_case

Providers → SomethingProvider

Services → SomethingService

Models → SomethingModel

Helpers/Utils → something_utils.dart

4. Normes de Widgets
   4.1 Stateless vs Stateful

Preferir StatelessWidget

Només Stateless per UI purament declarativa

StatefulWidget només quan:

focus

animacions

controllers (scroll, text, page)

estat efímer no global

4.2 Extreure widgets

Si un widget supera 250 línies, dividir-lo en:

\_PrivateWidgetPartA

\_PrivateWidgetPartB

o moure directament a /widgets/

4.3 Reutilització

UI repetida més de 2 cops → convertir-se en widget reutilitzable.

5. Normes de Provider
   5.1 Regles estrictes

Providers no poden:

fer print de logs interns

fer crides a Firebase directament

contenir lògica de negoci pesada

Providers sí poden:

gestionar estat

exposar getters/mètodes públics

trucar a un service extern

notificar canvis

5.2 Format d’un provider
class VotingProvider extends ChangeNotifier {
final VoteService \_service;
VotingProvider(this.\_service);

bool \_isLoading = false;
bool get isLoading => \_isLoading;

Future<void> castVote(MatchSeed match) async {
\_isLoading = true;
notifyListeners();
try {
await \_service.castVote(match);
} finally {
\_isLoading = false;
notifyListeners();
}
}
}

5.3 Us correcte

Lectura: context.watch<VoteProvider>()

Acció: context.read<VoteProvider>()

6. Gestió d’errors i loading
   6.1 Loading normalitzat

Tot component que fa crides async ha de tenir:

estat de isLoading

UI de càrrega coherent amb el tema global

6.2 Errors

Mai mostrar errors tipus:

Exception: Bad request

Sempre:

Mostrar un missatge humà

Log discret (mai prints al code release)

Errors estructurats als serveis

7. Navegació

Flutter Navigation ha de seguir:

7.1 Regles

Navegació sempre via noms de rutes

File separats per route table

Mai usar Navigator.of(context) directament des de widgets profunds

7.2 Protecció de rutes
RequireAuth(child: VisionatMatchPage())

Aquesta és la manera oficial.

8. Temes i estil visual
   8.1 Colors i tema global

Tot color → a app_theme.dart

Prohibit definir colors dins del widget.

8.2 Tipografia

TextTheme definit globalment
→ widgets utilitzen context.textTheme.xxx

8.3 Responsive

Utilitzar LayoutBuilder quan cal

Evitar MediaQuery repetit

Fer servir constraints.maxWidth per condicionar disseny

9. Optimització
   9.1 Renderitzat

Fer servir const sempre que sigui possible

Evitar rebuilds innecessaris

Utilitzar Selector quan només canvia una propietat del provider

9.2 Llistes

Sempre ListView.builder

Cap ListView dins Column sense Expanded

Evitar SingleChildScrollView -> ListView duplicat

10. Bones pràctiques de tests

Testing a:

Providers (unit tests)

Services (mock Firebase)

Widgets (Golden tests)

Mai test d’integració que depengui de Firebase real
