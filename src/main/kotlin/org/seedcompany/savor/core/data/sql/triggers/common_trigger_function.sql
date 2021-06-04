CREATE OR REPLACE FUNCTION common_history_fn()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
  AS $$
  declare 
  original_table_name text;
  history_table_name text;
  sql_statement text;
  rec record;
  last_id int;
  col_name text;
begin
    original_table_name := quote_ident(TG_ARGV[0]);
    history_table_name := original_table_name || '_history';
    raise info '%', original_table_name; 
	execute format('insert into '|| history_table_name || '(_history_id) values( default
	 ) returning _history_id') into last_id;
	for rec in (select column_name from information_schema.columns where table_name = original_table_name) loop 
	col_name := quote_ident(rec.column_name);
	raise info '%', rec;
	raise info '%', col_name;
    execute format('update '|| history_table_name || ' set ' || col_name || ' = $1.' || col_name ||' where _history_id = '|| last_id) using new;
	END loop;
	raise info 'DONE';
	RETURN NEW;
end; $$;
