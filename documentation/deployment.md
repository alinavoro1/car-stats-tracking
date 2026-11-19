# Deploy în cloud

Backend-ul poate rula pe orice host Docker. Sunt pregătite două variante
simple: **Railway** și **Render**. Ambele oferă HTTPS automat și
PostgreSQL gestionat.

> Deploy-ul necesită contul tău pe platformă. Codul este pregătit, dar
> crearea contului și autorizarea repository-ului sunt pași manuali.

## Varianta A — Railway

Potrivită dacă ai deja cont/credit de la hackathon.

1. Intră pe <https://railway.app> și autentifică-te cu GitHub.
2. **New Project → Deploy from GitHub repo** și alege repository-ul
   proiectului. Dacă repo-ul este privat, autorizează accesul.
3. În serviciul creat, setează **Root Directory = `backend`**
   (Settings → Source). Dockerfile-ul este `backend/Dockerfile`.
4. Adaugă o bază de date: **New → Database → PostgreSQL**.
5. În serviciul aplicației, adaugă variabilele:
   - `DATABASE_URL` = referința către PostgreSQL
     (`${{Postgres.DATABASE_URL}}`);
   - `SECRET_KEY` = o valoare aleatoare generată cu
     `python -c "import secrets; print(secrets.token_urlsafe(48))"`;
   - `ACCESS_TOKEN_EXPIRE_MINUTES` = `60`.
6. **Settings → Networking → Generate Domain**.
7. Verifică `https://<domeniu>/api/v1/health` și
   `https://<domeniu>/docs`.

Notă: Railway oferă un credit de trial; pentru consum îndelungat poate
fi nevoie de un plan plătit. Verifică creditul din cont.

## Varianta B — Render

1. Intră pe <https://render.com> și autentifică-te cu GitHub.
2. **New → Blueprint**, alege repository-ul proiectului și aplică
   `render.yaml` din rădăcină.
3. Blueprint-ul creează serviciul Docker și baza PostgreSQL.
4. După deploy, copiază URL-ul serviciului și verifică
   `https://<serviciu>/api/v1/health`.

Planul free al serviciului web intră în sleep după inactivitate și
pornește lent la prima cerere. Verifică disponibilitatea planului free
pentru PostgreSQL în contul tău; dacă nu este disponibil, creează o bază
PostgreSQL (Render, Neon, Supabase) și setează `DATABASE_URL` manual.

## Orice alt host Docker

Sunt necesare doar:

- imagine construită din `backend/Dockerfile`;
- variabilele `DATABASE_URL` (PostgreSQL) și `SECRET_KEY`;
- portul oferit de platformă în `PORT` (Dockerfile-ul îl folosește);
- HTTPS în fața serviciului.

Migrațiile Alembic rulează automat la pornirea containerului.

## După deploy

1. Backend-ul are baza de date goală; **primul cont înregistrat devine
   admin**. Înregistrează întâi contul proprietarului, înainte de a
   împărți aplicația cu testerii.
2. Reconstruiește APK-ul cu adresa cloud:
   ```bash
   flutter build apk --release \
     --dart-define=API_BASE_URL=https://<domeniu>/api/v1
   ```
3. Datele locale din PostgreSQL-ul de pe calculator **nu se migrează
   automat**. Pentru test este suficientă o bază nouă; migrarea se poate
   face separat cu `pg_dump`/`pg_restore`.
4. Linkul de instalare trebuie să fie găzduit tot în cloud (pagină
   statică + APK), ca să nu depindă de calculatorul local.
