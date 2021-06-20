-- inserts the new id into the security table for each member 
-- trigger function for each data table
create or replace function insert_data_to_security()
returns trigger
language plpgsql
as $$
declare 
security_schema_table text;
rec1 record;  
begin
        security_schema_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
		security_schema_table := replace(security_schema_table, '_data', '_security');
		raise info 'security table: %', security_schema_table;
		
        
         for rec1 in execute format('select id from public.people_data') loop

             execute format('insert into '|| security_schema_table || '(__id, __person_id) values (' || new.id || ',' || quote_literal(rec1.id) || ')'); 
            
         end loop; 
		return new;
end; $$

