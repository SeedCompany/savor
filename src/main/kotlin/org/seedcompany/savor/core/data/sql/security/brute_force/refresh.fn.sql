create or replace function refresh_security_tables(p_schema_name text)
returns void
language plpgsql
as $$
declare 
security_schema_table text;
rec1 record;
rec2 record;
rec3 record;
global_access_level access_level;
project_access_level access_level;
base_schema_table_name text;
security_schema_table_name text;     
begin
    
    for rec1 in (select table_name from information_schema.tables where table_schema = p_schema_name and table_name like '%_security' order by table_name) loop 
        security_schema_table_name := p_schema_name || rec1.table_name;
        base_schema_table_name := replace(security_schema_table_name, '_security', '_data');

        for rec2 in (select column_name from information_schema.tables 
                    where table_schema = p_schema_name and table_name like '%_security' 
                    order by table_name) loop
                
            for rec3 in execute format('select __id, __person_id from '|| rec1.table_name) loop

                select get_global_access_level( rec3.__person_id, base_schema_table_name 
                , rec2.column_name) into global_access_level;

                select get_project_access_level(rec3.__id, rec3.__person_id 
                , base_schema_table_name, rec2.column_name) into project_access_level;

                

            end loop;
        end loop;
    end loop;

end; $$