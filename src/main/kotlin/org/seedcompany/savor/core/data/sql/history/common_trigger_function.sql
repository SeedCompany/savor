CREATE OR REPLACE FUNCTION common_history_fn()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
declare 
base_schema_table_name text;
history_schema_table_name text;
rec1 record;
col_name text;
last_id int;
begin
  base_schema_table_name := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
  history_schema_table_name := replace(base_schema_table_name, '_data', '_history');

  raise info '%', base_schema_table_name; 
	execute format('insert into '|| history_schema_table_name || '(_history_id) values( default
	 ) returning _history_id') into last_id;

	for rec1 in (select column_name from information_schema.columns where table_schema = TG_TABLE_SCHEMA and  table_name = TG_TABLE_NAME) loop 
    raise info '%', rec1;
    raise info '%', rec1.column_name;
    col_name := quote_ident(rec1.column_name);
      execute format('update '|| history_schema_table_name || ' set ' || quote_ident(rec1.column_name) || ' = $1.' || col_name ||' where _history_id = '|| last_id) using new ;
	END loop;
	raise info 'DONE';
	RETURN NEW;
end; $$;


