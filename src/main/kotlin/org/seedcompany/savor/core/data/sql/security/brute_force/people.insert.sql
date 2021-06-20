-- trigger function on insert for public.people
create or replace function insert_person_to_security()
returns trigger
language plpgsql
as $$
declare 
	rec1 record;
    rec2 record;
    security_table_name text;
begin
    execute format('set schema '|| quote_literal(TG_ARGV[0]));

	for rec1 in (select table_name from information_schema.tables where table_schema = TG_ARGV[0] and table_name like '%_data' order by table_name) loop 

        raise info 'table_name: %', rec1.table_name;

        for rec2 in execute format('select id from '|| rec1.table_name) loop 

            security_table_name := replace(rec1.table_name, '_data', '_security');
			raise info 'security_table_name: %', security_table_name;
            execute format('insert into '|| security_table_name || '(__id, __person_id) values (' || rec2.id || ',' || new.id || ')' );

        end loop;
    end loop;
    raise info 'done';
	return new;
end; $$

drop trigger if exists insert_people_public_security_trigger on public.people_data;
drop trigger if exists insert_people_sc_security_trigger on public.people_data;


create trigger insert_people_public_security_trigger 
after insert 
on public.people_data
for each row 
execute procedure public.insert_person_to_security('public');

create trigger insert_people_sc_security_trigger 
after insert 
on public.people_data
for each row 
execute procedure public.insert_person_to_security('sc');