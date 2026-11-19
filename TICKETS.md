# Car Tracker --- Backlog detaliat de implementare

**Status:** Backlog inițial --- cerințele beneficiarului trebuie
confirmate\
**Platformă în această etapă:** Android\
**Stack:** Flutter + FastAPI + PostgreSQL\
**Principiu:** KISS --- implementare incrementală, fără complexitate
prematură.

------------------------------------------------------------------------

## Cum se folosește acest backlog

-   Fiecare tichet are un ID unic.
-   Nu începe toate tichetele simultan. Respectă ordinea și
    dependențele.
-   Un tichet este Done numai când criteriile de acceptare sunt
    îndeplinite.
-   Dacă o cerință depinde de răspunsul beneficiarului, tichetul este
    marcat **Blocked / Needs clarification**.
-   Tichetele opționale nu intră automat în MVP.
-   Pentru fiecare tichet, păstrează modificările mici și rulează
    verificările relevante.

### Priorități

-   **P0:** blocant pentru MVP.
-   **P1:** important pentru MVP.
-   **P2:** îmbunătățire după funcționalitatea de bază.
-   **P3:** opțional / numai dacă este confirmat.

### Statusuri

`Todo` · `In Progress` · `Blocked` · `Done`

------------------------------------------------------------------------

# EPIC 0 --- Clarificarea cerințelor și definirea MVP-ului

## REQ-01 --- Confirmarea utilizatorilor aplicației

**Prioritate:** P0 · **Status:** Done

**Descriere:** Cerință confirmată: aplicația este multi-utilizator, cu
înregistrare liberă din aplicație.

**Decizii confirmate:** - Fiecare utilizator vede doar propriile
călătorii. - Există rolurile `user` și `admin`. - Primul cont
înregistrat primește automat rolul `admin`. - Adminul vede propriile
călătorii ca un utilizator normal și are o pagină separată cu toate
călătoriile, etichetate cu proprietarul. - Nu este necesar un panou web
în această etapă.

**Criterii de acceptare:** - Tipurile de utilizatori și rolurile sunt
documentate. - Regulile de acces la date sunt stabilite. - Izolarea
datelor este verificată în backend, nu doar în aplicație.

## REQ-02 --- Confirmarea platformei

**Prioritate:** P0 · **Status:** Done pentru etapa curentă

**Descriere:** Prima versiune se dezvoltă și se testează pentru Android.
iOS este în afara scopului curent.

**Criterii de acceptare:** - Configurația și testele inițiale vizează
Android. - Nu se introduce muncă specifică iOS în backlog-ul curent.

## REQ-03 --- Stabilirea modului de pornire a călătoriei

**Prioritate:** P0 · **Status:** Blocked

**Descriere:** Confirmă dacă utilizatorul pornește/oprește manual
călătoria sau dacă aceasta trebuie detectată automat.

**MVP propus:** butoane Start Trip și Stop Trip.

**Criterii de acceptare:** - Modul de pornire este confirmat. -
Detectarea automată nu este implementată fără cerință explicită.

## REQ-04 --- Confirmarea statisticilor necesare

**Prioritate:** P0 · **Status:** Blocked

**De confirmat:** - Distanță totală. - Durată totală. - Durată efectivă
de deplasare. - Viteză medie. - Viteză maximă. - Timp de staționare. -
Alte valori solicitate de beneficiar.

**Criterii de acceptare:** - Fiecare statistică are o definiție clară și
o unitate. - Este stabilit dacă viteza medie folosește durata totală sau
doar timpul în mișcare.

## REQ-05 --- Confirmarea hărții și a istoricului

**Prioritate:** P1 · **Status:** Blocked

**De clarificat:** - Este necesară afișarea traseului pe hartă? - Este
necesară păstrarea punctelor GPS pentru fiecare călătorie? - Cât timp se
păstrează istoricul? - Sunt necesare filtre după zi/lună?

## REQ-06 --- Confirmarea vehiculelor

**Prioritate:** P2 · **Status:** Blocked

**De clarificat:** - Există una sau mai multe mașini? - Trebuie memorate
marca, modelul și numărul de înmatriculare? - Trebuie asociată fiecare
călătorie cu o mașină?

## REQ-07 --- Confirmarea exportului și rapoartelor

**Prioritate:** P2 · **Status:** Blocked

**De clarificat:** PDF, CSV, Excel, rapoarte lunare sau doar vizualizare
în aplicație.

## REQ-08 --- Confirmarea politicii de date

**Prioritate:** P0 · **Status:** Todo

**De clarificat:** - Cine poate vedea traseele? - Cât timp se păstrează
coordonatele? - Cum poate utilizatorul șterge o călătorie sau contul? -
Este necesară exportarea datelor?

------------------------------------------------------------------------

# EPIC 1 --- Setup și structură proiect

## SET-01 --- Crearea repository-ului

**Prioritate:** P0 · **Status:** Done

**Descriere:** Creează repository-ul Git pentru proiect.

**Pași:** 1. Creează repository-ul. 2. Adaugă `.gitignore` pentru
Flutter, Python și IDE. 3. Adaugă `README.md`. 4. Creează branch-ul
principal. 5. Fă primul commit.

**Criterii de acceptare:** - Repository-ul există. - Fișierele generate
automat și secretele nu sunt versionate. - README conține scopul
proiectului și tehnologiile.

## SET-02 --- Crearea structurii frontend/backend

**Prioritate:** P0 · **Status:** Done

**Structură propusă:**

``` text
car-tracker/
├── mobile/
│   └── car_tracker_app/
├── backend/
├── documentation/
├── CLAUDE.md
├── TICKETS.md
└── README.md
```

**Criterii de acceptare:** - Frontend și backend sunt separate. -
Fiecare poate fi pornit independent. - Documentația este în repository.

## SET-03 --- Crearea proiectului Flutter

**Prioritate:** P0 · **Status:** Done

**Pași:** 1. Creează proiectul Flutter în `mobile/car_tracker_app`. 2.
Verifică `flutter doctor`. 3. Configurează Android SDK. 4. Rulează
aplicația pe emulator sau dispozitiv Android. 5. Verifică structura
inițială.

**Criterii de acceptare:** - `flutter run` pornește aplicația. - Nu
există erori de configurare. - Proiectul este versionat.

## SET-04 --- Inițializarea backend-ului FastAPI

