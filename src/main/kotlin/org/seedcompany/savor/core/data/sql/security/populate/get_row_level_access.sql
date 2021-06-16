-- just implement it for sys_locations_security for now and then generalise it. 
-- (main concern is how to replace rec2 -> primary_location_id = p_id) 
-- maybe switch case? 

-- the function checks the project roles and then returns the appropriate access level

-- a person might have access through projects or through global grants

create or replace function get_row_level_access(p_person_id int, p_id int, p_table_name table_name, p_column_name varchar(255))
returns access_level 
language PLPGSQL
as $$
declare
    rec1 record;
    rec2 record; 
    rec3 record;
    new_access_level access_level;
begin 

    for rec1 in (select * from sys_project_member_roles where person_id = p_person_id) loop 
        for rec2 in (select * from sys_projects where id = rec1.project_id and primary_location_id = p_id) loop 
            for rec3 in (select * from sys_project_role_grants where table_name = p_table_name and column_name  = p_column_name and project_role_id = rec1.project_role_id) loop

                 if new_access_level is null or new_access_level = 'Read' then
                            new_access_level := rec3.access_level; 
                end if;

            end loop;
        end loop;
    end loop;
    return new_access_level;
end; $$; 