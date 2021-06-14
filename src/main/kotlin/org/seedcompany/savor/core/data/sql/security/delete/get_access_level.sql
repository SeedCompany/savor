create or replace function get_access_level(p_person_id int, p_table_name table_name, p_column_name varchar(255))
returns access_level 
language PLPGSQL
as $$
declare
entries_count_for_person int;
security_table_name text;
new_access_level text;
rec1 record;
rec2 record;
begin 
    security_table_name := p_table_name || '_security';
	raise info '%, %, %', p_person_id, p_table_name, p_column_name;
    execute format('select count(*) from ' || quote_ident(security_table_name) ||' where __sys_person_id = '||p_person_id) into entries_count_for_person;
	
        if entries_count_for_person != 0 then

            for rec1 in (select * from sys_role_memberships where sys_person_id = p_person_id) loop 
				raise info 'rec1: %', rec1;
                for rec2 in (select * from sys_role_grants where sys_role_id = rec1.sys_role_id and table_name = p_table_name and column_name = p_column_name) loop 
            			raise info 'rec2: %', rec2;
                        if new_access_level is null or new_access_level = 'Read' then
                            new_access_level := rec2.access_level; 
                        end if;

                end loop;
            end loop;
            
        end if;
        raise info '%', new_access_level;
        return new_access_level;
end; $$; 