**Prioritate:** P0 · **Status:** Done

**Pași:** 1. Creează mediul virtual Python. 2. Instalează FastAPI și
Uvicorn. 3. Creează entry point-ul aplicației. 4. Adaugă un endpoint
simplu de health check. 5. Pornește serverul local.

**Criterii de acceptare:** - Serverul pornește fără erori. - Endpoint-ul
de health check returnează un răspuns valid. - Documentația Swagger este
disponibilă.

## SET-05 --- Configurarea dependențelor backend

**Prioritate:** P0 · **Status:** Done

**Descriere:** Adaugă doar bibliotecile necesare: SQLAlchemy, Alembic,
driver PostgreSQL, Pydantic Settings, Pytest și HTTPX când sunt
necesare.

**Criterii de acceptare:** - Dependențele sunt documentate și
reproductibile. - Există un fișier de dependențe (`requirements.txt` sau
`pyproject.toml`). - Nu sunt instalate pachete fără scop.

## SET-06 --- Configurarea variabilelor de mediu

**Prioritate:** P0 · **Status:** Done

**Variabile inițiale propuse:** - `DATABASE_URL` - `SECRET_KEY` (când se
implementează autentificarea) - `ACCESS_TOKEN_EXPIRE_MINUTES` (când se
implementează autentificarea)

**Criterii de acceptare:** - Configurația locală este separată de cod. -
Fișierul `.env` nu este comis în Git. - Există `.env.example` fără
secrete reale.

## SET-07 --- Conectarea Flutter la FastAPI

**Prioritate:** P0 · **Status:** Done

**Pași:** 1. Configurează clientul HTTP în Flutter. 2. Adaugă un
endpoint de test în backend. 3. Apelează endpoint-ul din aplicație. 4.
Gestionează răspunsul și erorile de conexiune. 5. Verifică adresa
corectă pentru emulator/dispozitiv fizic.

**Criterii de acceptare:** - Flutter primește răspunsul backend-ului. -
Erorile de conexiune sunt afișate controlat. - URL-ul backend-ului nu
este duplicat în mai multe fișiere.

------------------------------------------------------------------------

# EPIC 2 --- Proof of Concept GPS (prioritate tehnică maximă)

> Acest epic trebuie realizat înainte de dezvoltarea extensivă a
> interfeței. Scopul este să verifici că telefonul poate colecta date
> GPS suficient de fiabil pentru proiect.

## GPS-01 --- Verificarea disponibilității serviciului de localizare

**Prioritate:** P0 · **Status:** In Progress

**Descriere:** Verifică dacă serviciile de localizare ale telefonului
sunt activate.

**Criterii de acceptare:** - Aplicația detectează GPS dezactivat. -
Utilizatorul primește un mesaj clar. - Tracking-ul nu pornește ca și cum
locația ar funcționa.

## GPS-02 --- Solicitarea permisiunii de localizare

**Prioritate:** P0 · **Status:** In Progress

**Descriere:** Solicită permisiunea de localizare numai când
utilizatorul încearcă să folosească tracking-ul.

**De verificat:** - Permisiune refuzată. - Permisiune refuzată
permanent. - Permisiune acordată doar în timpul utilizării. -
Permisiunea suplimentară necesară pentru background, conform versiunii
Android.

**Criterii de acceptare:** - Aplicația explică de ce are nevoie de
locație. - Nu pornește tracking-ul fără permisiunile necesare. - Oferă
utilizatorului instrucțiuni când trebuie să modifice setările.

## GPS-03 --- Obținerea poziției curente

**Prioritate:** P0 · **Status:** In Progress

**Date urmărite:** - Latitudine. - Longitudine. - Timestamp. -
Acuratețe. - Viteză, dacă este disponibilă. - Altitudine, opțional.

**Criterii de acceptare:** - Aplicația poate obține o poziție validă. -
Valorile sunt afișate temporar pentru verificare. - Erorile GPS sunt
tratate.

## GPS-04 --- Obținerea fluxului de poziții GPS

**Prioritate:** P0 · **Status:** In Progress

**Descriere:** Ascultă actualizările de locație pe durata unei sesiuni
de tracking.

**Criterii de acceptare:** - Sunt recepționate mai multe poziții. -
Fiecare poziție are timestamp. - Fluxul poate fi oprit. - Nu sunt create
mai multe subscription-uri accidental.

## GPS-05 --- Înregistrarea vitezei GPS

**Prioritate:** P0 · **Status:** Done

**Descriere:** Citește viteza furnizată de sistemul de localizare și
gestionează cazurile în care aceasta lipsește.

**Criterii de acceptare:** - Viteza este păstrată cu unitate clară. -
Valorile lipsă nu sunt transformate automat în valori valide. -
Conversia în km/h este corectă.

## GPS-06 --- Stabilirea intervalului de colectare

**Prioritate:** P0 · **Status:** In Progress

**Descriere:** Alege un interval/distanță de actualizare potrivit pentru
o călătorie cu mașina.

**Criterii de acceptare:** - Configurația este documentată. - Nu se
colectează inutil de des. - Se poate modifica fără rescrierea logicii. -
Se testează efectul asupra traseului și bateriei.

## GPS-07 --- Filtrarea punctelor GPS

**Prioritate:** P0 · **Status:** Done

**Descriere:** Identifică punctele care nu ar trebui folosite la
calculul distanței.

**Cazuri:** - Acuratețe peste pragul acceptat. - Coordonate în afara
limitelor geografice. - Timestamp lipsă sau invalid. - Punct duplicat. -
Salt nerealist față de punctul anterior. - Viteză evident imposibilă.

**Criterii de acceptare:** - Regulile de filtrare sunt documentate. -
Punctele originale pot fi păstrate separat dacă este necesar pentru
diagnostic. - Filtrarea nu elimină arbitrar puncte valide.

## GPS-08 --- Testarea GPS pe telefon Android real

**Prioritate:** P0 · **Status:** Todo

**Pași:** 1. Pornește aplicația. 2. Colectează coordonate în timpul unei
deplasări. 3. Compară traseul cu deplasarea reală. 4. Verifică
timestamp-urile și vitezele. 5. Repetă testul în condiții diferite.

**Criterii de acceptare:** - Sunt colectate puncte pe durata
deplasării. - Valorile sunt plauzibile. - Problemele observate sunt
documentate.

