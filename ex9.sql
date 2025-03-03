-- Sa se realizeze un program stocat independent de tip procedura care sa determine mai multe informatii despre un utilizator-sub forma 
-- unei analize in functie de
-- numele acestuia (nume + prenume) si sa se analizeze comportamentul acestuia de rezervare.
-- Raportul trebuie sa includa:
-- 1.numarul de modalitati distincte de achitare a platii
-- 2.o lista cu tipurile de locuinte rezervate
-- 3. valoarea totala platita de acesta
-- 4. cel mai frecvent tip de locuinta inchirat
-- 5. perioada totala de inchiriere
-- 6. si categoria de utilizator in care e incadrat in functie de nr de rezervari efectuate
------ <2 utilizator bronze ---- 2,5 utilizator silver --------5,10 utilizator gold------- >10 utilizator premium
--In plus sa se gestioneze exceptiile care pot aparea.
desc tipuri_locuinte;

create or replace type tipuri_varray as varray(200) of varchar2(20);

create or replace type analiza_record as object(
    numar_modalitati number,
    lista_tipuri tipuri_varray,
    valoare_totala number,
    tip_frecvent varchar2(20),
    total_zile number,
    categorie_utilizator varchar2(50)   
);

create or replace procedure analiza_rezervari_utilizator(
                p_nume_utilizator in varchar2,
                p_prenume_utilizator in varchar2,
                p_analiza out analiza_record ) is
                
                
    --============exceptii proprii===============--
    
    ex_rezervari_active exception;

    ex_valoare_zero exception;
    
    ex_modalitate_invalida exception;
    
    --===========================================--
                
    cod_u utilizator.id_utilizator%type;
    numar_modalitati number := 0;
    lista_tipuri tipuri_varray := tipuri_varray();
    valoare_totala number := 0;
    tip_frecvent varchar2(50);
    total_zile number;
    categorie_utilizator varchar2(50);
    nr_rezerv number := 0;
    mod_plata_nedefinit number:=0;
    
    cursor c_tipuri is
        select distinct t.nume_tip
        from tipuri_locuinte t
        join locuinta l on l.id_tip = t.id_tip
        join se_asociaza_la s on l.id_locuinta = s.id_locuinta
        join rezervare r on s.id_rezervare = r.id_rezervare
        where r.id_utilizator = cod_u;
        
    cursor curs_frecventa is
        select t.nume_tip, count(*) as numar
        from tipuri_locuinte t
        join locuinta l on l.id_tip = t.id_tip
        join se_asociaza_la s on s.id_locuinta = l.id_locuinta
        join rezervare r on r.id_rezervare = s.id_rezervare
        where r.id_utilizator = cod_u
        group by t.nume_tip
        order by count(*) desc;
        
     c_frecv_rec curs_frecventa%rowtype;
    
begin
--iau id-ul util dupa numele dat ca parametru
    select id_utilizator  into cod_u
    from utilizator 
    where lower(nume) = lower(p_nume_utilizator) and lower(prenume) = lower(p_prenume_utilizator);
    
-- nr modalitatile lui de plata(le iau in calcul doar daca rezervarile au ramas active) si nr de rezervari facute  
    select count(distinct r.modalitate_plata) into numar_modalitati
    from rezervare r
    join se_asociaza_la s on r.id_rezervare = s.id_rezervare
    where r.id_utilizator = cod_u
    and s.status = 'activa';
    
    select count(*) into mod_plata_nedefinit
    from rezervare r
    join se_asociaza_la s on r.id_rezervare = s.id_rezervare
    where r.id_utilizator = cod_u
    and s.status = 'activa'
    and r.modalitate_plata not in ('cash', 'transfer', 'card');
    
    if mod_plata_nedefinit > 0 then 
        raise ex_modalitate_invalida;
    end if;
    
    select count(r.id_rezervare) into nr_rezerv
    from rezervare r
    where r.id_utilizator = cod_u;
    
--exceptie custom    
    if nr_rezerv = 0 then
        raise ex_rezervari_active;
    end if;
    
--determinare categ utilizator in functie de nr de r
    if nr_rezerv < 2 then
        categorie_utilizator := 'Utilizator BRONZE';
    elsif nr_rezerv between 2 and 5 then
        categorie_utilizator := 'Utilizator SILVER';
    elsif nr_rezerv between 5 and 10 then
        categorie_utilizator := 'Utilizator GOLD';
    else
        categorie_utilizator := 'Utilizator PREMIUM';
    end if;
    
    lista_tipuri := tipuri_varray();
-- lista de tipuri rezervate
    for c_rec in c_tipuri loop
        lista_tipuri.extend;
        lista_tipuri(lista_tipuri.last) := c_rec.nume_tip;
    end loop;
    
    if lista_tipuri.count = 0 then
    dbms_output.put_line('Nu exist? tipuri de locuin?e rezervate pentru utilizator.');
    end if;
    

-- valoare totala ->>>>>>>> 5 dintre tabelele create
    select nvl(sum(r.numar_persoane * t.pret_per_persoana), 0)
    into valoare_totala
    from rezervare r 
    join se_asociaza_la s on r.id_rezervare = s.id_rezervare
    join locuinta l on s.id_locuinta = l.id_locuinta
    join tipuri_locuinte tip on tip.id_tip = l.id_tip
    join tarife t on t.id_tarif = tip.id_tarif
    where r.id_utilizator = cod_u;
    
    if valoare_totala = 0 then
        raise ex_valoare_zero;
    end if;
    
