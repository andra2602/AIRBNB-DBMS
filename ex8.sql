create sequence seq_erori
increment by 1
start with 1
nocycle;

create table erori (
    id_eroare number constraint pk_eroare primary key,
    mesaj varchar2(500),
    data_ora timestamp default current_timestamp,
    unde_apare varchar2(100)    
)

--===========================================================
--Sa se realizeze un program stocat independent de tip functie care primeste ca parametru numele unei tari si care returneaza valoarea maxima
--care a fost inregistrata pentru o rezervare in tara respectiva,indiferente de locatie.Daca exista o astfel de valoare,impreuna cu ea se vor 
--afisa numele utilizatorului,id-ul rezervarii si locuinta pe care a fost facuta.
--Sa se trateze exceptiile care pot aparea.
--Exceptii care pot aparea:
--1.tara nu exista in bd
--2.nu s-au gasit rezervari in tara respectiva
--3.cel putin 2 rezervari din tara respectiva au aceeasi valoare
--4.s-a introdus o val gresita de la tastatura-gen numar
--===========================================================
desc locuinta;
create or replace type info_rezervare_record as object(
    val_max number,
    nume_utilizator varchar2(30),
    prenume_utilizator varchar2(30),
    id_rezervare number,
    nume_loc varchar2(30)
);

create or replace function rezervare_maxima (tara_input tari.nume_tara%type) return info_rezervare_record is
    venit_max number := 0;
    nume_u_func utilizator.nume%type;
    prenume_u_func utilizator.prenume%type;
    rezerv rezervare.id_rezervare%type;
    loc_val locuinta.nume_locuinta%type; 
    numar_rezervari number := 0; 
    
    fara_rezervari exception;
begin
    if tara_input is null or length(trim(tara_input)) = 0 or regexp_like(tara_input, '^\d+$') then
        raise value_error; 
    end if;
    
    declare
        tara_exista number := 0;
    begin
        select count(*) into tara_exista
        from tari
        where lower(nume_tara) = lower(tara_input);

        if tara_exista = 0 then
            raise no_data_found; 
        end if;
        
    end;
    
    select count(*) into numar_rezervari 
    from rezervare r
    join se_asociaza_la s on s.id_rezervare = r.id_rezervare
    join locuinta l on l.id_locuinta = s.id_locuinta
    join locatie loc on l.id_locatie = loc.id_locatie
    join tari ta on ta.id_tara = loc.id_tara
    where s.status = 'activa'
    and lower(ta.nume_tara) = lower(tara_input);
    
    if numar_rezervari = 0 then 
        raise fara_rezervari;
    else
        select r.id_rezervare,l.nume_locuinta,max(t.pret_per_persoana*r.numar_persoane) into rezerv, loc_val, venit_max
        from rezervare r
        join se_asociaza_la s on s.id_rezervare = r.id_rezervare
        join locuinta l on l.id_locuinta = s.id_locuinta
        join tipuri_locuinte tip on tip.id_tip = l.id_tip
        join tarife t on t.id_tarif = tip.id_tarif
        join locatie loc on l.id_locatie = loc.id_locatie
        join tari ta on ta.id_tara = loc.id_tara
        where s.status = 'activa'
        and lower(ta.nume_tara) = lower(tara_input)
        group by l.nume_locuinta,r.id_rezervare;
    end if;
    
    if venit_max <> 0  then
        select u.nume,u.prenume into nume_u_func, prenume_u_func
        from utilizator u
        join rezervare r on u.id_utilizator = r.id_utilizator
        where r.id_rezervare = rezerv;
    end if;
        
    return info_rezervare_record(venit_max,nume_u_func,prenume_u_func,rezerv,loc_val);
    
exception
     when value_error then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'Valoarea parametrului este gresita!!!', 'rezervare_maxima');
        dbms_output.put_line('Valoarea parametrului este gresita');
        return info_rezervare_record(0, NULL, NULL, NULL, NULL);
    when fara_rezervari then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'In tara introdusa nu s-au inregistrat rezervari!!!', 'rezervare_maxima');
        dbms_output.put_line('In tara introdusa nu s-au inregistrat rezervari');
        return info_rezervare_record(0, NULL, NULL, NULL, NULL);
    when no_data_found then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'Nu s-a gasit tara in baza de date!', 'rezervare_maxima');
        dbms_output.put_line('Nu s-a gasit tara in baza de date!!!');
        return info_rezervare_record(0, NULL, NULL, NULL, NULL);
    when too_many_rows then
        insert into erori (id_eroare, mesaj, unde_apare)
        values (seq_erori.nextval, 'Sunt mai multe rezervari cu aceeasi valoare maxima!!!', 'rezervare_maxima');
        dbms_output.put_line('Sunt mai multe rezervari cu aceeasi valoare maxima!');
        return info_rezervare_record(0, NULL, NULL, NULL, NULL);    
end rezervare_maxima;
/

declare
    tara_test tari.nume_tara%type := '&p_tara';
    rezervare_test info_rezervare_record;
begin
    rezervare_test := rezervare_maxima(tara_test);
    
    dbms_output.put_line('======================================================');
    dbms_output.put_line('Tara: '|| tara_test);
    dbms_output.put_line('Valoare maxima: '|| rezervare_test.val_max);
    dbms_output.put_line('Nume utilizator: '|| rezervare_test.nume_utilizator ||' '|| rezervare_test.prenume_utilizator);
    dbms_output.put_line('Id-ul rezervarii: '|| rezervare_test.id_rezervare);
    dbms_output.put_line('Locuinta: '|| rezervare_test.nume_loc);
end;

insert into tari values('DK','Danemarca',4);




select *
from erori;

