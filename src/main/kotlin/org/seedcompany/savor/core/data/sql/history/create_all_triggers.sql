CREATE OR REPLACE FUNCTION create_history_triggers_fn(p_schema_name text)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
declare 
	 rec1 record;
	 insert_trigger_name text;
	 update_trigger_name text;
	 base_schema_table_name text;
begin
	for rec1 in (SELECT table_name
	FROM information_schema.tables
	WHERE table_schema = p_schema_name and table_name like '%_data'
	ORDER BY table_name) loop 
	-- FINDING ALL TABLES THAT HAVE A HISTORY TABLE AND LOOPING OVER THEM
	base_schema_table_name = p_schema_name || '.' || rec1.table_name;
	insert_trigger_name := quote_ident(rec1.table_name||'_history_insert_trigger');
	update_trigger_name := quote_ident(rec1.table_name||'_history_update_trigger');
	raise info '%', base_schema_table_name;
	-- INSERT TRIGGER
	execute format('DROP TRIGGER IF EXISTS '|| insert_trigger_name || ' ON ' ||base_schema_table_name);
	execute format('CREATE TRIGGER ' || insert_trigger_name
  	|| ' AFTER INSERT
  	ON ' || base_schema_table_name || 
  	' FOR EACH ROW
  	EXECUTE PROCEDURE common_history_fn()'); 
	--   UPDATE TRIGGER
	execute format('DROP TRIGGER IF EXISTS ' || update_trigger_name || ' ON ' || base_schema_table_name);
	execute format('CREATE TRIGGER ' || update_trigger_name
  	|| ' AFTER UPDATE
  	ON ' || base_schema_table_name || 
  	' FOR EACH ROW
  	EXECUTE PROCEDURE common_history_fn()'); 

	END loop;
	raise info 'DONE';
end; $$;

select create_history_triggers_fn('public');
select create_history_triggers_fn('sc');
select create_history_triggers_fn('sil');