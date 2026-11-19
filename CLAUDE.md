# CLAUDE.md --- Car Tracker

## 1. Scopul proiectului

Acest repository conține o aplicație mobilă Android pentru înregistrarea
călătoriilor efectuate cu mașina și centralizarea statisticilor
aferente.

Aplicația trebuie să poată: - porni și opri manual o călătorie; -
colecta coordonate GPS pe durata călătoriei; - înregistra datele
inclusiv când aplicația este în background, în limitele permise de
Android; - calcula distanța, durata, viteza medie și viteza maximă; -
afișa traseul pe hartă și istoricul călătoriilor; - păstra local datele
atunci când nu există internet și sincroniza ulterior cu backend-ul.

**În această etapă se dezvoltă doar pentru Android. Nu implementa și nu
pregăti funcționalități iOS decât dacă se cere explicit ulterior.**

Cerințele beneficiarului nu sunt încă definitive. Nu presupune că
funcționalitățile opționale sunt obligatorii. Păstrează implementarea
simplă și ușor de modificat.

## 2. Tehnologii stabilite

### Mobile

-   Flutter
-   Dart
-   Android SDK
-   `geolocator` pentru accesul la locație, dacă verificarea tehnică
    confirmă că acoperă cazul de utilizare.
-   `flutter_map` și `latlong2` pentru afișarea hărții, dacă se
    păstrează varianta OpenStreetMap.
-   `dio` pentru apelurile HTTP.
-   SQLite (de exemplu `sqflite`) pentru datele locale.
-   `flutter_secure_storage` pentru tokenuri, dacă autentificarea cu
    token este implementată.

### Backend

-   Python
-   FastAPI
-   Uvicorn
-   SQLAlchemy
-   Alembic
-   PostgreSQL
-   Pydantic / pydantic-settings
-   Pytest și HTTPX pentru teste

### Alte instrumente

-   Git și GitHub
-   Postman pentru verificarea API-ului
-   DBeaver sau pgAdmin pentru inspectarea bazei de date

Nu adăuga o bibliotecă doar pentru că este populară. Verifică mai întâi
dacă funcționalitatea poate fi implementată simplu cu tehnologiile deja
folosite.

## 3. Principii obligatorii de lucru

### KISS --- Keep It Simple

-   Alege cea mai simplă soluție care îndeplinește cerința.
-   Nu introduce arhitecturi, straturi sau abstracții fără un motiv
    concret.
-   Nu crea clase, servicii, repository-uri, DTO-uri, viewmodel-uri sau
    manageri suplimentari doar pentru a respecta un tipar.
-   Nu construi un framework generic pentru o singură funcționalitate.
-   Nu anticipa funcționalități care nu au fost cerute.
-   Nu adăuga dependențe fără să explici de ce sunt necesare.
-   Evită duplicarea codului, dar nu sacrifica lizibilitatea pentru
    abstracții premature.

### Stilul codului

-   Scrie cod simplu, lizibil și potrivit unui proiect realizat de un
    student/dezvoltator aflat în proces de învățare.
-   Folosește denumiri clare și consecvente.
-   Păstrează funcțiile scurte și cu responsabilități clare.
-   Adaugă comentarii numai când explică un motiv sau o logică care nu
    este evidentă. Nu comenta fiecare linie.
-   Nu rescrie fișiere întregi dacă este suficientă o modificare mică.
-   Respectă structura și convențiile deja existente în repository.
-   Nu schimba versiuni, configurații sau dependențe fără să verifici
    impactul.

### Modul de lucru

Înainte de a modifica fișiere: 1. Inspectează structura proiectului și
codul relevant. 2. Identifică exact fișierele care trebuie modificate.
3. Verifică dacă funcționalitatea există deja parțial. 4. Explică pe
scurt planul și eventualele implicații. 5. Implementează numai cerința
solicitată.

După modificări: 1. Rulează verificările sau testele relevante. 2.
Repară erorile introduse de modificare. 3. Spune ce fișiere ai
modificat. 4. Explică ce trebuie rulat manual, dacă este cazul. 5.
Menționează clar ce nu a putut fi verificat.

Nu pretinde că o funcționalitate funcționează pe un dispozitiv real dacă
a fost verificată doar prin analiză statică sau emulator.

