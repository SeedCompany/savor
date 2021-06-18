create or replace function refresh_security(p_schema_name text)
returns void
language plpgsql
as $$
declare 
security_schema_table text;
rec1 record;  
begin
    
    for rec1 in (select table_name from information_schema.tables where table_schema = p_schema_name
                and table_name like '%_security' order by table_name) loop 

        for rec2 in (select __id, __person_id from rec1.table_name) loop 
            
            -- get project role access and global role access and update the access level 
            -- with the highest grant


        end loop;
    end loop;

end; $$