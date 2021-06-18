-- trigger function that runs on insert on security tables
-- have access to new.__person_id and new.__id and table_name (TG_TABLE_NAME) and schema (TG_TABLE_SCHEMA)
create or replace function get_global_access_level(p_schema_name text)
returns void
language plpgsql
as $$
declare 
	security_schema_table text;
    base_schema_table text; 
    rec1 record;
    rec2 record;
    security_table_column text;
    current_access_level public.access_level;
begin
        security_schema_table := quote_ident(TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME);
        base_schema_table := replace(security_schema_table, '_security', '_data');
        
        raise info 'security_table: % | base_table: %', security_schema_table, base_schema_table;

        for rec1 in (select global_role_id from global_role_memberships_data where person_id = new.__person_id) loop

            for rec2 in (select column_name, access_level from global_role_grants_data where table_name = base_schema_table and global_role_id = rec1.global_role_id) loop 
                
                security_table_column := '_' || rec2.column_name;
                
                execute format('select ' || rec2.column_name || ' from ' || security_schema_table || 
                ' where __id = ' || new.__id || ' and __person_id = '|| new.__person_id) into current_access_level;

                if current_access_level is null or current_access_level = 'Read' then 
                    
                    execute format('update '|| security_schema_table || ' set '|| security_table_column ' = ' rec2.access_level || ' where __id = '|| new.__id 
                    || ' and __person_id = ' || new.__person_id );
                
                end if; 

            end loop;
        end loop;

        raise info 'done';
end; $$