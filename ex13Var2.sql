CREATE OR REPLACE PACKAGE pachetEx13 AS

    -- Tipuri de date complexe
    TYPE record_rezervari IS RECORD (
        id_rezervare NUMBER,
        id_utilizator NUMBER,
        id_locuinta NUMBER,
        data_inceput DATE,
        data_sfarsit DATE,
        cost_total NUMBER
    );

    TYPE lista_rezervari IS TABLE OF record_rezervari;
    
    
    TYPE record_locuinta IS RECORD (
        id_locuinta NUMBER,
        nume_locuinta VARCHAR2(70),
        venit_locuinta NUMBER
    );

    TYPE lista_locuinte IS TABLE OF record_locuinta;
    
     TYPE record_gazda IS RECORD (
        id_gazda NUMBER,
        venit_total NUMBER,
        nume_gazda VARCHAR2(50),
        prenume_gazda VARCHAR2(50),
        locuinte_rezervate lista_locuinte
    );

    TYPE lista_gazde IS TABLE OF record_gazda;



    -- Functii
    FUNCTION calculVenitLunar(luna VARCHAR2, year VARCHAR2) RETURN NUMBER;
    FUNCTION calculVenitAnual(year VARCHAR2) RETURN NUMBER;

    -- Proceduri
    PROCEDURE raportAnual(year VARCHAR2);
    PROCEDURE raportRezervariAn(year VARCHAR2);
    PROCEDURE top3Gazde(year VARCHAR2);
    
END pachetEx13;
/

CREATE OR REPLACE PACKAGE BODY pachetEx13 AS

    rezervari lista_rezervari;
    venituri_anuale NUMBER := 0;

     FUNCTION calculVenitLunar(luna VARCHAR2, year VARCHAR2) RETURN NUMBER IS
        total_luna NUMBER := 0;
    BEGIN
            FOR rec IN (
                SELECT r.id_rezervare, 
                       SUM(r.numar_persoane * t.pret_per_persoana) + NVL(SUM(d.cost_suplimentar), 0) AS cost_total_rezervare
                FROM rezervare r
                JOIN se_asociaza_la s ON r.id_rezervare = s.id_rezervare
                JOIN locuinta l ON s.id_locuinta = l.id_locuinta
                JOIN tipuri_locuinte tip ON tip.id_tip = l.id_tip
                JOIN tarife t ON tip.id_tarif = t.id_tarif
                LEFT JOIN are a ON l.id_locuinta = a.id_locuinta
                LEFT JOIN dotari d ON a.id_dotare = d.id_dotare
                WHERE TRIM(TO_CHAR(data_inceput, 'Month')) = luna
                  AND TO_CHAR(data_inceput, 'YYYY') = year
                GROUP BY r.id_rezervare
            ) LOOP
                total_luna := total_luna + rec.cost_total_rezervare;
            END LOOP;
         RETURN total_luna;
    END calculVenitLunar;

   FUNCTION calculVenitAnual(year VARCHAR2) RETURN NUMBER IS
        total_an NUMBER := 0;
        venit_lunar NUMBER;
        luna VARCHAR2(9); -- Numele lunii
    BEGIN
        
        FOR i IN 1..12 LOOP
            luna := TRIM(TO_CHAR(TO_DATE(i, 'MM'), 'Month'));
            
            
            venit_lunar := calculVenitLunar(luna, year);
            
           
            total_an := total_an + venit_lunar;
        END LOOP;
        
        RETURN total_an;
    END calculVenitAnual;

    -- Procedura raportAnual
   PROCEDURE raportAnual(year VARCHAR2) IS
    total_an NUMBER := 0;
    venit_lunar NUMBER;
    luna VARCHAR2(9); -- Numele lunii
BEGIN
    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('Raport anual pentru anul ' || year || ':');
    DBMS_OUTPUT.PUT_LINE('==============================================');
    
    FOR i IN 1..12 LOOP
       
        luna := TRIM(TO_CHAR(TO_DATE(i, 'MM'), 'Month'));
        
        venit_lunar := calculVenitLunar(luna, year);
        
        DBMS_OUTPUT.PUT_LINE('     '||i||'.Luna ' || luna || ': Venit ' || venit_lunar);
        
        total_an := total_an + venit_lunar;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('        Venit total anual: ' || total_an);
END raportAnual;

