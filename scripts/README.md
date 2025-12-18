# Scripts de manteniment - El Visionat

## Diccionari d'equips (`supercopa_teams.json`)

📁 **Font única**: `assets/data/supercopa_teams.json`

Aquest fitxer és l'única font de veritat per al diccionari d'equips de la Super Copa.
Tant Flutter com qualsevol script o servei backend han de llegir directament aquest fitxer.

### Format del JSON

```json
{
  "id": "identificador-unic",
  "name": "NOM OFICIAL FCBQ",
  "acronym": "ACR",
  "gender": "Masculina" | "Femenina",
  "colorHex": "#RRGGBB",
  "logoAssetPath": "assets/images/teams/nom-fitxer.webp" | null,
  "aliases": ["VARIANT 1", "VARIANT 2"]
}
```

### Scripts disponibles

| Comanda | Descripció |
|---------|------------|
| `npm run seed:emu` | Seed de dades al Firestore emulator |
