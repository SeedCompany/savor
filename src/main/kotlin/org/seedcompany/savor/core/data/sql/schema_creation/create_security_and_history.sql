create or replace function create_security_history_tables()
returns void
language plpgsql
as $$
declare 
	rec1 record;
    rec2 record;
    p_table_name_literal text;
    p_table_name text; 
    history_table_name text;
    security_table_name text;
	security_table_column text;
begin
    for rec1 in (SELECT table_name
	FROM information_schema.tables
	WHERE table_schema = 'public' and table_name like '%_data'
	ORDER BY table_name) loop 

        -- FINDING ALL TABLES THAT NEED A HISTORY AND SECURITY TABLE AND LOOPING OVER THEM
        p_table_name_literal := replace(rec1.table_name, '_data', '');
        p_table_name := quote_ident(p_table_name_literal);
        security_table_name := quote_ident(p_table_name_literal||'_security');
        history_table_name := quote_ident(p_table_name_literal||'_history');
        raise info '%', p_table_name;

        -- DROP HISTORY AND SECURITY TABLES IF THEY EXIST
        execute format('drop table if exists '|| security_table_name || ' cascade ');
        execute format('drop table if exists '|| history_table_name || ' cascade ');

        p_table_name := quote_ident(rec1.table_name);

        -- HISTORY TABLE CREATION
        execute format('create table if not exists '|| history_table_name || ' ( _history_id serial primary key, 
        _history_created_at timestamp not null default CURRENT_TIMESTAMP)'); 

        -- SECURITY TABLE CREATION
        execute format('create table if not exists '|| security_table_name || ' ( __person_id int not null, __id int not null, foreign key (__id) references ' || p_table_name || '(id))' );


        -- UPDATE BOTH SECURITY AND HISTORY TABLE 
         for rec2 in (select column_name,data_type from information_schema.columns
        where table_name = p_table_name) loop
		raise info 'col-name: % | data-type: %', rec2.column_name, rec2.data_type;
            execute format('alter table ' || history_table_name || ' add column ' || rec2.column_name || ' ' ||
            rec2.data_type);
			security_table_column := '_' || rec2.column_name;
            execute format('alter table '|| security_table_name || ' add column '|| security_table_column || ' access_level');
        end loop;

	END loop;
	raise info 'DONE';
end; $$


select create_security_history_tables();