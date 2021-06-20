CREATE OR REPLACE FUNCTION create_history_triggers_fn()
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
declare 
	 rec record;
  	 p_table_name text;
	 p_table_name_literal text;
	 insert_trigger_name text;
	 update_trigger_name text;
begin
	for rec in (SELECT table_name
	FROM information_schema.tables
	WHERE table_schema = 'public' and table_name like '%history'
	ORDER BY table_name) loop 
	-- FINDING ALL TABLES THAT HAVE A HISTORY TABLE AND LOOPING OVER THEM
	p_table_name_literal := replace(rec.table_name, '_history', '');
	p_table_name := quote_ident(p_table_name_literal);
	insert_trigger_name := quote_ident(p_table_name_literal||'_history_insert_trigger');
	update_trigger_name := quote_ident(p_table_name_literal||'_history_update_trigger');
	raise info '%', p_table_name;
	-- INSERT TRIGGER
	execute format('DROP TRIGGER IF EXISTS '|| insert_trigger_name || ' ON ' ||p_table_name);
	execute format('CREATE TRIGGER ' || insert_trigger_name
  	|| ' AFTER INSERT
  	ON ' || p_table_name || 
  	' FOR EACH ROW
  	EXECUTE PROCEDURE common_history_fn('|| p_table_name_literal || ')'); 
	--   UPDATE TRIGGER
	execute format('DROP TRIGGER IF EXISTS ' || update_trigger_name || ' ON ' || p_table_name);
	execute format('CREATE TRIGGER ' || update_trigger_name
  	|| ' AFTER UPDATE
  	ON ' || p_table_name || 
  	' FOR EACH ROW
  	EXECUTE PROCEDURE common_history_fn('|| p_table_name_literal || ')'); 

	END loop;
	raise info 'DONE';
end; $$;

select create_all_triggers_fn();