## GPS-09 --- Testarea ecranului stins și a aplicației în background

**Prioritate:** P0 · **Status:** Todo

**Descriere:** Verifică dacă actualizările GPS continuă când
utilizatorul stinge ecranul sau trece în altă aplicație.

**Criterii de acceptare:** - Este documentat comportamentul pe
dispozitivul testat. - Sunt respectate cerințele Android pentru
foreground service și permisiuni. - Dacă este necesară notificare
persistentă, aceasta este afișată. - Limitările sistemului sunt
documentate.

## GPS-10 --- Alegerea soluției finale pentru background tracking

**Prioritate:** P0 · **Status:** In Progress

**Descriere:** După testul inițial, decide dacă soluția bazată pe
pluginul GPS este suficientă sau dacă este necesar un plugin/serviciu
dedicat.

**Criterii de acceptare:** - Compatibilitatea cu Flutter și Android este
verificată. - Sunt cunoscute permisiunile necesare. - Sunt cunoscute
limitările și eventualele costuri/licențe. - Decizia este documentată
înainte de implementarea completă.

------------------------------------------------------------------------

# EPIC 3 --- Baza de date și modelele backend

## DB-01 --- Configurarea PostgreSQL

**Prioritate:** P0 · **Status:** Done

**Pași:** 1. Creează baza de date locală. 2. Creează utilizatorul bazei
de date. 3. Configurează conexiunea în backend. 4. Testează conectarea.

**Criterii de acceptare:** - Backend-ul se conectează la baza de date. -
Credențialele nu sunt în cod.

## DB-02 --- Configurarea SQLAlchemy

**Prioritate:** P0 · **Status:** Done

**Descriere:** Configurează engine-ul, sesiunea și baza declarativă
SQLAlchemy.

**Criterii de acceptare:** - Backend-ul poate crea o sesiune DB. -
Sesiunile sunt închise corect. - Configurația nu este duplicată.

## DB-03 --- Modelul User

**Prioritate:** P1 · **Status:** Done

**Câmpuri propuse:** id, email, password_hash, created_at.

**Criterii de acceptare:** - Email-ul are constrângere de unicitate dacă
se folosește autentificare. - Parola nu este stocată în clar. - Modelul
are cheie primară.

## DB-04 --- Modelul Vehicle

**Prioritate:** P2 · **Status:** Blocked --- confirmarea beneficiarului

**Câmpuri propuse:** id, user_id, name, brand, model,
registration_number.

**Criterii de acceptare:** - Relația cu utilizatorul este definită. -
Câmpurile opționale pot lipsi. - Nu se implementează dacă aplicația
folosește o singură mașină fixă și beneficiarul nu solicită
administrarea vehiculelor.

## DB-05 --- Modelul Trip

**Prioritate:** P0 · **Status:** Done

**Câmpuri propuse:** - id - user_id - vehicle_id (nullable/opțional) -
started_at - ended_at (nullable) - status - distance_meters -
average_speed - max_speed - moving_duration_seconds -
total_duration_seconds - created_at - updated_at

**Criterii de acceptare:** - O călătorie are proprietar. - O călătorie
activă nu are `ended_at`. - Statusurile sunt definite și validate. -
Unitățile sunt documentate.

## DB-06 --- Modelul GPSPoint

**Prioritate:** P0 · **Status:** Done

**Câmpuri propuse:** - id - trip_id - latitude - longitude - speed
(nullable) - accuracy (nullable) - altitude (nullable) - recorded_at -
identificator/sequence pentru sincronizare

**Criterii de acceptare:** - Fiecare punct aparține unei călătorii. -
Coordonatele sunt validate. - Timestamp-ul este păstrat. - Există o
metodă de identificare a punctelor duplicate la sincronizare.

## DB-07 --- Relațiile dintre modele

**Prioritate:** P0 · **Status:** Done

**Relații propuse:** - User → Trips: one-to-many. - User → Vehicles:
one-to-many, dacă vehiculele sunt incluse. - Vehicle → Trips:
one-to-many, dacă vehiculele sunt incluse. - Trip → GPSPoints:
one-to-many.

**Criterii de acceptare:** - Relațiile funcționează la citire și
scriere. - Ștergerea nu lasă date orfane. - Comportamentul cascade este
ales explicit.

## DB-08 --- Configurarea Alembic

**Prioritate:** P0 · **Status:** Done

**Criterii de acceptare:** - Alembic este configurat cu metadata
modelelor. - Migrațiile pot fi generate și aplicate. - Baza de date
poate fi actualizată reproductibil.

## DB-09 --- Indexuri și constrângeri

**Prioritate:** P1 · **Status:** Done

**Propuneri:** - Index pe `trip_id` în GPSPoint. - Index pe `user_id` în
Trip. - Index pe `recorded_at` dacă interogările o justifică. -
Unicitate pentru identificatorul punctului sincronizat.

**Criterii de acceptare:** - Indexurile sunt justificate de
interogări. - Constrângerile previn date invalide. - Nu se adaugă
indexuri inutile.

------------------------------------------------------------------------

# EPIC 4 --- Înregistrarea și gestionarea călătoriilor

## TRIP-01 --- Definirea stărilor unei călătorii

**Prioritate:** P0 · **Status:** Done

**Stări propuse:** `active`, `completed`, `cancelled`, eventual
`interrupted`.

**Criterii de acceptare:** - Tranzițiile permise sunt documentate. - O
călătorie finalizată nu revine accidental în starea activă. - O
călătorie întreruptă poate fi recuperată sau închisă controlat.

## TRIP-02 --- Pornirea unei călătorii

**Prioritate:** P0 · **Status:** In Progress

**Pași:** 1. Verifică permisiunile GPS. 2. Verifică serviciul de
localizare. 3. Verifică dacă există deja o călătorie activă. 4. Creează
călătoria local. 5. Înregistrează ora de început. 6. Pornește colectarea
GPS.

**Criterii de acceptare:** - Start pornește o singură sesiune. - Ora de
început este salvată. - Nu se pornesc două călătorii simultan pentru
același utilizator/vehicul. - Dacă GPS-ul nu este disponibil,
utilizatorul primește un mesaj clar.

## TRIP-03 --- Oprirea unei călătorii

**Prioritate:** P0 · **Status:** In Progress

**Pași:** 1. Oprește colectarea GPS. 2. Înregistrează ora de finalizare.
3. Calculează statisticile. 4. Marchează călătoria ca finalizată. 5.
Pregătește sincronizarea.

