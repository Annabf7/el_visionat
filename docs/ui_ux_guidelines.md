📘 ui_ux_guidelines.md — Estàndards UI/UX del Projecte

Aquest document defineix tots els patrons de disseny, regles visuals, normes de UX i estàndards de components Flutter utilitzats a EL VISIONAT.

És un document essencial perquè Copilot generi UI coherent, professional i consistent.

1. Principis de Disseny
   1.1 Identitat Visual del Projecte

Colors corporatius definits a AppTheme:

Púrpura fosc (porpraFosc)

Lila mitjà (lilaMitja)

Mostassa (mostassa)

Gris suau (per superfícies)

Blanc pur (per neteja visual)

1.2 Estil general

UI moderna, netejada, zero soroll

Cards amb cantonades suaus (radius 16)

Ombres subtils (BlurRadius 12 · SpreadRadius 1)

Icons i tipografia Material 3

Espais consistents (16 / 24 / 32 px)

Jerarquia visual clara

1.3 Principis UX

Tot text ha de ser clar, curt i informatiu

“Una acció = un objectiu”

Feedback sempre immediat:

Loading indicators

Snackbars de confirmació

Errors humans i empàtics

Navegació consistent

Evitar pantalles sobrecarregades

2. Layout i Responsiveness
   2.1 Mòbil

Layout una columna

Cards full-width

Text mida 14–16px

Botons sempre min 48px d’alçada

BottomSheet per modalitat temporal

2.2 Tablet

Doble columna quan hi ha espai

Cards fins a 480px d’amplada

2.3 Desktop

Layout professional 2 o 3 columnes

Àrees definides:

Barra lateral fixada (navigation)

Contingut principal centrada

Sidebar opcional (analítica, stats)

Breakpoints recomanats
< 600px → Mobile
600–1024px → Tablet
1024–1600px → Desktop

> 1600px → Large Desktop (max width 1200–1400px)

3. Components Reutilitzables

Aquests són els components oficials:

3.1 Cards

Patró:

Card(
elevation: 3,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
child: Padding(
padding: const EdgeInsets.all(16),
child: ...
),
)

Regles:

No més de 3 nivells de nesting

Cap card sense padding intern

Colors sempre del AppTheme

3.2 Botons
Primari

Color: porpraFosc o mostassa

Text en blanc

Radius 12

Secundari

Contorn (OutlineButton)

Color primari al border

Danger

Vermell Material 3 (Colors.red.shade700)

Usar només per accions destructives

3.3 Tipografia

Material 3, amb modificacions:

Títols grans: 22–26px, pes medium

Subtítols: 16–18px

Body text: 14–16px

Notes secundàries: 12–13px gris suau

4. Interaccions i Animacions
   4.1 Microinteraccions

Usuari ha de notar que alguna cosa passa:

Hover animations (desktop)

Tap splash efecte discret (mòbil)

Icones que animen lleugerament amb AnimatedOpacity o AnimatedScale

4.2 Duracions recomanades

Microanimacions UI: 120–180ms

Apertura modals: 250ms

Transicions de pàgina: 300ms

5. Modals i BottomSheets
   Modal Full-screen (desktop)

Ús:

Formularis llargs

Analítica

Comentaris col·lectius (actual)

Modal 80% screen (tablet)
BottomSheet modal (mòbil)

Ús:

Accions ràpides

Confirmacions

Regles:

Mai més de 1 modal obert

Títol curt

Botó de tancar sempre a dalt a la dreta

6. Gestió d’Errors i Feedback
   Correcte

✔️ Missatges clars
✔️ Sense argot tècnic
✔️ Solució suggerida

Exemple:

“No hem pogut carregar els comentaris. Reintenta o comprova la connexió.”

Incorrecte

❌ “FirebaseError: permission-denied”
❌ “Unexpected null value”

7. Accessibilitat

Contrastos WCAG AA

Botons mínim de 48px

Fonts mínim 14px

Touch targets ben separats

Lectura per TalkBack compatible

8. Estàndards de Fotografia i Vídeo
   Per la secció Visionat:

Vídeo sempre centrado

Aspect ratio 16:9

Controls propis Flutter o integrats

Per avatars:

32–40px

Rodons (radius 40)

9. Estàndards Especials del Projecte
   9.1 TagSelector

Categoria amb icona

Tags amb secció clara

Cerca sempre disponible

Tags = polletes amb feedback visual

9.2 Timeline de Highlights

Estructura vertical

Hora destacada

Tag visual

Text descriptiu curt i clar

9.3 Secció d’Anàlisi

Un sol card amb 2 seccions:

Anàlisi personal

Anàlisi col·lectiva

Divider suau

Colors diferents per separar rols
