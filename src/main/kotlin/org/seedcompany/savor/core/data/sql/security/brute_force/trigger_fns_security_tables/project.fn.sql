-- trigger function that runs on insert on security tables
-- have access to new.__person_id and new.__id and table_name (TG_TABLE_NAME) and schema (TG_TABLE_SCHEMA)
create or replace function get_project_access_level(p_schema_name text)
returns void
language plpgsql
as $$
declare 
	security_schema_table text;
    base_schema_table text; 
    rec1 record;
    rec2 record;
    rec3 record;
    project_column text;
    security_table_column text;
    current_access_level public.access_level;
begin
        security_schema_table := quote_ident(TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME);
        -- public.locations_security
        base_schema_table := replace(security_schema_table, '_security', '_data');
        -- public.locations_data

        raise info 'security_table: % | base_table: %', security_schema_table, base_schema_table;

        if base_schema_table = 'public.locations_data' then 
            project_column := primary_location_id; 
        elif base_schema_table = 'public.organizations_data' then 
            project_column := primary_org_id; 
        end if;

        
        for rec1 in execute format('select id from public.projects_data where '|| project_column ||  
        ' = ' || quote_literal(new.__id)) loop 
	        raise info 'rec1: %', rec1;

            for rec2 in (select project_role_id from public.project_member_roles_data where person_id = new.__person_id and project_id = rec1.id) loop 
                raise info 'rec2: %', rec2;

                for rec3 in (select column_name, access_level from public.project_role_grants where table_name = base_schema_table  and project_role_id = rec2.project_role_id) loop
                    raise info 'rec3: %', rec3;

                    security_table_column := '_' || rec3.column_name;
                    
                    execute format('select ' || rec3.column_name || ' from ' || security_schema_table || ' where __id = ' || new.__id || ' and __person_id = '|| new.__person_id) into current_access_level;


                    if current_access_level is null or current_access_level = 'Read' then 
                        
                        execute format('update '|| security_schema_table || ' set '|| security_table_column ' = ' rec3.access_level || ' where __id = '|| new.__id 
                        || ' and __person_id = ' || new.__person_id );
                    
                    end if; 

                end loop;
            end loop;
         end loop;

        raise info 'done';
end; $$