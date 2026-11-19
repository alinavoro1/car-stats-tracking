# Decizii tehnice

Acest document fixează regulile cerute de tichete (unități, filtrare,
calcule, sincronizare) și limitele cunoscute.

## 1. Utilizatori și autentificare

- REQ-01 și AUTH-01..07 sunt încă neconfirmate. MVP-ul folosește un
  **singur utilizator implicit**, creat automat la prima călătorie
  (`local@car-tracker.local`).
- Nu există login, token sau izolare între utilizatori în această etapă.
  Modelele păstrează `user_id` pentru a permite adăugarea autentificării
  fără rescrierea schemei.
- Nu folosi această configurație pentru mai mulți utilizatori în
  producție.

## 2. Unități și formule

| Mărime | Stocare | Afișare |
|---|---|---|
| Distanță | metri (`distance_meters`) | m sub 1 km, apoi km |
| Viteză | m/s (`*_speed_mps`) | km/h |
| Durată | secunde | h/m/s |

**Distanța** este suma distanțelor Haversine dintre punctele GPS
acceptate consecutive. Formula folosește raza medie a Pământului
(6 371 000 m). Două coordonate identice au distanță zero.

**Durata totală** = `ended_at − started_at` (niciodată negativă).

**Timpul de deplasare** (STAT-04): un segment dintre două puncte
acceptate este considerat în deplasare dacă:

- diferența de timp este > 0 și ≤ 60 s;
- viteza implicită (`distanță / timp`) este ≥ 1 m/s (~3.6 km/h);
- distanța segmentului este ≥ 5 m (elimină zgomotul GPS).

Timpul de deplasare este suma duratelor segmentelor care îndeplinesc
condițiile. Întreruperile de semnal mai lungi de 60 s nu sunt
considerate nici deplasare, nici staționare.

**Staționarea estimată** este suma segmentelor acoperite de GPS care nu
sunt în deplasare. Lipsa datelor GPS nu este transformată în
staționare. Valoarea afișată în detalii este o estimare.

**Viteza medie** = `distanță / timp de deplasare`. Am ales această
definiție pentru că opririle nu scad artificial viteza de condus.
Definiția alternativă (distanță / durată totală) nu este folosită.

**Viteza maximă** = cea mai mare viteză raportată de GPS dintre punctele
acceptate. Vitezele lipsă sunt ignorate. Nu se amestecă viteza GPS cu
viteza derivată din coordonate. Dacă toate valorile lipsesc, rezultatul
este 0.

Statisticile se calculează o singură dată, la oprirea călătoriei, din
punctele salvate local; calculul este determinist și poate fi refăcut.

## 3. Colectarea GPS

- `geolocator`, `LocationAccuracy.high`, interval de 5 secunde și
  distanță minimă de 10 metri (`lib/config.dart`).
- Se păstrează pentru fiecare punct: latitudine, longitudine, timestamp
  UTC, acuratețe, viteză (dacă există) și altitudine (dacă există).
- Pe Android, fluxul rulează cu un **foreground service** și o
  notificare persistentă („Înregistrare călătorie activă”). Permisiunile
  sunt declarate în `android/app/src/main/AndroidManifest.xml`.
- Limitare cunoscută: notificarea de foreground a `geolocator` nu
  garantează actualizări dacă Android distruge activitatea. La
  redeschidere, aplicația detectează călătoria activă și îi cere
  utilizatorului să continue sau să o încheie. Nu se inventează puncte
  pentru perioada în care tracking-ul nu a rulat.
- Tracking-ul este întotdeauna vizibil și poate fi oprit din ecranul
  călătoriei active. Nu există tracking ascuns.
- Testarea pe un telefon Android real (ecran stins, background, baterie)
  nu a fost efectuată în această etapă (GPS-08, GPS-09, GPS-10).

## 4. Filtrarea punctelor (GPS-07)

Un punct este respins dacă:

- latitudinea nu este în [-90, 90] sau longitudinea în [-180, 180];
- acuratețea depășește 50 m (acuratețea lipsă este acceptată);
- viteza raportată este negativă sau peste 100 m/s (~360 km/h);
- timestamp-ul nu este după punctul anterior (duplicat / ordine greșită);
- viteza implicită față de punctul acceptat anterior depășește
  100 m/s (salt GPS nerealist).

