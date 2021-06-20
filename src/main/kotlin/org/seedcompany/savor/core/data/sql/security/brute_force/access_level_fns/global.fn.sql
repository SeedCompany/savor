create or replace function get_global_access_level(p_person_id int, p_table_name table_name, p_column_name varchar(255))
returns access_level
language plpgsql
as $$
declare 
    rec1 record;
    rec2 record;
    project_column text;
    new_access_level access_level;
begin


    for rec1 in (select id from public.global_role_memberships_data where person_id = p_person_id)loop 

        for rec2 in (select * from public.global_role_grants_data where table_name = p_table_name and column_name = p_column_name and role_id = rec1.role_id) loop 

            if new_access_level is null or new_access_level = 'Read' then 
                new_access_level := rec2.access_level; 
            end if;

        end loop;
    end loop; 
    
    return access_level;
end; $$