-- Procedura raportRezervariAn
    PROCEDURE raportRezervariAn(year VARCHAR2) IS
        rezervari_an lista_rezervari := lista_rezervari();
        total_rezervari NUMBER := 0;
    BEGIN
        FOR rec IN (
            SELECT r.id_rezervare,
                   r.id_utilizator,
                   l.id_locuinta,
                   r.data_inceput,
                   r.data_sfarsit,
                   (SUM(r.numar_persoane * t.pret_per_persoana) + NVL(SUM(d.cost_suplimentar), 0)) AS cost_total_rezervare
            FROM rezervare r
            JOIN se_asociaza_la s ON r.id_rezervare = s.id_rezervare
            JOIN locuinta l ON s.id_locuinta = l.id_locuinta
            JOIN tipuri_locuinte tip ON tip.id_tip = l.id_tip
            JOIN tarife t ON tip.id_tarif = t.id_tarif
            LEFT JOIN are a ON l.id_locuinta = a.id_locuinta
            LEFT JOIN dotari d ON a.id_dotare = d.id_dotare
            WHERE TO_CHAR(r.data_inceput, 'YYYY') = year
            GROUP BY r.id_rezervare, r.id_utilizator, l.id_locuinta, r.data_inceput, r.data_sfarsit
        ) LOOP
      
            rezervari_an.EXTEND;
            rezervari_an(rezervari_an.COUNT) := record_rezervari(
                rec.id_rezervare,
                rec.id_utilizator,
                rec.id_locuinta,
                rec.data_inceput,
                rec.data_sfarsit,
                rec.cost_total_rezervare
            );
            
          
            total_rezervari := total_rezervari + rec.cost_total_rezervare;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('=================================================');
        DBMS_OUTPUT.PUT_LINE('Raport rezervari pentru anul ' || year || ':');
        DBMS_OUTPUT.PUT_LINE('=================================================');
        FOR i IN 1..rezervari_an.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('Rezervare ID: ' || rezervari_an(i).id_rezervare ||
                                 ', Utilizator ID: ' || rezervari_an(i).id_utilizator ||
                                 ', Locuinta ID: ' || rezervari_an(i).id_locuinta ||
                                 ', Perioada: ' || rezervari_an(i).data_inceput || ' - ' || rezervari_an(i).data_sfarsit ||
                                 ', Cost total: ' || rezervari_an(i).cost_total);
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('        Total venit din rezervari in acest an: ' || total_rezervari);
    END raportRezervariAn;

   
PROCEDURE top3Gazde(year VARCHAR2) IS
    gazde lista_gazde := lista_gazde(); 
    venit_gazda NUMBER;
    nume_gazda VARCHAR2(100);
    prenume_gazda VARCHAR2(100);
    locuinte_rezervate lista_locuinte := lista_locuinte(); 
BEGIN
    
    FOR rec IN (
        SELECT l.id_gazda,
               SUM(r.numar_persoane * t.pret_per_persoana + NVL(d.cost_suplimentar, 0)) AS venit_total
        FROM locuinta l
        JOIN se_asociaza_la s ON l.id_locuinta = s.id_locuinta
        JOIN rezervare r ON s.id_rezervare = r.id_rezervare
        LEFT JOIN tipuri_locuinte tip ON tip.id_tip = l.id_tip
        LEFT JOIN tarife t ON tip.id_tarif = t.id_tarif
        LEFT JOIN are a ON l.id_locuinta = a.id_locuinta
        LEFT JOIN dotari d ON a.id_dotare = d.id_dotare
        WHERE TO_CHAR(r.data_inceput, 'YYYY') = year
        GROUP BY l.id_gazda
        ORDER BY venit_total DESC
        FETCH FIRST 3 ROWS ONLY 
    ) LOOP
     
        venit_gazda := rec.venit_total;

 
        SELECT nume, prenume INTO nume_gazda, prenume_gazda
        FROM gazda
        WHERE id_gazda = rec.id_gazda;

       
        FOR locuinta IN (
            SELECT l.id_locuinta, l.nume_locuinta
            FROM locuinta l
            JOIN se_asociaza_la s ON l.id_locuinta = s.id_locuinta
            JOIN rezervare r ON s.id_rezervare = r.id_rezervare
            WHERE l.id_gazda = rec.id_gazda
              AND TO_CHAR(r.data_inceput, 'YYYY') = year
        ) LOOP
           
            locuinte_rezervate.EXTEND;
            locuinte_rezervate(locuinte_rezervate.COUNT) := record_locuinta(
                locuinta.id_locuinta,
                locuinta.nume_locuinta,
                0 
            );
        END LOOP;

       
        gazde.EXTEND;
        gazde(gazde.COUNT) := record_gazda(
            rec.id_gazda,
            venit_gazda,
            nume_gazda,
            prenume_gazda,
            locuinte_rezervate 
        );

        locuinte_rezervate.DELETE;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Top 3 gazde pentru anul ' || year || ':');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------');
    FOR i IN 1..LEAST(3, gazde.COUNT) LOOP
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE(i||'.Gazda ID: ' || gazde(i).id_gazda ||
                             ', Nume: ' || gazde(i).nume_gazda || ' ' || gazde(i).prenume_gazda ||
                             ', Venit total: ' || gazde(i).venit_total);

        DBMS_OUTPUT.PUT_LINE('Locuinte rezervate:');
        FOR j IN 1..gazde(i).locuinte_rezervate.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('  Locuinta ID: ' || gazde(i).locuinte_rezervate(j).id_locuinta ||
                                 ', Nume locuinta: ' || gazde(i).locuinte_rezervate(j).nume_locuinta);
        END LOOP;
    END LOOP;
END top3Gazde;


END pachetEx13;
/



BEGIN
    DBMS_OUTPUT.PUT_LINE('Venitul lunar pentru iulie 2024: ' || pachetEx13.calculVenitLunar('July', '2024'));
END;
/



BEGIN
    DBMS_OUTPUT.PUT_LINE('Venitul anual pentru 2024: ' || pachetEx13.calculVenitAnual('2024'));
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Venitul anual pentru 2020: ' || pachetEx13.calculVenitAnual('2020'));
END;
/
BEGIN 
    pachetEx13.raportAnual('2024');
END;
/


BEGIN 
    pachetEx13.raportRezervariAn('2024');
END;
/


BEGIN 
    pachetEx13.top3Gazde('2024');
END;
/



select * 
from locuinta;