-- tipul cel mai frecvent
    open curs_frecventa;
    fetch curs_frecventa into c_frecv_rec;
    if curs_frecventa%found then
        tip_frecvent := c_frecv_rec.nume_tip;
    else
        tip_frecvent := null;
    end if;
    close curs_frecventa;
    
-- nr zile
    select sum(data_sfarsit - data_inceput)
    into total_zile
    from rezervare
    where id_utilizator = cod_u;
    
    p_analiza := analiza_record(
    numar_modalitati,
    lista_tipuri, -- Atribuie colec?ia ini?ializat?
    valoare_totala,
    tip_frecvent,
    total_zile,
    categorie_utilizator
    );
    
exception
    when ex_rezervari_active then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'Utilizatorul exista,dar nu are sau nu a avut rezervari active.', 'analiza_rezervari_utilizator');
        dbms_output.put_line('Utilizatorul exista,dar nu are sau nu a avut rezervari active.');
    when ex_valoare_zero then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'Valoarea totala e zero,verificati tarifele si rezervarile.', 'analiza_rezervari_utilizator');
        dbms_output.put_line('Valoarea totala e zero,verificati tarifele si rezervarile.');
    when ex_modalitate_invalida then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'S-a inregistrat o modalitate invalida de plata,verificati inregistrarile.', 'analiza_rezervari_utilizator');
        dbms_output.put_line('S-a inregistrat o modalitate invalida de plata,verificati inregistrarile.');
    when no_data_found then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'Nu s-au gasit datele cautate!', 'analiza_rezervari_utilizator');
        dbms_output.put_line('Nu s-au gasit datele cautate');
    when too_many_rows then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'Exista mai multi utilizatori cu acelasi nume.Verificati baza de date.', 'analiza_rezervari_utilizator');
        dbms_output.put_line('Exista mai multi utilizatori cu acelasi nume.Verificati baza de date.');
    when others then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'A aparut o eroare neasteptata', 'analiza_rezervari_utilizator');
        dbms_output.put_line('A aparut o eroare neasteptata');
             
end analiza_rezervari_utilizator;
/



accept nume_u prompt 'Introduceti numele utilizatorului: ';
accept prenume_u prompt 'Introduceti prenumele utilizatorului: ';
declare
    v_analiza analiza_record;
    contor number :=0;
begin

    analiza_rezervari_utilizator(
        p_nume_utilizator => '&nume_u',
        p_prenume_utilizator => '&prenume_u',
        p_analiza => v_analiza
    );
    
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('ANALIZA PENTRU UTILIZATORUL: '||upper('&nume_u') || ' '|| upper('&prenume_u'));
    DBMS_OUTPUT.PUT_LINE('====================================================');
    DBMS_OUTPUT.PUT_LINE('Numar modalitati distincte de plata: ' || v_analiza.numar_modalitati);
    DBMS_OUTPUT.PUT_LINE('Valoare totala platita: ' || v_analiza.valoare_totala);
    DBMS_OUTPUT.PUT_LINE('Tipul frecvent inchiriat: ' || v_analiza.tip_frecvent);
    DBMS_OUTPUT.PUT_LINE('Total zile de inchiriere: ' || v_analiza.total_zile);
    DBMS_OUTPUT.PUT_LINE('Categorie utilizator: ' || v_analiza.categorie_utilizator);

    DBMS_OUTPUT.PUT_LINE('Tipuri de locuinte rezervate pana acum: ');
    contor := 0;
    
    IF v_analiza.lista_tipuri IS NOT NULL THEN
        IF v_analiza.lista_tipuri.COUNT > 0 THEN
            FOR i IN 1 .. v_analiza.lista_tipuri.COUNT LOOP
                DBMS_OUTPUT.PUT_LINE('Tip locuinta rezervata: ' || v_analiza.lista_tipuri(i));
            END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Nu exista tipuri de locuinte rezervate.');
        END IF;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Lista tipuri de locuin?e nu a fost ini?ializat?.');
    END IF;
end;
/




insert into utilizator (id_utilizator,nume,prenume,email,data_inregistrare,telefon,gen,data_nasterii)
values(seq_utilizator.nextval,'Sandu','Anastasia','ana.test@gmail.com',to_date('05/10/2024','dd/mm/yyyy'),null,'feminin',to_date('03/03/2005','dd/mm/yyyy'));

insert into utilizator (id_utilizator,nume,prenume,email,data_inregistrare,telefon,gen,data_nasterii)
values(seq_utilizator.nextval,'Dobrinoiu','Mari','dmari.test@gmail.com',to_date('10/10/2023','dd/mm/yyyy'),null,'feminin',to_date('12/03/1990','dd/mm/yyyy'));

insert into utilizator (id_utilizator,nume,prenume,email,data_inregistrare,telefon,gen,data_nasterii)
values(seq_utilizator.nextval,'Dobrinoiu','Mari','dmari2.test@gmail.com',to_date('09/10/2023','dd/mm/yyyy'),null,'masculin',to_date('15/06/1988','dd/mm/yyyy'));

insert into rezervare values (seq_rezervare.nextval,141,to_date('25/01/2025','dd/mm/yyyy'),to_date('25/03/2025','dd/mm/yyyy'),4,'pos');

select * from utilizator;
select * from rezervare;

select * from se_asociaza_la;

insert into se_asociaza_la values(250,1043,to_date('20/01/2025','dd/mm/yyyy'),'activa');

delete from rezervare
where  modalitate_plata = 'pos';



select * from erori;
