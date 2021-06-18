-- inserts the new id into the security table for each member 
create or replace function insert_data_to_security()
returns void
language plpgsql
as $$
declare 
security_schema_table text;
rec1 record;  
begin
        security_schema_table := quote_ident(TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME);
        -- public.locations_security
        
        for rec1 in execute format('select __person_id from '|| security_schema_table) loop

            execute format('insert into '|| security_schema_table || '(__id, __person_id) values (' || new.id || ',' || rec1.person_id ')'); 
            
        end loop; 
end; $$