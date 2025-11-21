# Profile Header Widget - El Visionat

## 📖 Descripció

`ProfileHeaderWidget` és el component principal del header de perfil d'usuari, dissenyat seguint el prototip de Figma d'El Visionat.

## ✨ Funcionalitats

- ✅ **Imatge per defecte** durant desenvolupament
- ✅ **Preparació per imatges d'usuari** via `image_picker`
- ✅ **Menú kebab (3 punts)** amb opcions contextuals
- ✅ **Shimmer loading** per imatges externes
- ✅ **Responsive design** (mòbil/desktop)
- ✅ **Fallback robust** si hi ha errors de càrrega

## 🎯 Ús Bàsic

```dart
import 'package:el_visionat/features/profile/widgets/profile_header_widget.dart';

// Ús mínim
ProfileHeaderWidget()

// Ús complet amb callbacks
ProfileHeaderWidget(
  imageUrl: user.profileImageUrl, // opcional
  height: 300, // opcional (per desktop)
  onEditProfile: () => _handleEditProfile(),
  onChangeVisibility: () => _handleChangeVisibility(),
  onCompareProfileEvolution: () => _handleCompareEvolution(),
)
```

## 📦 Dependències Requerides

```yaml
dependencies:
  image_picker: ^1.0.4           # Selecció d'imatges
  cached_network_image: ^3.3.0   # Cache d'imatges de xarxa
```

## 🎨 Assets Requerits

```
assets/
  images/
    profile/
      profile_header.webp  # Imatge per defecte
```

## 🔧 Configuració

### 1. Afegir a pubspec.yaml

```yaml
flutter:
  assets:
    - assets/images/profile/
```

### 2. Importar al teu widget

```dart
import 'package:el_visionat/features/profile/widgets/profile_header_widget.dart';
```

## 🎭 Opcions del Menú Kebab

| Opció | Descripció | Status |
|-------|------------|--------|
| **Editar perfil** | Modifica dades personals | 🚧 Placeholder |
| **Configuració visibilitat** | Gestió de privacitat | 🚧 Placeholder |
| **Comparar amb fa 1 any** | Evolució temporal | 🚧 Placeholder |

## 🎨 Personalització

### Altura personalitzada

```dart
ProfileHeaderWidget(
  height: 250, // mòbil
  height: 350, // desktop
)
```

### Imatge d'usuari

```dart
ProfileHeaderWidget(
  imageUrl: 'https://example.com/user-photo.jpg',
)
```

## 🔮 Funcionalitats Futures

- [ ] **Upload d'imatges** a Firebase Storage
- [ ] **Edició inline** de dades del perfil
- [ ] **Configuració avançada** de privacitat
- [ ] **Comparativa temporal** amb gràfics
- [ ] **Filtres i efectes** per les imatges

## 🐛 Solució de Problemes

### Error: Imatge no es carrega

```dart
// Verifica que l'asset existeix
assets/images/profile/profile_header.webp

// Comprova el pubspec.yaml
flutter:
  assets:
    - assets/images/profile/
```

### Error: Dependències no trobades

```bash
flutter pub get
flutter clean
flutter pub get
```

## 📱 Comportament Responsiu

| Pantalla | Altura | Características |
|----------|--------|-----------------|
| **Mòbil** | 250px | Compacte, botó kebab més gran |
| **Tablet** | 275px | Mida intermèdia |
| **Desktop** | 300px | Més espai, millor resolució |

## 🎯 Integració amb ProfilePage

```dart
class ProfilePage extends StatefulWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header principal
        ProfileHeaderWidget(
          onEditProfile: () => _navigateToEditProfile(),
          onChangeVisibility: () => _showVisibilityDialog(),
          onCompareProfileEvolution: () => _showEvolutionReport(),
        ),
        // Resta del contingut...
      ],
    );
  }
}
```

---

**🔥 El Visionat** - Profile System v1.0  
Desenvolupat seguint Feature-First Architecture