Punctele respinse rămân în SQLite cu `is_valid = 0` pentru diagnostic,
dar nu contribuie la statistici și nu se trimit la server. Pragul de
acuratețe și celelalte praguri sunt constante în `trip_stats.dart`.

## 5. Stările călătoriei

```text
active ──Stop──▶ completed ──▶ (sync)
   │
   ├──Anulare──▶ cancelled
   └── (rezervat) interrupted
```

- `active`: are `ended_at = NULL`; o singură călătorie activă permite
  aplicația și backend-ul.
- `completed`: are `ended_at` și statistici; poate fi sincronizată.
- `cancelled`: oprită intenționat; exclusă din statistici și din
  sincronizare.
- `interrupted`: definit pentru situații viitoare; în MVP, o călătorie
  întreruptă de sistem rămâne `active` până când utilizatorul alege
  continuarea sau finalizarea.

## 6. Baza de date locală (SQLite)

`trips`:

```text
id TEXT PK, started_at TEXT (UTC ISO-8601), ended_at TEXT NULL,
status TEXT, distance_meters REAL, average_speed_mps REAL,
max_speed_mps REAL, moving_duration_seconds INTEGER,
total_duration_seconds INTEGER, sync_state TEXT, sync_error TEXT
```

`points`:

```text
id TEXT PK, trip_id TEXT FK -> trips(id) ON DELETE CASCADE,
latitude REAL, longitude REAL, speed_mps REAL NULL,
accuracy_meters REAL NULL, altitude_meters REAL NULL,
recorded_at TEXT (UTC ISO-8601), sequence_number INTEGER,
is_valid INTEGER, UNIQUE(trip_id, sequence_number)
```

Datele persistă după închiderea aplicației. O călătorie activă este
recuperată la pornire (TRIP-04, TRIP-06).

## 7. Sincronizarea (OFF-04..OFF-07)

- ID-urile călătoriei și ale punctelor sunt UUID generate pe telefon,
  deci retrimiterea nu creează duplicate.
- Ordinea cererilor: `POST /trips` → loturi de maximum 200 de puncte
  valide → `POST /trips/{id}/complete`.
- Serverul ignoră punctele deja existente (după ID) și refuză
  secvențele duplicate pentru aceeași călătorie.
- Starea de sincronizare a călătoriei: `pending`, `syncing`, `synced`,
  `failed`. O eroare păstrează datele local și afișează opțiunea de
  reîncercare.
- Sincronizarea se reia automat când revine conexiunea, la pornirea
  aplicației și manual. Erorile nu produc bucle infinite.
- Datele locale nu sunt șterse după sincronizare, ca istoricul și
  traseul să fie disponibile offline. Curățarea (OFF-08) este amânată.

## 8. API

Toate rutele sunt sub `/api/v1`:

| Metodă | Rută | Rol |
|---|---|---|
| GET | `/health` | verificare server |
| POST | `/trips` | creare idempotentă după ID |
| GET | `/trips` | listă, cele mai recente primele |
| GET | `/trips/{id}` | metadate și statistici |
| GET | `/trips/{id}/points` | punctele, ordonate după secvență |
| POST | `/trips/{id}/points/batch` | 1..500 puncte, idempotent |
| POST | `/trips/{id}/complete` | finalizare idempotentă |
| DELETE | `/trips/{id}` | ștergere cu punctele asociate |

Backend-ul validează coordonatele, viteza, dimensiunea lotului și
timestamp-urile (cu fus orar obligatoriu). Nu returnează stack trace-uri.
Documentația este generată automat la `/docs`.

## 9. Hartă

- OpenStreetMap prin `flutter_map`, fără cheie API.
- Atribuirea „OpenStreetMap contributors” este afișată pe hartă.
- Tile-urile necesită internet; dacă lipsesc, restul detaliilor
  călătoriei rămân vizibile.
- Se folosește un user agent identificabil, conform politicii OSM.

## 10. Verificări efectuate

- Backend: 12 teste API trec (SQLite pentru testele rapide). Rularea pe
  PostgreSQL este necesară pentru paritate completă.
- Mobil: `flutter analyze` fără probleme; 16 teste unitare trec;
  `flutter build apk --debug` produce APK-ul.
- **Neverificat**: rulare pe telefon Android real sau emulator,
  actualizări GPS cu ecranul stins, dialoguri de permisiuni, afișarea
  tile-urilor de hartă în aplicație, consumul de baterie, executarea
  migrațiilor pe PostgreSQL.
