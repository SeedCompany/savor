-- inserts the new id into the security table for each member 
-- trigger function for each data table
create or replace function public.insert_data_to_security()
returns trigger
language plpgsql
as $$
declare 
base_schema_table_name text;
security_schema_table_name text;
row_sensitivity_clearance boolean;
rec1 record;  
begin                                           
        base_schema_table_name := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
		security_schema_table_name := replace(base_schema_table_name, '_data', '_security');
		raise info 'security table: %', security_schema_table_name;
		
        
         for rec1 in execute format('select id, sensitivity_clearance from public.people_data') loop
            
            select public.get_sensitivity_clearance(new.id, rec1.id, rec1.sensitivity_clearance, TG_TABLE_SCHEMA, TG_TABLE_NAME) into row_sensitivity_clearance;
             execute format('insert into '|| security_schema_table_name || '(__id, __person_id, __sensitivity_clearance) values (' || new.id || ',' || quote_literal(rec1.id) ||',' || row_sensitivity_clearance ||')'); 
            
         end loop; 
		return new;
end; $$;

