--Sa se defineasca un subprogram stocat independent care pentru o regiune si o perioada transmisa ca parametru gaseste toate locuintele ,
--iar pentru fiecare locuinta care este disponibila se afiseaza lista cu dotari.In cazul in care perioada specificata se suprapune cu 
--o rezervare deja existenta care este activa se va afisa un mesaj corespunzator.

--lista locuinte => tablou indexat
--istoricul de rezervari ale locuintei =>  tabele nested care retin perioada prin ata start-data final
--dotarile =>varray


create or replace procedure loc_disponibile(
                            p_regiune IN regiuni.nume_regiune%type,
                            perioada_start IN date,
                            perioada_stop  IN date) is
    type tablou_index_loc is table of locuinta.nume_locuinta%type index by pls_integer;
    lista_locuinte tablou_index_loc;
    
    type tablou_nested_rezervari is table of varchar2(50);
    istoric_rezervari_start tablou_nested_rezervari;
    istoric_rezervari_sfarsit tablou_nested_rezervari;
    
    type dot is varray(26) of dotari.nume%type;
    lista_dotari dot;
    
    ok boolean;
    nr number :=0;
    
begin
--locuintele din regiunea transmisa ca parametru
    for rec in (select l.id_locuinta, l.nume_locuinta
                from locuinta l
                join locatie loc on l.id_locatie = loc.id_locatie
                join tari t on loc.id_tara = t.id_tara
                join regiuni reg on reg.id_regiune = t.id_regiune
                where reg.nume_regiune = p_regiune) loop
        lista_locuinte(rec.id_locuinta) := rec.nume_locuinta;
    end loop;
    
    dbms_output.put_line('Locuintele gasite in regiunea '|| p_regiune ||': ');
    dbms_output.put_line('');
    nr := 0;
    for i in lista_locuinte.first..lista_locuinte.last loop
        if lista_locuinte.exists(i) then
            nr := nr+1;
            dbms_output.put_line(nr ||'. '||lista_locuinte(i));
            
            istoric_rezervari_start := tablou_nested_rezervari();
            istoric_rezervari_sfarsit := tablou_nested_rezervari();
            --pt fiecare locuinta gasita perioadele in care e rezervata 
            for aux in(
                    select r.data_inceput,r.data_sfarsit
                    from rezervare r
                    join se_asociaza_la aux on aux.id_rezervare = r.id_rezervare
                    where aux.id_locuinta = i
                    and aux.status = 'activa' ) loop
                istoric_rezervari_start.extend;
                istoric_rezervari_sfarsit.extend;
                istoric_rezervari_start(istoric_rezervari_start.last) := aux.data_inceput;
                istoric_rezervari_sfarsit(istoric_rezervari_sfarsit.last) := aux.data_sfarsit;
            end loop;
            
            ok := true;
            
            if istoric_rezervari_start.count = 0 then
                dbms_output.put_line('Locuinta '|| lista_locuinte(i)||' este disponibila in perioada introdusa: '|| perioada_start||' / '|| perioada_stop);
                
                lista_dotari := dot();
                
                select d.nume 
                bulk collect into lista_dotari
                from dotari d
                join are a on d.id_dotare = a.id_dotare
                where a.id_locuinta = i;
                  
                if lista_dotari.count <> 0 then
                    dbms_output.put_line('Dotarile disponibile ale acestei locuinte sunt: ');
                    for d_index in 1..lista_dotari.count loop
                        dbms_output.put_line('   - '|| lista_dotari(d_index));
                    end loop;
                    DBMS_OUTPUT.PUT_LINE('');

                    dbms_output.put_line('=================================================');
                    DBMS_OUTPUT.PUT_LINE('');

                    
                else
                    dbms_output.put_line('Nu s-au gasit dotari pentru aceasta locuinta.');
                    DBMS_OUTPUT.PUT_LINE('');

                    dbms_output.put_line('=================================================');
                    DBMS_OUTPUT.PUT_LINE('');

                end if;
            else
                for j in 1 .. istoric_rezervari_start.count loop
                        if istoric_rezervari_start(j) <= perioada_stop and istoric_rezervari_sfarsit(j) >= perioada_start then
                            ok := false;
                            dbms_output.put_line('Perioada selectata se suprapune deja cu o rezervare.E posibil sa nu mai avem locuri.');
                            
                            DBMS_OUTPUT.PUT_LINE('');

                            dbms_output.put_line('=================================================');
                            DBMS_OUTPUT.PUT_LINE('');

                        end if;
                end loop;
                if ok = true then
                    dbms_output.put_line('Locuinta '|| lista_locuinte(i)||' este disponibila in perioada introdusa: '|| perioada_start||'-'|| perioada_stop);
                    lista_dotari := dot();
                
                    for dotari_rec in(select d.nume
                                        from dotari d
                                        join are a on d.id_dotare = a.id_dotare
                                        where a.id_locuinta = i) loop
                        lista_dotari.extend;
                        lista_dotari(lista_dotari.last) := dotari_rec.nume;
                        end loop;
                    if lista_dotari.count <> 0 then
                        dbms_output.put_line('Dotarile disponibile ale acestei locuinte sunt: ');
                        for d_index in 1..lista_dotari.count loop
                            dbms_output.put_line('   - '|| lista_dotari(d_index));
                        end loop;
                        DBMS_OUTPUT.PUT_LINE('');

                        dbms_output.put_line('=================================================');
                        DBMS_OUTPUT.PUT_LINE('');

                    else
                        dbms_output.put_line('Nu s-au gasit dotari pentru aceasta locuinta.');
                        DBMS_OUTPUT.PUT_LINE('');
                        dbms_output.put_line('=================================================');
                        DBMS_OUTPUT.PUT_LINE('');
                    end if;
                end if;
            end if;
        end if;
    end loop;
                
end loc_disponibile;


begin
    loc_disponibile(
        p_regiune => 'Europa de Est',
        perioada_start => TO_DATE('09/11/2005', 'dd/mm/yyyy'),
        perioada_stop => TO_DATE('11/11/2005', 'dd/mm/yyyy')
    );
end;
/


begin
    loc_disponibile(
        p_regiune => 'Europa de Est',
        perioada_start => TO_DATE('23/03/2023', 'dd/mm/yyyy'),
        perioada_stop => TO_DATE('24/03/2023', 'dd/mm/yyyy')
    );
end;
/