--Se doreste implementarea unui mecanism de audit pentru tabela de rezervari prin intermediul caruia sa se monitorizeze schimbarile care se fac asupra 
--acestei tabele.Detaliile care sunt retiunte sunt detalii precum : tipul de comanda,user ul care a efectuat-o,data si numarul de randuri afectate
--din interiorul tabelei

create sequence seq_audit_r
increment by 1
start with 1
nocycle;

create table rezervari_audit(
    id_audit number,
    comanda varchar2(15),
    utilizator varchar2(40),
    data_comanda timestamp default current_timestamp,
    randuri_afectate number
);

drop table rezervari_audit;
drop sequence seq_audit_r;

create or replace trigger trig_ex10
    after insert or update or delete on rezervare
declare
    nr_randuri number := 0;
    t_comanda varchar2(15);
begin
    if INSERTING then
        t_comanda := 'INSERT';
        select count(*) into nr_randuri
        from rezervare
        where rowid in (select rowid from rezervare);
    elsif UPDATING then
        t_comanda := 'UPDATE';
        select count(*) into nr_randuri
        from rezervare
        where rowid in (select rowid from rezervare);
    elsif DELETING then
        t_comanda := 'DELETE';
        select count(*) into nr_randuri
        from rezervare;
    end if;
    
    insert into rezervari_audit 
    values (seq_audit_r.nextval, t_comanda, sys_context('USERENV','SESSION_USER'), systimestamp ,nr_randuri);
end;
/



create or replace trigger trig_ex10
    after insert or update or delete on rezervare
declare
    nr_randuri number := 0;
    t_comanda varchar2(15);
begin
    if INSERTING then
        t_comanda := 'INSERT';
        nr_randuri:= sql%rowcount;
    elsif UPDATING then
        t_comanda := 'UPDATE';
        nr_randuri:= sql%rowcount;
    elsif DELETING then
        t_comanda := 'DELETE';
        nr_randuri:= sql%rowcount;
    end if;
    
    insert into rezervari_audit 
    values (seq_audit_r.nextval, t_comanda, sys_context('USERENV','SESSION_USER'), systimestamp ,nr_randuri);
end;
/


insert into rezervare values (seq_rezervare.nextval,107,to_date('22/12/2024','dd/mm/yyyy'),to_date('25/12/2024','dd/mm/yyyy'),5,'pos');
insert into rezervare values (seq_rezervare.nextval,108,to_date('25/01/2025','dd/mm/yyyy'),to_date('25/02/2025','dd/mm/yyyy'),4,'pos');
                
desc rezervare;

update rezervare
set numar_persoane = 10
where modalitate_plata = 'pos';

delete from rezervare
where modalitate_plata = 'pos';

select *
from rezervari_audit;



select *
from rezervare;


insert into rezervare (id_rezervare,id_utilizator,data_inceput,data_sfarsit,numar_persoane,modalitate_plata) values
            (seq_rezervare.nextval,107,to_date('22/12/2024','dd/mm/yyyy'),to_date('25/12/2024','dd/mm/yyyy'),5,'pos'),
            (seq_rezervare.nextval,108,to_date('25/01/2025','dd/mm/yyyy'),to_date('25/02/2025','dd/mm/yyyy'),4,'pos');