**Criterii de acceptare:** - Stop oprește efectiv fluxul GPS. - Ora
finalizării este salvată. - Statisticile sunt calculate o singură dată
sau pot fi recalculate determinist. - Nu se pierd punctele deja
colectate.

## TRIP-04 --- Verificarea călătoriei active

**Prioritate:** P0 · **Status:** In Progress

**Descriere:** La deschiderea aplicației, verifică dacă există o
călătorie activă.

**Criterii de acceptare:** - Utilizatorul vede că tracking-ul este
activ. - Aplicația nu pornește automat o a doua călătorie. - Poate
continua sau opri sesiunea existentă.

## TRIP-05 --- Salvarea punctelor GPS în timpul călătoriei

**Prioritate:** P0 · **Status:** In Progress

**Criterii de acceptare:** - Punctele sunt asociate călătoriei active. -
Sunt salvate timestamp-ul și metadatele disponibile. - Salvarea nu
depinde de internet. - Erorile de scriere sunt tratate.

## TRIP-06 --- Recuperarea unei călătorii întrerupte

**Prioritate:** P0 · **Status:** In Progress

**Descriere:** Gestionează situația în care aplicația este închisă
neașteptat sau procesul este oprit de sistem.

**Criterii de acceptare:** - La redeschidere se identifică sesiunea
neterminată. - Utilizatorului i se prezintă o opțiune clară de
continuare sau finalizare. - Datele colectate înainte de întrerupere nu
se pierd. - Nu se inventează puncte pentru perioada în care tracking-ul
nu a funcționat.

## TRIP-07 --- Anularea unei călătorii

**Prioritate:** P2 · **Status:** In Progress

**Descriere:** Permite anularea unei călătorii pornite accidental.

**Criterii de acceptare:** - Tracking-ul este oprit. - Călătoria este
marcată anulată sau ștearsă conform regulii stabilite. - Datele nu apar
în statisticile călătoriilor finalizate, dacă regula produsului spune
acest lucru.

## TRIP-08 --- Gestionarea unei singure călătorii active

**Prioritate:** P0 · **Status:** Done

**Criterii de acceptare:** - Aplicația previne pornirea unei a doua
călătorii active. - Backend-ul verifică aceeași regulă dacă există
autentificare și sincronizare. - Cererile simultane nu creează sesiuni
active duplicate.

------------------------------------------------------------------------

# EPIC 5 --- Calcularea distanței și statisticilor

## STAT-01 --- Implementarea calculului Haversine

**Prioritate:** P0 · **Status:** Done

**Descriere:** Calculează distanța în metri dintre două coordonate GPS
consecutive.

**Criterii de acceptare:** - Rezultatul este în metri. - Sunt validate
latitudinea și longitudinea. - Există teste pentru coordonate
cunoscute. - Cazul în care două puncte sunt identice returnează distanță
zero.

## STAT-02 --- Calcularea distanței totale

**Prioritate:** P0 · **Status:** Done

**Descriere:** Adună distanțele dintre punctele consecutive acceptate.

**Criterii de acceptare:** - Punctele invalide nu contribuie la
distanță. - Salturile nerealiste nu sunt incluse automat. - Distanța
este stocată într-o unitate stabilită. - Afișarea în kilometri este
corectă.

## STAT-03 --- Calcularea duratei totale

**Prioritate:** P0 · **Status:** Done

**Formula:** `ended_at - started_at`.

**Criterii de acceptare:** - Se folosesc timestamp-uri corecte. - Se
gestionează călătoriile fără finalizare. - Fusurile orare nu produc
durate greșite.

## STAT-04 --- Definirea timpului efectiv de deplasare

**Prioritate:** P1 · **Status:** Done

**Descriere:** Definește o regulă pentru a determina când vehiculul se
deplasează și când staționează.

**Criterii de acceptare:** - Pragul de viteză și durata minimă sunt
documentate. - Zgomotul GPS în jurul vitezei zero nu produce alternanțe
constante. - Rezultatul este testat pe exemple.

## STAT-05 --- Calcularea timpului de staționare

**Prioritate:** P1 · **Status:** Done

**Descriere:** Calculează timpul în care vehiculul este considerat
staționat.

**Criterii de acceptare:** - Regula este compatibilă cu definiția
timpului de deplasare. - Nu se presupune că lipsa datelor GPS înseamnă
staționare.

## STAT-06 --- Calcularea vitezei medii

**Prioritate:** P0 · **Status:** Done

**Descriere:** Calculează viteza medie conform definiției stabilite cu
beneficiarul.

**Variante de documentat:** - distanță / durată totală; - distanță /
timp efectiv de deplasare.

**Criterii de acceptare:** - Formula folosită este documentată. - Cazul
cu durată zero este tratat. - Unitatea este clară, de exemplu km/h.

## STAT-07 --- Calcularea vitezei maxime

**Prioritate:** P0 · **Status:** Done

**Descriere:** Determină cea mai mare viteză validă din punctele
acceptate.

**Criterii de acceptare:** - Valorile lipsă sunt ignorate. - Valorile
evident imposibile sunt filtrate. - Este clar dacă se folosește viteza
GPS sau viteza derivată din coordonate. - Nu se amestecă unități
diferite.

## STAT-08 --- Teste pentru calcule

**Prioritate:** P0 · **Status:** Done

**Cazuri minime:** - zero puncte; - un singur punct; - două puncte
identice; - două puncte cunoscute; - punct cu acuratețe slabă; - punct
cu viteză lipsă; - salt GPS nerealist; - durată zero; - călătorie fără
mișcare; - călătorie cu opriri.

**Criterii de acceptare:** - Testele rulează automat. - Rezultatele
așteptate sunt documentate. - Cazurile-limită nu produc excepții
necontrolate.

## STAT-09 --- Centralizarea statisticilor utilizatorului

**Prioritate:** P1 · **Status:** In Progress

**Descriere:** Calculează totalurile pentru toate călătoriile finalizate
ale utilizatorului.

**Criterii de acceptare:** - Sunt incluse doar călătoriile care trebuie
incluse conform regulilor produsului. - Nu sunt amestecate datele altor
utilizatori. - Totalul kilometrilor este coerent cu detaliile
călătoriilor.

## STAT-10 --- Statistici pe perioade

