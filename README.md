# AIRBNB-DBMS
# Proiect-SGBD: Sistem de Gestiune a Rezervărilor de Locuințe (Tip Airbnb) 🏡

## Descriere
Această bază de date este proiectată pentru a gestiona procesul de rezervare a locuințelor disponibile pe o platformă de tip Airbnb. Sistemul permite administrarea locuințelor, utilizatorilor, rezervărilor și gazdelor, oferind o evidență clară și eficientă a închirierilor.
___
## Tehnologii utilizate
- Limbaj SGBD: Oracle PL/SQL (Oracle Database 19c)
- Sistem de operare: Windows 11 Pro
___
Modelare baze de date: Diagrama ERD și diagrama conceptuala in draw.io

## Funcționalități principale
- [x] Gestionarea locuințelor – fiecare are un tip, o locație și este administrată de o gazdă
- [x] Administrarea utilizatorilor – evidența clienților care fac rezervări
- [x] Sistem de rezervări – înregistrarea și gestionarea rezervărilor active
- [x] Calculul tarifelor și raportarea veniturilor – analiza câștigurilor generate pentru fiecare gazdă
- [x] Gestionarea dotărilor – evidența facilităților oferite în fiecare locuință
- [x] Sistem de protecție și audit – monitorizarea modificărilor și prevenirea ștergerii accidentale a datelor

___

## Structura bazei de date
Tabele principale: utilizator, gazda, locuinta, rezervare, dotari, tarife, locatie
#### Cateva relații:
- Utilizatorii pot face mai multe rezervări.
- Fiecare locuință aparține unei gazde și poate avea mai multe dotări.
- Gazdele pot deține mai multe locuințe.
- Fiecare rezervare este asociată unui singur utilizator și unei singure locuințe.
  
💰 Sistem de tarifare și venituri

Tarifele per persoană:
- Apartament: 100-250 lei
- Hotel: 200-500 lei
- Cabană/Vilă: 150-400 lei
  
🔹 Gazdele pot genera rapoarte de câștiguri pe baza rezervărilor efectuate

🔹 Utilizatorii pot vizualiza detaliile rezervărilor și costurile aferente
___

### Exemple de interogări SQL și proceduri PL/SQL
1️⃣ Procedură pentru verificarea disponibilității locuințelor
```bash
CREATE OR REPLACE PROCEDURE loc_disponibile(
    p_regiune IN regiuni.nume_regiune%TYPE,
    perioada_start IN DATE,
    perioada_stop IN DATE
) IS
BEGIN
    -- Verifică disponibilitatea locuințelor în perioada dată și afișează dotările acestora
END;
/
```
2️⃣ Funcție pentru determinarea rezervării cu cea mai mare valoare
```bash
CREATE OR REPLACE FUNCTION rezervare_maxima(tara_input IN tari.nume_tara%TYPE) 
RETURN NUMBER IS
BEGIN
    RETURN 0; -- Returnează valoarea maximă a unei rezervări în țara respectivă
END;
/
```
3️⃣ Trigger pentru auditarea modificărilor în rezervări
```bash
CREATE OR REPLACE TRIGGER trig_audit_rezervari
AFTER INSERT OR UPDATE OR DELETE ON rezervare
BEGIN
    -- Înregistrare automată a modificărilor în tabela de audit
END;
/
```
## Cum rulezi proiectul?
1️⃣ Instalează Oracle Database 19c

2️⃣ Importă scripturile PL/SQL în SQL Developer sau alt client compatibil

3️⃣ Rulează scripturile pentru crearea tabelelor și a relațiilor

4️⃣ Testează funcționalitățile prin rularea procedurilor și interogărilor

## Scopul proiectului
Acest proiect are ca obiectiv principal dezvoltarea unei baze de date eficiente pentru gestionarea rezervărilor de locuințe într-o platformă de tip Airbnb. Prin implementarea acestui sistem, se urmăresc următoarele beneficii:

✔️ **Oferirea unei experiențe eficiente și personalizate** – utilizatorii pot găsi rapid locuințe disponibile, iar gazdele își pot administra închirierile cu ușurință.

✔️ **Administrarea optimă a proprietăților** – evidența clară a locuințelor, rezervărilor și veniturilor generate.

✔️ **Creșterea satisfacției clienților** – printr-un sistem bine organizat de rezervări, tarife și dotări.

✔️ **Monitorizarea și auditarea proceselor** – implementarea de trigger-e și mecanisme de protecție pentru securizarea bazei de date.

✔️ **Generarea de rapoarte financiare și statistice** – pentru a ajuta gazdele să își optimizeze strategiile de închiriere.

✔️ **Fixarea cunoștințelor dobândite în cadrul cursului** – proiectul integrează concepte avansate din gestionarea bazelor de date, utilizând proceduri stocate, funcții, cursoare, trigger-e și mecanisme de audit pentru a dezvolta un sistem complex și funcțional.
