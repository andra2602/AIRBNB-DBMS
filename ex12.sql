--Managerii platformei doresc sa implementeze un mecanism de protectie si audit pentru baza de date,astfel incat stergea anumitor tabele sa fie prevenita.
--Toate incercarile de stergere a acelor tabele protejate vor fi monitorizate intr-o tabela de audit care va contine informatii precum:
--utilizatorul care a incercat sa dea drop
--ora si data la care a incercat
--tabelul pe care a vrut sa l stearga

--Tabelele care vrem sa fie protejate sunt 'DISCOUNT_U_AUDIT', 'REZERVARI_AUDIT', 'ERORI', 'TEST'

--========TABELA AUDIT========--
create sequence seq_audit_drop
increment by 1
start with 1
nocycle;

create table audit_drop(
    id_audit number,
    utilizator varchar2(60),
    data_incercare timestamp,
    tabel varchar2(30)
);

----=======LISTA TABELE PROTEJATE IN VARRAY========-------
create or replace type tabele_protejate as varray(10) of varchar2(30);
/

create or replace trigger trig_ex12
before drop on schema
declare
    tab varchar2(30);
    tabele_protej tabele_protejate := tabele_protejate('DISCOUNT_U_AUDIT', 'REZERVARI_AUDIT', 'ERORI');
begin
    tab := sys.dictionary_obj_name;
    
    for i in 1..tabele_protej.count loop
        if upper(tab) = upper(tabele_protej(i)) then
            -- Înregistreaza încercarea în tabelul de audit
            insert into audit_drop values (seq_audit_drop.nextval, 
                                           SYS_CONTEXT('USERENV','SESSION_USER'), 
                                           systimestamp, 
                                           tab);
            -- Afiseaza mesajul si ridica o eroare pentru a preveni stergerea
            dbms_output.put_line('Stergerea tabelului ' || tab || ' este interzisa deoarece este un tabel protejat!');
            raise_application_error(-20001, 'Stergerea tabelului ' || tab || ' este interzisa!');
        end if;
    end loop;
end;
/



create table test(
    id number,
    nume varchar2(100)
)

insert into test values(2,'abc');

select * from test;

drop table test;



drop table discount_u_audit;

select *
from discount_u_audit;

select *
from audit_drop;