**Prioritate:** P2 · **Status:** Todo

**Descriere:** Adaugă statistici zilnice, săptămânale sau lunare numai
dacă sunt confirmate.

**Criterii de acceptare:** - Filtrarea după interval este corectă. -
Sunt definite limitele zilelor și fusul orar. - Rezultatele sunt
testate.

------------------------------------------------------------------------

# EPIC 6 --- Backend API pentru călătorii

## API-01 --- Endpoint de health check

**Prioritate:** P0 · **Status:** Done

**Criterii de acceptare:** - Returnează un status simplu. - Nu expune
date sensibile.

## API-02 --- Crearea unei călătorii

**Prioritate:** P0 · **Status:** Done

**Descriere:** Creează în backend o călătorie sau înregistrează
metadatele ei la sincronizare.

**Criterii de acceptare:** - Datele sunt validate. - Este atribuit un ID
stabil. - Nu se creează duplicate la retry.

## API-03 --- Trimiterea punctelor GPS în batch

**Prioritate:** P0 · **Status:** Done

**Descriere:** Primește un lot de puncte GPS pentru o călătorie.

**Cerințe:** - Validarea coordonatelor. - Validarea timestamp-urilor. -
Limită rezonabilă pentru dimensiunea batch-ului. - Identificator unic
pentru punct sau secvență. - Tratarea punctelor duplicate.

**Criterii de acceptare:** - Un batch valid este salvat. - Un batch
invalid returnează erori explicite. - Retrimiterea aceluiași batch nu
dublează punctele.

## API-04 --- Finalizarea unei călătorii

**Prioritate:** P0 · **Status:** Done

**Descriere:** Primește finalizarea și statisticile sau recalculează
statisticile din punctele GPS.

**Criterii de acceptare:** - Călătoria este marcată completă. -
Finalizarea repetată este tratată controlat. - Datele sunt consistente.

## API-05 --- Listarea călătoriilor

**Prioritate:** P1 · **Status:** Done

**Criterii de acceptare:** - Returnează doar călătoriile utilizatorului
autentificat, dacă există autentificare. - Permite sortare după dată. -
Răspunsul nu include toate punctele GPS dacă nu sunt necesare.

## API-06 --- Detaliile unei călătorii

**Prioritate:** P1 · **Status:** Done

**Criterii de acceptare:** - Returnează statisticile și metadatele
călătoriei. - Poate returna punctele GPS printr-o cerere separată sau
paginată dacă volumul este mare. - Verifică proprietarul călătoriei.

## API-07 --- Ștergerea unei călătorii

**Prioritate:** P2 · **Status:** Done

**Criterii de acceptare:** - Doar proprietarul sau rolul autorizat poate
șterge. - Se aplică regula de ștergere pentru punctele GPS asociate. -
Rezultatul este confirmat clar.

## API-08 --- Gestionarea erorilor API

**Prioritate:** P1 · **Status:** Done

**Criterii de acceptare:** - Codurile HTTP sunt potrivite. - Erorile de
validare sunt clare. - Nu sunt returnate stack trace-uri în producție.

------------------------------------------------------------------------

# EPIC 7 --- Stocare locală și sincronizare offline

## OFF-01 --- Configurarea SQLite

**Prioritate:** P0 · **Status:** Done

**Descriere:** Configurează baza de date locală pentru călătorii și
punctele GPS.

**Criterii de acceptare:** - Baza locală este creată. - Datele persistă
după închiderea aplicației. - Schema locală este documentată.

## OFF-02 --- Salvarea locală a călătoriei

**Prioritate:** P0 · **Status:** Done

**Criterii de acceptare:** - Călătoria este salvată înainte de
sincronizare. - Starea activă este recuperabilă după redeschiderea
aplicației.

## OFF-03 --- Salvarea locală a punctelor GPS

**Prioritate:** P0 · **Status:** Done

**Criterii de acceptare:** - Fiecare punct este asociat călătoriei
locale. - Ordinea punctelor este păstrată. - Scrierea este suficient de
eficientă pentru tracking.

## OFF-04 --- Definirea stării de sincronizare

**Prioritate:** P0 · **Status:** Done

**Stări propuse:** pending, syncing, synced, failed.

**Criterii de acceptare:** - Fiecare călătorie și/sau batch are stare de
sincronizare. - Eșecurile pot fi reluate. - Nu se pierd datele locale
după un eșec.

## OFF-05 --- Sincronizarea batch-urilor GPS

**Prioritate:** P0 · **Status:** Done

**Criterii de acceptare:** - Punctele sunt trimise în loturi. -
Batch-urile au identificatori stabili. - Răspunsurile serverului
confirmă datele acceptate. - Loturile nereușite rămân în așteptare.

## OFF-06 --- Detectarea conexiunii și retry

**Prioritate:** P1 · **Status:** In Progress

**Criterii de acceptare:** - Aplicația poate continua tracking-ul fără
internet. - Sincronizarea se reia după reconectare. - Retry-ul nu
creează duplicate. - Erorile permanente nu produc bucle infinite de
retry.

## OFF-07 --- Prevenirea duplicatelor

**Prioritate:** P0 · **Status:** Done

**Descriere:** Folosește un ID generat local pentru fiecare punct sau un
identificator de batch plus număr de secvență.

**Criterii de acceptare:** - Retrimiterea unui punct nu creează un al
doilea punct. - Serverul aplică o constrângere sau o verificare de
idempotency.

## OFF-08 --- Curățarea datelor locale sincronizate

**Prioritate:** P2 · **Status:** Todo

**Descriere:** Stabilește dacă și când pot fi șterse datele locale deja
sincronizate.

**Criterii de acceptare:** - Nu se șterg date înainte de confirmarea
serverului. - Se respectă necesitatea afișării istoricului offline. -
Politica este documentată.

------------------------------------------------------------------------

# EPIC 8 --- Interfața Flutter

## UI-01 --- Structura de navigare

**Prioritate:** P1 · **Status:** In Progress

**Descriere:** Creează navigarea minimă între Dashboard, Trip History și
Profile/Settings dacă sunt necesare.

**Criterii de acceptare:** - Navigarea este funcțională. - Nu există
ecrane fără cale de întoarcere. - Structura este simplă.

## UI-02 --- Dashboard

**Prioritate:** P1 · **Status:** In Progress