Dacă lipsește o informație care schimbă semnificativ implementarea,
întreabă înainte să presupui. Dacă există o variantă sigură și
reversibilă, explică presupunerea și continuă numai dacă este rezonabil.

## 4. Arhitectura proiectului

Se păstrează două aplicații separate:

-   `mobile/` --- aplicația Flutter.
-   `backend/` --- API-ul FastAPI.

Fluxul principal:

1.  Flutter colectează datele GPS.
2.  Datele sunt salvate local pe telefon.
3.  Aplicația calculează sau pregătește datele călătoriei.
4.  Flutter trimite datele către FastAPI prin HTTPS.
5.  FastAPI validează datele și le salvează în PostgreSQL.
6.  Flutter solicită istoricul și detaliile călătoriilor prin API.

Backend-ul nu trebuie să fie necesar pentru colectarea GPS în timp real.
O călătorie trebuie să poată fi înregistrată local și fără internet.

Nu trimite fiecare punct GPS printr-o cerere HTTP separată. Folosește
sincronizare în loturi (batch), cu identificatori stabili și mecanism de
retry.

## 5. Funcționalități MVP

Ordinea de importanță:

1.  Configurarea proiectelor și conexiunii Flutter--FastAPI.
2.  Proof of Concept GPS pe un telefon Android real.
3.  Pornirea și oprirea manuală a unei călătorii.
4.  Colectarea coordonatelor, timestamp-urilor, vitezei și acurateței
    GPS.
5.  Salvarea locală a călătoriei și punctelor GPS.
6.  Calcularea distanței și statisticilor de bază.
7.  Trimiterea și salvarea datelor în backend.
8.  Istoricul călătoriilor și detaliile unei călătorii.
9.  Afișarea traseului pe hartă.
10. Gestionarea lipsei internetului și sincronizarea ulterioară.
11. Autentificare și protejarea datelor fiecărui utilizator, dacă
    aplicația va avea mai mulți utilizatori.

Funcționalități precum detectarea automată a călătoriilor, mai multe
vehicule, grafice avansate, export PDF/Excel și dashboard web nu fac
parte automat din MVP. Se implementează doar după confirmarea
beneficiarului.

## 6. Reguli importante pentru GPS și tracking

-   Nu presupune că viteza GPS este întotdeauna disponibilă sau corectă.
-   Păstrează timestamp-ul fiecărui punct.
-   Păstrează acuratețea GPS și folosește-o pentru filtrarea punctelor
    slabe.
-   Verifică valorile nule, negative, duplicate și salturile geografice
    nerealiste.
-   Nu calcula distanța prin însumarea necondiționată a tuturor
    punctelor.
-   Nu transforma lipsa unui punct GPS în deplasare inventată.
-   Separă durata totală de timpul efectiv de deplasare, dacă ambele
    sunt afișate.
-   Definește clar formula vitezei medii și documenteaz-o.
-   Stabilește și documentează intervalul de colectare GPS; nu colecta
    inutil de des.
-   Testează tracking-ul cu ecranul stins și aplicația în background pe
    un dispozitiv Android real.
-   Respectă permisiunile Android pentru locație și regulile pentru
    foreground service/location service aplicabile versiunii Android
    țintă.
-   Dacă este necesară o notificare persistentă pentru foreground
    service, aceasta trebuie afișată corect.
-   Nu promite tracking garantat dacă utilizatorul forțează oprirea
    aplicației, dezactivează locația sau sistemul restricționează
    serviciul.
-   Nu implementa tracking ascuns. Utilizatorul trebuie să știe când
    înregistrarea este activă și să o poată opri.

Înainte de a alege o soluție pentru background tracking, verifică
documentația actuală a pluginului și compatibilitatea cu versiunile
Flutter/Android folosite. `geolocator` poate furniza locația, dar nu
trebuie considerat automat o soluție completă pentru toate scenariile de
background.

## 7. Date și modele

Modelele inițiale propuse sunt:

### User

-   `id`
-   `email`
-   `password_hash`
-   `created_at`

### Vehicle (opțional pentru MVP)

-   `id`
-   `user_id`
-   `name`
-   `brand` (opțional)
-   `model` (opțional)
-   `registration_number` (opțional)

### Trip

