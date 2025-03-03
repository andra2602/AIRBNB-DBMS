--2.Managerii platformei doresc sa genereze un raport cu privire la veniturile totale obtinute in urma rezervarilor pe categorii de locuinte
--,pentru un anumit an care este introdus de la tastatura.De asemenea dupa ce este precizata categoria impreuna cu venitul total pe anul respectiv
--se vor afisa locuintele din acea categorie care au inregistrat venit in anul respectiv,specificandu-l.
--Pentru a rezolva acest raport ,managerii doresc sa foloseasca un subprogram stocat
--independent,in cadrul caruia se utilizeaza 2 tipuri de cursoare,unul dintre ele fiind parametrizat,dependent de primul cursor.
--Totodata sa se gestioneze erorile care pot aparea in urma specificarii anului pentru care se doreste realizarea raportului.

--cursor static => selecteaza categoriile distincte de locuinte 
-- cursor parametrizat => selecteaza locuintele cu venitul lor daca fac parte din acea categorie si au rezervari in anul dat
--cursor dinamic => selecteaza si calculeaza venituri;e obtinute 

create or replace procedure raport_venituri_pe_categorii (p_an in varchar2) is
    -- cursor static pentru selectarea categoriilor distincte
    cursor c_categorii is
        select nume_tip
        from tipuri_locuinte;

    venituri sys_refcursor;
    
    --cursor parametrizat pentru locatii care fac parte din categoria respectiva
    cursor c_locuinta (p_categ varchar2,p_an number) is
        select l.nume_locuinta, sum(r.numar_persoane * t.pret_per_persoana) as venit_locatie
        from rezervare r
        join se_asociaza_la s on s.id_rezervare = r.id_rezervare
        join locuinta l on s.id_locuinta = l.id_locuinta
        join tipuri_locuinte tip on tip.id_tip = l.id_tip
        join tarife t on t.id_tarif = tip.id_tarif
        where tip.nume_tip = p_categ 
        and extract(year from r.data_inceput) = p_an
        and s.status = 'activa'
        group by l.nume_locuinta; 

    categ_cur varchar2(50);
    venit_total number;
    an_valid number;
    nume_loc varchar2(100);
    venit_loc number;
    null_error exception;
    value_error7 exception;
    
begin
    if p_an is null then
        raise null_error;
    end if;

    if not regexp_like(p_an, '^\d+$') then
        raise value_error7;
    end if;
    
    an_valid := to_number(p_an);
    
    dbms_output.put_line('Raport venituri pentru anul ' || an_valid || ':');
    dbms_output.put_line('===========================================');

    -- parcurgere cursor static
    for i in c_categorii loop
        categ_cur := i.nume_tip;

        open venituri for
            'select sum(r.numar_persoane* t.pret_per_persoana) 
             from rezervare r
             join se_asociaza_la s on s.id_rezervare = r.id_rezervare
             join locuinta l on s.id_locuinta = l.id_locuinta
             join tipuri_locuinte tl on tl.id_tip = l.id_tip
             join tarife t on t.id_tarif = tl.id_tarif
             where tl.nume_tip = :cat and extract(year from r.data_inceput) = :an'
            using categ_cur, an_valid;

        fetch venituri into venit_total;
        close venituri;

        if venit_total is not null then
            dbms_output.put_line('Categorie: ' || categ_cur || ' - venit total: ' || venit_total || ' lei');
            dbms_output.put_line('');
        else
            dbms_output.put_line('Categorie: ' || categ_cur || ' - venit total: 0 lei');
            dbms_output.put_line('');
        end if;
        
         for j in c_locuinta(categ_cur,an_valid) loop
                nume_loc  := j.nume_locuinta;
                venit_loc := j.venit_locatie;
                dbms_output.put_line('     Locuinta: ' || nume_loc || ' - venit total: ' || nvl(venit_loc, 0) || ' lei');
                dbms_output.put_line('');
        end loop;        
        
    end loop;
    dbms_output.put_line('===========================================');
exception
    when null_error then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'Parametrul p_an nu poate fi NULL!', 'raport_venituri_pe_categorii');
        dbms_output.put_line('Parametrul p_an nu poate fi NULL!');
    when value_error7 then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'Valoarea parametrului este gresita!!!', 'raport_venituri_pe_categorii');
        dbms_output.put_line('Valoarea parametrului este gresita');
    when others then
            insert into erori (id_eroare, mesaj, unde_apare)
            values (seq_erori.nextval, 'A aparut o eroare neasteptata!', 'raport_venituri_pe_categorii');
            dbms_output.put_line('A aparut o eroare neasteptata!');
       
end raport_venituri_pe_categorii;
/


DECLARE
    an varchar2(20) := '&an_tastatura';
BEGIN
  raport_venituri_pe_categorii(an);
END;
/


--apel in bloc anonim
BEGIN
    raport_venituri_pe_categorii(2024);
END;
/

BEGIN
    raport_venituri_pe_categorii(NULL);
END;
/

BEGIN
    raport_venituri_pe_categorii('abc');
END;
/
BEGIN
    raport_venituri_pe_categorii('');
END;
/
BEGIN
    raport_venituri_pe_categorii(2019);
END;
/
BEGIN
    raport_venituri_pe_categorii('202a');
END;
/

--sql plus apel

EXECUTE raport_venituri_pe_categorii(2019);

select *
from erori;