**Elemente propuse:** - Buton Start Trip. - Indicator pentru călătorie
activă. - Total kilometri. - Ultima călătorie. - Acces la istoric.

**Criterii de acceptare:** - Datele sunt afișate din sursa corectă. -
Starea goală este tratată. - Butonul Start respectă starea
tracking-ului.

## UI-03 --- Ecran Active Trip

**Prioritate:** P0 · **Status:** In Progress

**Elemente propuse:** - Durata curentă. - Distanța curentă. - Viteza
curentă. - Buton Stop Trip. - Indicator clar că tracking-ul este activ.

**Criterii de acceptare:** - Valorile se actualizează. - Utilizatorul
poate opri călătoria. - Starea activă este vizibilă. - Erorile GPS sunt
comunicate.

## UI-04 --- Ecran Trip History

**Prioritate:** P1 · **Status:** In Progress

**Elemente propuse:** - Data. - Durata. - Distanța. - Viteza medie.

**Criterii de acceptare:** - Călătoriile sunt listate. - Starea fără
călătorii este tratată. - Selectarea unei călătorii deschide detaliile.

## UI-05 --- Ecran Trip Details

**Prioritate:** P1 · **Status:** In Progress

**Elemente propuse:** - Data și intervalul orar. - Distanța. - Durata. -
Viteza medie. - Viteza maximă. - Traseul pe hartă, dacă este inclus în
MVP.

**Criterii de acceptare:** - Statisticile corespund călătoriei
selectate. - Datele lipsă sunt afișate clar. - Traseul este ordonat
cronologic.

## UI-06 --- Ecran Settings/Profile

**Prioritate:** P1 · **Status:** Todo

**Elemente propuse:** - Email și rolul contului. - Informații despre
permisiuni. - Logout.

**Criterii de acceptare:** - Contul curent este afișat clar. - Logout-ul
confirmă acțiunea și nu șterge datele locale nesincronizate.

## UI-07 --- Stări Loading, Error și Empty

**Prioritate:** P1 · **Status:** In Progress

**Criterii de acceptare:** - Apelurile API afișează loading. - Erorile
sunt explicate utilizatorului. - Listele goale au un mesaj potrivit. -
Nu se afișează ecrane albe la erori.

## UI-08 --- Tratarea rotației și dimensiunilor ecranului

**Prioritate:** P2 · **Status:** Todo

**Criterii de acceptare:** - Ecranele principale rămân utilizabile pe
dimensiuni Android diferite. - Conținutul nu este tăiat.

## UI-09 --- Rafinarea vizuală a interfeței

**Prioritate:** P1 · **Status:** Todo

**Descriere:** Temă unitară, carduri și spațiere consecvente, ecrane de
autentificare și administrare coerente.

**Criterii de acceptare:** - Aceeași paletă, tipografie și stil de
carduri pe toate ecranele. - Butoanele și câmpurile au stări clare
(normal/loading/error). - Aspect corect pe tabletă și telefon. - Modul
întunecat rămâne lizibil. - Nu se adaugă biblioteci doar pentru
animații.

------------------------------------------------------------------------

# EPIC 9 --- Hartă și vizualizarea traseului

## MAP-01 --- Alegerea și configurarea sursei de hartă

**Prioritate:** P1 · **Status:** In Progress

**Propunere:** OpenStreetMap prin `flutter_map`.

**Criterii de acceptare:** - Sursa tile-urilor este aleasă. - Sunt
respectate condițiile de utilizare și atribuirea. - Cheile/API-urile
necesare sunt configurate în siguranță.

## MAP-02 --- Afișarea hărții

**Prioritate:** P1 · **Status:** In Progress

**Criterii de acceptare:** - Harta se încarcă. - Erorile de rețea sunt
tratate. - Atribuirea sursei hărții este vizibilă.

## MAP-03 --- Afișarea poziției curente

**Prioritate:** P1 · **Status:** In Progress

**Criterii de acceptare:** - Poziția curentă este marcată. - Harta poate
centra poziția. - Lipsa locației este tratată.

## MAP-04 --- Desenarea traseului în timpul călătoriei

**Prioritate:** P1 · **Status:** In Progress

**Criterii de acceptare:** - Punctele sunt desenate în ordinea
colectării. - Traseul se actualizează fără reconstruiri excesive. -
Punctele invalide nu produc segmente aberante.

## MAP-05 --- Marcarea începutului și sfârșitului

**Prioritate:** P2 · **Status:** In Progress

**Criterii de acceptare:** - Start și finish sunt marcate distinct. -
Marker-ele folosesc punctele valide corespunzătoare.

## MAP-06 --- Vizualizarea traseului istoric

**Prioritate:** P1 · **Status:** In Progress

**Criterii de acceptare:** - Traseul poate fi încărcat din datele
salvate. - Harta ajustează zoom-ul pentru a include traseul. -
Călătoriile fără coordonate sunt tratate.

------------------------------------------------------------------------

# EPIC 10 --- Autentificare și autorizare

> Multi-user este confirmat (REQ-01): rolurile `user` și `admin`,
> înregistrare liberă, primul cont devine admin. Endpointurile private
> cer token JWT, iar datele sunt izolate în backend.

## AUTH-01 --- Înregistrarea utilizatorului

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Email-ul este validat și unic. - Parola
este hash-uită, niciodată stocată în clar. - Email-ul duplicat este
respins cu un mesaj clar.

## AUTH-02 --- Autentificarea utilizatorului

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Credențialele corecte permit
autentificarea. - Credențialele greșite sunt respinse. - Răspunsul nu
divulgă dacă email-ul sau parola este greșită.

## AUTH-03 --- JWT

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Tokenul are expirare. - Semnarea folosește
un secret din configurație, fără valoare implicită în cod. -
Tokenurile invalide sau expirate sunt respinse cu 401.

## AUTH-04 --- Protejarea endpointurilor

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Endpointurile private cer autentificare
(excepție: health, register, login). - Backend-ul identifică
utilizatorul din token. - Nu se bazează pe `user_id` trimis liber de
client pentru autorizare.

## AUTH-05 --- Izolarea datelor utilizatorilor

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Utilizatorul A nu poate citi, modifica sau
șterge călătoriile utilizatorului B. - Verificarea este realizată în
backend. - Există teste pentru acces neautorizat. - Adminul are acces
explicit doar prin endpointurile de administrare.

