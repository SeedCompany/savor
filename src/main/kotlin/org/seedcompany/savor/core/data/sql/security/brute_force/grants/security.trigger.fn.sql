create or replace function get_access_level_for_new_security_row()
returns triggers
language plpgsql 
as $$
declare
rec1 record; 
base_table_name text;
base_schema_table text;
global_access_level public.access_level;
project_access_level public.access_level;
final_access_level public.access_level;
begin

    base_table_name := replace(TG_TABLE_NAME, '_security', '_data');
    base_schema_table_name := TG_TABLE_SCHEMA || '.' || base_table_name;

    -- find access level for every column of the newly inserted record

    for rec1 in (select cast(column_name as text) from information_schema.columns where table_schema = TG_TABLE_SCHEMA and table_name = base_table_name)
        
        select public.get_global_access_level( new.__person_id, base_schema_table_name , rec1.column_name) into global_access_level;
               

        if base_schema_table_name = 'public.locations_data' or base_schema_table_name = 'public.organizations_data' then
            select public.get_project_access_level(new.__id, new.__person_id 
            , base_schema_table_name, rec1.column_name) into project_access_level;
        end if;

        if project_access_level = 'Write' then 
            final_access_level := 'Write';
        elsif project_access_level = 'Read' and global_access_level != 'Write' then
            final_access_level := 'Read';
        else 
            final_access_level := global_access_level;
        end if;

        raise info 'refresh fn global_access_level: % | project_access_level: % | final_access_level: %', global_access_level, project_access_level, final_access_level;
        

        if final_access_level is not null then 
            security_column_name := '_' || rec1.column_name;
            execute format('update '||security_schema_table_name||' set '||security_column_name|| ' = ' 
                || quote_literal(final_access_level) || ' where __id = '|| new.__id  
                || 'and  __person_id = ' ||  new.__person_id );
        end if;


    end loop; 

end;$$;