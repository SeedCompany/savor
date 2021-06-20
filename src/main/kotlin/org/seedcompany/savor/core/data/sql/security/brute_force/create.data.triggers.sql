CREATE OR REPLACE FUNCTION create_data_triggers(p_schema_name text)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
declare 
	 rec1 record;
	 insert_trigger_name text;
begin

	execute format('set schema '|| quote_literal(p_schema_name));

	for rec1 in (SELECT table_name FROM information_schema.tables
				WHERE table_schema = p_schema_name and table_name like '%_data'
				ORDER BY table_name) loop 

        insert_trigger_name := quote_ident(rec1.table_name||'_security_insert_trigger');

        -- INSERT TRIGGER
        execute format('DROP TRIGGER IF EXISTS '|| insert_trigger_name || ' ON ' ||rec.table_name);
        execute format('CREATE TRIGGER ' || insert_trigger_name
        || ' AFTER INSERT
        ON ' || rec.table_name || 
        ' FOR EACH ROW
        EXECUTE PROCEDURE insert_data_to_security()'); 


	END loop;
	raise info 'DONE';
end; $$;

select create_data_triggers('public');
select create_data_triggers('sc');