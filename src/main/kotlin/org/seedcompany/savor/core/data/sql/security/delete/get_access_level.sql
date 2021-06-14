create or replace function get_access_level(p_person_id int, p_table_name table_name, p_column_name varchar(255))
returns access_level 
language PLPGSQL
as $$
declare
entries_count_for_person int;
security_table_name text;
rec1 record;
rec2 record;
begin 
	p_column_name := '_' || p_column_name;
    security_table_name := p_table_name || '_security';
    execute format('select count(*) from ' || quote_ident(security_table_name) ||' where __sys_person_id = '||p_person_id) into entries_count_for_person;
	
        if entries_count_for_person = 0 then
            

        end if;
end; $$; 

