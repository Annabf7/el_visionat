# 📸 INSTRUCCIONS IMATGE PLACEHOLDER

## Ubicació Required:

```
assets/images/profile/profile_header.webp
```

## Especificacions:

- **Format:** WebP (recomanat) o PNG/JPG
- **Dimensions:** 1200x400px (ratio 3:1)
- **Mida:** <500KB optimitzat
- **Contingut:** Foto d'àrbitre com la de la captura de Figma

## Opcions Temporals per Testing:

### 1. Descarregar de la captura

Pots extreure la imatge de l'àrbitre de la captura de Figma que m'has passat i desar-la com `profile_header.webp`

### 2. Imatge placeholder online

```dart
// Al ProfileHeaderWidget, pots substituir temporalment:
Image.asset('assets/images/profile/profile_header.webp')
// per:
Image.network('https://via.placeholder.com/1200x400/E8E8E8/666666?text=PROFILE+HEADER')
```

### 3. Convertir a WebP

```bash
# Si tens una imatge PNG/JPG
cwebp input.jpg -o profile_header.webp -q 80
```

## Testing sense Imatge:

El widget té fallback automàtic si no troba la imatge:

- Mostra gradient amb icona de bàsquet
- Text "El teu perfil d'àrbitre"
- Funciona perfectament mentre afegeixes la imatge real
