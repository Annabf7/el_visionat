# 🏀 El Visionat: Aplicació Oficial per a l'Arbitratge Català

> Projecte final d'aplicació mòbil (iOS i Android) dissenyat per a la gestió, seguiment i formació d'àrbitres i auxiliars de taula, assegurant l'accés exclusiu a personal registrat a la federació.

## 🌟 Característiques Clau

- **Autenticació Segura:** Flux de registre en tres passos amb validació d'ID de llicència (Llista Mestra) i aprovació manual de correu electrònic.
- **Eficiència i Rendiment:** Arquitectura optimitzada per a la càrrega instantània de dades d'equips mitjançant Base de Dades Local (Isar).
- **Frontend Multiplataforma:** Desenvolupat amb Flutter per a una experiència d'usuari nativa a iOS i Android.

---

## 🛠️ Pila Tecnològica (Tech Stack)

Aquest projecte es construeix sobre una arquitectura robusta de Flutter/Firebase:

- **Frontend:** **Flutter** (Dart)
- **Gestió d'Estat:** **Provider** (`ChangeNotifier`)
- **Backend:** **Google Firebase** (Pla Blaze)
- **Serveis Backend:**
  - **Firestore:** Base de dades principal (Data Mestra, Perfils d'Usuari).
  - **Firebase Auth:** Gestió d'usuaris.
  - **Cloud Functions:** Lògica de negoci i verificació (Node 20, TypeScript).
  - **Firebase Storage:** Emmagatzematge eficient de dades binàries (Logotips).
- **Persistència Local:** **Isar Database** (Caché NoSQL d'alt rendiment per a dades estàtiques).

---

## 🚀 Instal·lació i Entorn de Desenvolupament

Per començar a treballar en el projecte, necessiteu tenir instal·lats Flutter, Node.js i Firebase CLI.

### 1. Configuració de Dependències (Flutter & Node)

Executeu aquestes comandes a la carpeta arrel del projecte i dins del directori `functions/`:

```bash
# Instal·lar dependències de Flutter
flutter pub get

# Instal·lar dependències de Node.js (per a Cloud Functions)
cd functions/
npm install
cd ..
```
