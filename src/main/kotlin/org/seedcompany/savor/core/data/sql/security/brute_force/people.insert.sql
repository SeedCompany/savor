-- trigger function on insert for public.people
create or replace function public.insert_person_to_security()
returns trigger
language plpgsql
as $$
declare 
	rec1 record;
    rec2 record;
    base_schema_table_name text;
    security_schema_table_name text;
    row_sensitivity_clearance boolean;
begin
    -- execute format('set schema '|| quote_literal(TG_ARGV[0]));

	for rec1 in (select table_name from information_schema.tables where table_schema = TG_ARGV[0] and table_name like '%_data' order by table_name) loop 

        raise info 'table_name: %', rec1.table_name;
        base_schema_table_name := TG_ARGV[0] || '.' || rec1.table_name;

        if base_schema_table_name != 'public.people_data' then 

            for rec2 in execute format('select id from '|| base_schema_table_name) loop 

                raise info 'people.insert.fn rec2: %', rec2;

                select public.get_sensitivity_clearance(rec2.id, new.id, new.sensitivity_clearance, TG_ARGV[0], rec1.table_name) into row_sensitivity_clearance;
                security_schema_table_name := replace(base_schema_table_name, '_data', '_security');
                raise info 'security_schema_table_name: %', security_schema_table_name;
                execute format('insert into '|| security_schema_table_name || '(__id, __person_id, __is_cleared) values (' || rec2.id || ',' || new.id || ',' || row_sensitivity_clearance || ')' );

            end loop;

        end if;
    end loop;
    raise info 'done';
	return new;
end; $$;

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