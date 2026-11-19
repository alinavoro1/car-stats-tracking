# Decizii tehnice

Acest document fixează regulile cerute de tichete (unități, filtrare,
calcule, sincronizare) și limitele cunoscute.

## 1. Utilizatori, roluri și autentificare

- Aplicația este multi-user, cu înregistrare liberă din aplicație.
- Rolurile sunt `user` și `admin`, stocate în `users.role` și validate
  printr-o constrângere în baza de date.
- **Primul cont real** (cu parolă) creat devine automat `admin`.
  Utilizatorii vechi fără parolă, rămași din etapa single-user, nu sunt
  luați în calcul. Conturile următoare primesc rolul `user`.
- Parolele sunt hash-uite cu bcrypt; nu sunt stocate sau returnate în
  clar.
- Autentificarea folosește JWT semnat cu `SECRET_KEY` din `.env` și
  expiră după `ACCESS_TOKEN_EXPIRE_MINUTES` (implicit 60).
- Tokenul este păstrat în `flutter_secure_storage`, nu în preferințe
  obișnuite. La pornire, aplicația îl validează prin `/auth/me`; dacă nu
  există internet, folosește datele cache-uite ale contului.
- Fiecare utilizator vede doar propriile călătorii. Adminul vede
  propriile călătorii ca orice utilizator și are o pagină separată cu
  toate călătoriile.
- La logout tokenul este șters, tracking-ul este oprit dacă rulează, iar
  datele locale nesincronizate rămân pe dispozitiv.
- Călătoriile locale create înainte de autentificare sunt atribuite
  primului cont care se autentifică pe dispozitiv.

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
id TEXT PK, started_at TEXT (UTC ISO-8601), owner_email TEXT,
ended_at TEXT NULL, status TEXT, distance_meters REAL,
average_speed_mps REAL, max_speed_mps REAL,
moving_duration_seconds INTEGER, total_duration_seconds INTEGER,
sync_state TEXT, sync_error TEXT
```

Interogările locale filtrează după `owner_email`, astfel încât mai multe
conturi de pe același dispozitiv să nu-și vadă reciproc călătoriile.

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

- Cererile private trimit `Authorization: Bearer <token>`; un token
  lipsă, invalid sau expirat produce `401`.
- ID-urile călătoriei și ale punctelor sunt UUID generate pe telefon,
  deci retrimiterea nu creează duplicate.
- Serverul asociază călătoria cu utilizatorul din token, nu cu un
  `user_id` trimis de client.
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
| GET | `/health` | verificare server (public) |
| POST | `/auth/register` | creare cont (public) |
| POST | `/auth/login` | token JWT (public) |
| GET | `/auth/me` | contul curent |
| POST | `/trips` | creare idempotentă după ID, pentru utilizatorul curent |
| GET | `/trips` | doar călătoriile utilizatorului curent |
| GET | `/trips/{id}` | metadate și statistici (doar proprietarul) |
| GET | `/trips/{id}/points` | punctele (doar proprietarul) |
| POST | `/trips/{id}/points/batch` | 1..500 puncte, idempotent |
| POST | `/trips/{id}/complete` | finalizare idempotentă |
| DELETE | `/trips/{id}` | ștergere cu punctele asociate |
| GET | `/admin/trips` | toate călătoriile, doar pentru `admin` |
| GET | `/admin/trips/{id}/points` | punctele oricărei călătorii, doar `admin` |

Un utilizator normal primește `403` pe rutele `/admin/*`. Accesul la o
călătorie a altui utilizator prin rutele normale returnează `404`.

Backend-ul validează coordonatele, viteza, dimensiunea lotului și
timestamp-urile (cu fus orar obligatoriu). Nu returnează stack trace-uri.
Documentația este generată automat la `/docs`.

## 9. Hartă

- OpenStreetMap prin `flutter_map`, fără cheie API.
- Atribuirea „OpenStreetMap contributors” este afișată pe hartă.
- Tile-urile necesită internet; dacă lipsesc, restul detaliilor
  călătoriei rămân vizibile.
- Se folosește un user agent identificabil, conform politicii OSM.
- În timpul călătoriei active, harta live afișează traseul punctelor
  valide, poziția curentă, markerul de start și un buton de centrare.
  Harta se actualizează doar când sosesc puncte noi; cronometrul are
  propriul ciclu de reconstrucție.
- În detaliile unei călătorii finalizate, startul și sosirea sunt
  marcate distinct, folosind primul și ultimul punct valid.
- Ecranul Cont afișează starea permisiunilor de locație și notificări
  și oferă acces la setările aplicației.

## 10. Dezvoltare și hot reload

- Fiecare tichet se lucrează pe un branch separat și se merge în `main`
  numai după ce testele relevante trec.
- Pentru testarea pe tabletă prin USB, backend-ul rulează pe un port
  liber (în mediul curent 8010) și se folosește:
  `adb reverse tcp:8010 tcp:8010`.
- `scripts/dev_hot_reload.ps1` pornește `flutter run` în fundal și
  citește comenzi din `mobile/car_tracker_app/.hot_reload_cmd`
  (`reload`, `restart`, `quit`). Modificările structurale de arbore de
  widget-uri necesită `restart`, nu doar `reload`.

## 11. Verificări efectuate

- Backend: 49 teste trec pe SQLite și pe PostgreSQL, inclusiv
  înregistrare, login, roluri, izolare între utilizatori, token expirat
  și endpointurile de admin.
- Mobil: `flutter analyze` fără probleme; 40 teste unitare trec;
  `flutter build apk --debug` produce APK-ul.
- Pe tabletă: ecranul de login, permisiunea de locație, tracking-ul,
  notificarea persistentă, baza SQLite locală și detaliile cu hartă au
  fost verificate.
- Harta live, marker-ele de start/poziție curentă și cardul de
  permisiuni au fost implementate și trec analiza statică/testele, dar
  nu au fost încă verificate vizual pe dispozitiv.
- **Neverificat**: înregistrarea și navigarea în pagina de admin pe
  tabletă, tracking cu ecranul stins în mișcare, comportamentul offline,
  recuperarea după oprirea forțată, consumul de baterie, comportamentul
  pe alte versiuni Android.
