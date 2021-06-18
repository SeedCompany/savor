-- trigger function on insert for public.people
create or replace function insert_person_to_security(p_schema_name text)
returns void
language plpgsql
as $$
declare 
	rec1 record;
    rec2 record;
    security_table_name text;
begin
    execute format('set schema '|| quote_literal(p_schema_name));

	for rec1 in (select table_name from information_schema.tables where table_schema = p_schema_name and table_name like '%_data' order by table_name) loop 

        raise info 'table_name: %', table_name;

        for rec2 in execute format('select id from '|| rec1.table_name) loop 

            security_table_name := rec1.table_name || '_security';
            execute format('insert into '|| security_table_name || '(__id, __person_id) values (' || rec2.id || ',' || new.id || ')' );

        end loop;
    end loop;
    raise info 'done';
end; $$