## AUTH-06 --- Stocarea tokenului în Flutter

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Tokenul este stocat cu
`flutter_secure_storage`, nu în preferințe obișnuite. - Tokenul este
trimis prin HTTPS în producție. - Logout-ul elimină tokenul local.

## AUTH-07 --- Logout

**Prioritate:** P1 · **Status:** Todo

**Criterii de acceptare:** - Sesiunea locală este închisă. - Datele
locale nesincronizate nu sunt șterse accidental. - O călătorie activă
este oprită fără a fi pierdută și poate fi reluată după autentificare. -
Comportamentul este documentat.

## AUTH-08 --- Roluri `user` și `admin`

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Rolul este stocat în baza de date și
validat prin constrângere. - Rolul este citit din backend, nu din
client. - Există o dependență `require_admin` pentru endpointurile
administrative. - Rolul apare în răspunsul de autentificare.

## AUTH-09 --- Bootstrap pentru primul admin

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Primul cont înregistrat primește automat
rolul `admin`. - Conturile următoare primesc rolul `user`. - Logica nu
se bazează pe utilizatori vechi fără parolă. - Comportamentul este
documentat.

## AUTH-10 --- Ecranele de autentificare în Flutter

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Ecrane de login și înregistrare cu
validare și stări loading/error. - Sesiunea este restaurată la pornire
prin `/auth/me`. - Un token invalid duce la ecranul de login, fără ecran
alb. - După autentificare, călătoriile locale sunt filtrate după
proprietar.

------------------------------------------------------------------------

# EPIC 11 --- Vehicule (opțional)

## VEH-01 --- Adăugarea unui vehicul

**Prioritate:** P3 · **Status:** Blocked

**Criterii de acceptare:** - Utilizatorul poate introduce datele
confirmate. - Validarea câmpurilor este implementată. - Vehiculul este
asociat utilizatorului.

## VEH-02 --- Editarea unui vehicul

**Prioritate:** P3 · **Status:** Blocked

## VEH-03 --- Ștergerea unui vehicul

**Prioritate:** P3 · **Status:** Blocked

**Criterii de acceptare:** - Ștergerea nu elimină accidental istoricul
călătoriilor. - Se definește comportamentul pentru călătoriile deja
asociate.

## VEH-04 --- Asocierea călătoriilor cu vehicule

**Prioritate:** P3 · **Status:** Blocked

------------------------------------------------------------------------

# EPIC 12 --- Istoric și rapoarte avansate (opțional)

## HIST-01 --- Filtrarea călătoriilor după dată

**Prioritate:** P2 · **Status:** Todo

## HIST-02 --- Sortarea călătoriilor

**Prioritate:** P2 · **Status:** Todo

## HIST-03 --- Total kilometri pe perioadă

**Prioritate:** P2 · **Status:** Todo

## HIST-04 --- Grafice săptămânale/lunare

**Prioritate:** P3 · **Status:** Todo

## HIST-05 --- Export CSV

**Prioritate:** P3 · **Status:** Todo

## HIST-06 --- Export PDF/Excel

**Prioritate:** P3 · **Status:** Todo

**Criterii generale:** - Filtrele folosesc intervale de timp corecte. -
Exportul conține doar datele autorizate. - Valorile și unitățile sunt
consistente cu ecranele aplicației.

------------------------------------------------------------------------

# EPIC 13 --- Testare și stabilitate

## TEST-01 --- Teste unitare pentru calcule

**Prioritate:** P0 · **Status:** Done

Acoperă Haversine, distanță totală, durate, viteze și filtrarea
punctelor.

## TEST-02 --- Teste pentru modelele și accesul la DB

**Prioritate:** P1 · **Status:** Done

Verifică relațiile, constrângerile și operațiile de bază.

## TEST-03 --- Teste pentru endpointuri

**Prioritate:** P1 · **Status:** Done

Verifică răspunsuri valide, date invalide, lipsa resurselor și erori.

## TEST-04 --- Teste de autentificare și autorizare

**Prioritate:** P1 · **Status:** Blocked

Verifică accesul fără token, token expirat și accesul la datele altui
utilizator.

## TEST-05 --- Testare pe Android real

**Prioritate:** P0 · **Status:** Todo

Verifică GPS, permisiuni, tracking, ecran stins și consumul bateriei.

## TEST-06 --- Testare offline

**Prioritate:** P0 · **Status:** Todo

Dezactivează internetul în timpul unei călătorii și verifică păstrarea
punctelor.

## TEST-07 --- Testare sincronizare repetată

**Prioritate:** P0 · **Status:** In Progress

Simulează timeout și retrimiterea aceluiași batch.

## TEST-08 --- Testare închiderea aplicației

**Prioritate:** P0 · **Status:** Todo

Verifică recuperarea călătoriei după închidere neașteptată.

## TEST-09 --- Testare cazuri-limită

**Prioritate:** P1 · **Status:** In Progress

Exemple: - GPS dezactivat în timpul călătoriei. - Permisiune revocată. -
Baterie redusă. - Telefon fără internet. - Lipsă puncte GPS pentru o
perioadă. - Călătorie foarte scurtă. - Călătorie foarte lungă. -
Aplicație oprită de sistem. - Apăsare repetată pe Start/Stop.

## TEST-10 --- Verificarea consumului bateriei

**Prioritate:** P2 · **Status:** Todo

Compară comportamentul pentru intervale de colectare diferite și
documentează rezultatele.

## TEST-11 --- Verificarea performanței pentru trasee lungi

**Prioritate:** P2 · **Status:** Todo

Verifică stocarea, sincronizarea și afișarea unui număr mare de puncte.

------------------------------------------------------------------------

# EPIC 14 --- Securitate, confidențialitate și deployment

## SEC-01 --- Protejarea secretelor

**Prioritate:** P0 · **Status:** Done

-   Nu comite `.env`.
-   Nu include parole în cod.
-   Nu expune chei private în aplicația mobilă.
-   Folosește configurație separată pentru producție.

## SEC-02 --- HTTPS în producție

**Prioritate:** P0 înainte de lansare · **Status:** In Progress

**Criterii de acceptare:** - API-ul de producție folosește HTTPS. -
Aplicația nu trimite tokenuri prin HTTP neprotejat.

## SEC-03 --- Protejarea datelor GPS

**Prioritate:** P0 înainte de lansare · **Status:** Todo

