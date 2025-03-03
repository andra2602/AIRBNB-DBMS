select *
from rezervare;

select *
from utilizator;

--Pentru rezolvarea acestui exercitiu adaugati coloana de discount in tabela utilizator.
--Sa se defineasca un trigger care va actualiza automat campul de discount adaugat in tabela de utilizator atunci cand se inregistreaza o noua rezervare 
--ascoiata cu un utilizator,cand se adauga un utilizator nou in baza de date sau cand se modifica datele unei rezervari (data,numar persoane).
--Acest discount este calculat in functie de numarul total de zile rezervate de utilizatori.
--Toate aceste actiuni vor avea detaliile stocate intr-o tabela de audit ce va retine: id_ul utilizatorului,discount vechi/nou,
--data/ora modificarii.

--========TABELA AUDIT========--
create sequence seq_audit_u
increment by 1
start with 1
nocycle;

create table discount_u_audit(
    id_audit number,
    id_utilizator number,
    old_discount number,
    new_discount number,
    data_modificare timestamp
);

--=======MODIFICARE TABELA UTILIZATOR=======--
alter table utilizator add (discount number);



select *
from utilizator;

update utilizator
set discount = 0;


--=======TRIGGER=======--

create or replace trigger trig_ex11
before update or insert on utilizator
for each row
declare
    durata_rezervari number := 0;
    discount_actual number;
    discount_vechi number;

begin

    select nvl(sum(r.data_sfarsit-r.data_inceput),0) into durata_rezervari
    from rezervare r
    join se_asociaza_la s on r.id_rezervare = s.id_rezervare
    where id_utilizator = :new.id_utilizator
    and s.status = 'activa';
    
    if durata_rezervari between 10 and 25 then
        discount_actual := 5; --5 la suta
    elsif durata_rezervari between 26 and 50 then
        discount_actual := 10; --10 la suta
    elsif durata_rezervari > 50 then
        discount_actual := 20;
    else 
        discount_actual := 0;
    end if;

    discount_vechi := :new.discount;
    
    if (discount_actual <> discount_vechi) or (discount_vechi is null) then
        :new.discount := discount_actual;
        
        insert into discount_u_audit values (seq_audit_u.nextval,:new.id_utilizator,discount_vechi,discount_actual,systimestamp);
    
    end if;
end;
/

select *
from utilizator;

select *
from rezervare;

insert into utilizator (id_utilizator,nume,prenume,email,data_inregistrare,telefon,gen,data_nasterii)
values(seq_utilizator.nextval,'Tunaru','Alexandra','alex.test@gmail.com',to_date('20/10/2024','dd/mm/yyyy'),null,'feminin',to_date('10/03/2005','dd/mm/yyyy'));

update utilizator
set discount = discount
where id_utilizator = 123;


insert into rezervare values (seq_rezervare.nextval,108,to_date('25/01/2025','dd/mm/yyyy'),to_date('25/03/2025','dd/mm/yyyy'),4,'pos');
update utilizator
set discount = discount
where id_utilizator = 108;

delete from utilizator
where nume = 'Tunaru';


update utilizator
set discount = discount
where id_utilizator in(select id_utilizator 
                        from utilizator);


insert into utilizator (id_utilizator,nume,prenume,email,data_inregistrare,telefon,gen,data_nasterii)
values(seq_utilizator.nextval,'Sandu','Robert','sandu.test@gmail.com',to_date('05/10/2024','dd/mm/yyyy'),null,'masculin',to_date('03/03/2005','dd/mm/yyyy'));



select * from utilizator;

select *
from discount_u_audit;