-   `id`
-   `user_id`
-   `vehicle_id` (opțional)
-   `started_at`
-   `ended_at` (nullable cât timp este activă)
-   `status`
-   `distance_meters` sau `distance_km`
-   `average_speed`
-   `max_speed`
-   `moving_duration_seconds`
-   `total_duration_seconds`
-   `created_at`
-   `updated_at`

### GPSPoint

-   `id`
-   `trip_id`
-   `latitude`
-   `longitude`
-   `speed` (nullable)
-   `accuracy` (nullable)
-   `altitude` (nullable)
-   `recorded_at`
-   `sequence_number` sau un identificator stabil pentru sincronizare

Ajustează modelele numai când cerințele confirmate justifică schimbarea.
Folosește unități consecvente și documentate. Recomandarea este să
păstrezi distanța în metri și viteza în m/s în calculele interne,
convertind pentru afișare.

## 8. Date personale și securitate

-   Solicită numai permisiunile necesare.
-   Explică utilizatorului de ce este necesară locația.
-   Înregistrarea trebuie să fie vizibilă și controlată de utilizator.
-   Nu expune datele unui utilizator altui utilizator.
-   Verifică proprietatea fiecărei călătorii în backend, nu doar în
    Flutter.
-   Nu salva parole în clar.
-   Nu include parole, tokenuri sau chei API în repository.
-   Folosește variabile de mediu pentru secrete.
-   Folosește HTTPS în producție.
-   Prevede ștergerea datelor și a contului conform cerințelor
    aplicabile.
-   Nu păstra locația mai mult decât este necesar pentru scopul
    aplicației.

## 9. API și validare

-   Folosește endpointuri REST clare și consecvente.
-   Validează datele primite cu Pydantic.
-   Verifică faptul că punctele GPS aparțin călătoriei indicate.
-   Previne trimiterea duplicată a aceluiași batch.
-   Returnează coduri HTTP și mesaje de eroare potrivite.
-   Nu expune stack trace sau informații interne în răspunsurile către
    client.
-   Documentează endpointurile prin OpenAPI/Swagger generat de FastAPI.

## 10. Testare

Testează cel puțin: - calculul distanței dintre două coordonate
cunoscute; - puncte GPS invalide și acuratețe slabă; - viteze lipsă și
valori nerealiste; - călătorie fără puncte sau cu un singur punct; -
pornire și oprire repetată; - două cereri simultane de pornire; -
sincronizare repetată fără duplicate; - accesul unui utilizator la
călătoria altuia; - pierderea internetului și retry; - recuperarea unei
călătorii după închiderea neașteptată; - tracking cu ecranul stins pe
Android real.

## 11. Ce să NU faci

-   Nu introduce microservicii.
-   Nu introduce Redis, message queues sau Kubernetes fără o cerință
    concretă.
-   Nu adăuga un dashboard web fără confirmare.
-   Nu implementa detectarea automată a deplasării înainte de MVP.
-   Nu introduce Clean Architecture completă, Bloc/Riverpod sau alte
    tipare complexe fără o nevoie reală. Riverpod poate fi folosit dacă
    simplifică efectiv starea aplicației, dar nu este obligatoriu.
-   Nu duplica logica de calcul în mai multe locuri.
-   Nu stoca doar statisticile și elimina punctele GPS dacă traseul
    trebuie afișat ulterior.
-   Nu presupune că telefonul are permanent internet sau GPS precis.
-   Nu face modificări masive și fără legătură cu tichetul curent.

## 12. Documentație și tichete

Fișierul `TICKETS.md` este lista de lucru și descrie cerințele, pașii și
criteriile de acceptare.

Când lucrezi la un tichet: 1. Identifică ID-ul tichetului. 2. Citește
descrierea și criteriile de acceptare. 3. Verifică dependențele și
tichetele deja implementate. 4. Implementează numai acel tichet. 5.
Rulează testele relevante. 6. Actualizează statusul tichetului numai
după verificare.

Dacă observi o cerință lipsă sau o contradicție, semnaleaz-o înainte de
a lua o decizie care schimbă arhitectura.

**Regula generală: păstrează proiectul simplu, funcțional, testabil și
ușor de înțeles. KISS are prioritate față de complexitatea inutilă.**
