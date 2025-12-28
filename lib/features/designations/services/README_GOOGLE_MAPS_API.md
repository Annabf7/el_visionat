# Configuració de Google Maps Distance Matrix API

## ✅ Ja està configurat!

Aquest projecte **ja utilitza Firebase Cloud Functions** per cridar a Google Maps Distance Matrix API de forma segura. La clau API està guardada a Firebase Secrets (`GOOGLE_PLACES_API_KEY`) i s'utilitza per:

1. **Google Places Autocomplete** - Autocompletar adreces quan l'usuari escriu
2. **Google Places Details** - Obtenir components d'una adreça (carrer, CP, ciutat, etc.)
3. **Google Maps Distance Matrix** - Calcular distàncies entre adreces (NOU!)

## Activar Distance Matrix API (si no ho has fet)

Si encara no has activat la Distance Matrix API al teu projecte de Google Cloud:

1. Ves a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona el mateix projecte que utilitzes per Places API
3. Ves a "APIs & Services" > "Library"
4. Cerca "Distance Matrix API"
5. Fes clic a "Enable"

**IMPORTANT**: Utilitza la mateixa clau API que ja tens configurada per Places API. No cal crear una clau nova!

## Restriccions de l'API (recomanades)

A Google Cloud Console, configura les següents restriccions per la teva clau:

1. **Application restrictions**:
   - NO estableixis restriccions (la clau s'utilitza des de Firebase Functions)
   - Les Cloud Functions ja proporcionen seguretat mitjançant autenticació

2. **API restrictions**:
   - Limita la clau a aquestes APIs:
     - Places API (New)
     - Distance Matrix API
     - Geocoding API (opcional, per futures funcionalitats)

## Costos

- Google Maps Distance Matrix API té un cost per petició
- Els primers 200$ al mes són gratuïts (crèdit de Google Cloud)
- Consulta els preus actuals a: https://cloud.google.com/maps-platform/pricing

## Ús a l'aplicació

Quan l'usuari puja un PDF de designació:

1. El sistema obté l'adreça de casa de l'àrbitre del seu perfil (`homeAddress`)
2. Per cada partit del PDF, extreu l'adreça del pavelló (`locationAddress`)
3. Crida a `DistanceCalculatorService.calculateDistance()` que:
   - Fa una petició a Google Maps Distance Matrix API
   - Rep la distància en metres i la converteix a quilòmetres
   - Retorna 0.0 si hi ha algun error
4. Utilitza els quilòmetres calculats per:
   - Calcular el cost de quilometratge (tarifes FCBQ)
   - Determinar si apliquen dietes segons distància
   - Mostrar la informació a la designació

## Configuració de l'adreça de casa

L'usuari ha de configurar la seva adreça de casa al perfil perquè el sistema pugui calcular distàncies:

**Perfil d'usuari** → **Editar perfil** → **Adreça de casa**

Camps necessaris:
- Carrer i número
- Codi postal
- Ciutat
- Província

Exemple: `Genís i Sagrera, 9, 17200 Palafrugell, Girona`