**Criterii de acceptare:** - Accesul la coordonate este limitat. -
Backend-ul verifică proprietarul datelor. - Logurile nu includ
coordonate sau tokenuri fără motiv.

## SEC-04 --- Informarea utilizatorului despre tracking

**Prioritate:** P0 · **Status:** In Progress

**Criterii de acceptare:** - Utilizatorul știe când tracking-ul este
activ. - Scopul permisiunii GPS este explicat. - Există o metodă clară
de oprire.

## SEC-05 --- Ștergerea datelor și contului

**Prioritate:** P1 înainte de lansare · **Status:** Todo

**Criterii de acceptare:** - Este definit ce se șterge. - Sunt tratate
și punctele GPS asociate. - Comportamentul este documentat.

## SEC-06 --- Documentarea retenției datelor

**Prioritate:** P1 înainte de lansare · **Status:** Todo

**Criterii de acceptare:** - Este stabilită perioada de păstrare. -
Utilizatorul este informat. - Datele nu sunt păstrate nelimitat fără
motiv.

## DEP-01 --- Pregătirea backend-ului pentru producție

**Prioritate:** P1 · **Status:** Todo

-   Configurare variabile de mediu.
-   Configurare server.
-   Migrații DB.
-   Logging controlat.
-   Health check.

## DEP-02 --- Deployment backend

**Prioritate:** P1 · **Status:** Todo

Alege furnizorul după estimarea costurilor, cerințelor și volumului de
date.

## DEP-03 --- Configurarea bazei de date de producție

**Prioritate:** P1 · **Status:** Todo

-   Acces limitat.
-   Backup.
-   Migrații.
-   Conexiune securizată.

## DEP-04 --- Build Android

**Prioritate:** P1 · **Status:** Todo

**Criterii de acceptare:** - Build-ul release se generează. - Aplicația
folosește URL-ul API de producție. - Permisiunile și notificarea de
tracking sunt configurate corect. - Semnarea aplicației este gestionată
în siguranță.

## DEP-05 --- Documentația de instalare și utilizare

**Prioritate:** P1 · **Status:** Todo

Documentează: - instalarea backend-ului; - configurarea bazei de date; -
pornirea Flutter; - permisiunile Android; - pornirea și oprirea unei
călătorii; - limitările tracking-ului; - procedura de sincronizare.

------------------------------------------------------------------------

# EPIC 15 --- Administrare (rol admin)

## ADMIN-01 --- Endpoint admin pentru toate călătoriile

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Endpointul este accesibil doar rolului
`admin`; un utilizator normal primește 403. - Returnează călătoriile
tuturor utilizatorilor, inclusiv email-ul proprietarului. - Rezultatele
sunt sortate după data începerii. - Există teste pentru admin și pentru
accesul interzis.

## ADMIN-02 --- Ecranul Admin în Flutter

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Opțiunea Admin apare doar pentru rolul
`admin`. - Lista arată toate călătoriile, cu proprietarul fiecăreia. -
Sunt tratate stările loading, error și listă goală. - Lista poate fi
reîmprospătată. - Călătoriile adminului rămân disponibile în Istoric, ca
la un utilizator normal.

## ADMIN-03 --- Detaliile unei călătorii din pagina admin

**Prioritate:** P0 · **Status:** Todo

**Criterii de acceptare:** - Punctele GPS ale călătoriei selectate sunt
încărcate din backend. - Statisticile și harta corespund călătoriei
selectate. - Erorile de rețea sunt afișate controlat.

------------------------------------------------------------------------

# Ordinea recomandată de implementare

1.  SET-01 până la SET-07 --- setup.
2.  GPS-01 până la GPS-10 --- verificarea GPS și background tracking.
3.  DB-01 până la DB-09 --- baza de date.
4.  TRIP-01 până la TRIP-08 --- gestionarea călătoriilor.
5.  STAT-01 până la STAT-08 --- calcule și teste.
6.  OFF-01 până la OFF-07 --- stocare și sincronizare.
7.  API-01 până la API-08 --- API pentru călătorii.
8.  UI-01 până la UI-08 --- interfață.
9.  MAP-01 până la MAP-06 --- hartă.
10. AUTH-08, AUTH-09, AUTH-01 până la AUTH-07, AUTH-10 ---
    autentificare multi-user.
11. ADMIN-01 până la ADMIN-03 --- administrare.
12. UI-09 --- rafinarea vizuală, după ce fluxurile sunt stabile.
13. TEST-01 până la TEST-11 --- verificări complete.
14. SEC și DEP --- pregătire pentru lansare.
15. Epic-urile opționale numai după confirmarea beneficiarului.

**Notă despre ordine:** Unele tichete pot fi realizate în paralel după
stabilirea contractelor dintre componente, dar GPS Proof of Concept
trebuie validat devreme. Nu amâna testarea background tracking până la
final.

------------------------------------------------------------------------

# Definition of Done --- condiții generale

Un tichet poate fi marcat Done când: - cerința descrisă este
implementată; - codul respectă principiul KISS; - nu au fost introduse
dependențe inutile; - cazurile de eroare relevante sunt tratate; -
testele relevante trec; - funcționalitatea a fost verificată la nivelul
potrivit (unit test, API test sau dispozitiv real); - documentația este
actualizată dacă s-a schimbat comportamentul; - nu au fost introduse
secrete în repository.

# Decizii care trebuie păstrate vizibile

1.  Platforma curentă: Android.
2.  Frontend: Flutter.
3.  Backend: FastAPI.
4.  Bază de date: PostgreSQL.
5.  Stocare locală: SQLite.
6.  Hartă propusă: OpenStreetMap + flutter_map.
7.  Tracking inițial: pornire și oprire manuală.
8.  Tracking-ul trebuie testat în background pe telefon Android real.
9.  Datele GPS trebuie salvate local înainte de sincronizare.
10. Nu implementa funcționalități opționale fără confirmarea
    beneficiarului.
11. Respectă KISS și evită arhitectura excesivă.
12. Aplicația este multi-user, cu rolurile `user` și `admin`.
13. Înregistrarea este liberă din aplicație; primul cont devine admin.
14. Adminul vede propriile călătorii ca un user normal și are o pagină
    separată cu toate călătoriile, etichetate cu proprietarul.
15. Fiecare tichet se lucrează pe branch separat și se merge în `main`
    numai după ce testele relevante trec.
