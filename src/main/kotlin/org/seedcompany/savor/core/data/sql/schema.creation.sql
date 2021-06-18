-- NOTE: using pg_catalog instead of information_schema might speed up the function
create or replace function create_security_history_tables(p_schema_name text)
returns text
language plpgsql
as $$
declare 
	rec1 record;
    rec2 record;
    existing_column text;
    p_table_name_literal text;
    p_table_name text; 
    history_table_name text;
    security_table_name text;
	security_table_column text;
	status text;
begin
	status := 'no change';
    -- FINDING ALL TABLES THAT NEED A HISTORY AND SECURITY TABLE AND LOOPING OVER THEM
    for rec1 in (select table_name
	from information_schema.tables
	where table_schema = p_schema_name and table_name like '%_data'
	order by table_name) loop 

		execute format('set schema '|| quote_literal(p_schema_name));
        
        p_table_name_literal := replace(rec1.table_name, '_data', '');
        -- locations_data -> locations
        security_table_name := quote_ident(p_table_name_literal||'_security');
        -- "locations_security"
        history_table_name := quote_ident(p_table_name_literal||'_history');
        -- "locations_history"
        p_table_name := quote_ident(rec1.table_name);
        -- "locations_data"

		raise info 'table_name: %', p_table_name;
        -- HISTORY TABLE CREATION
        execute format('create table if not exists '|| history_table_name || ' ( _history_id serial primary key, 
        _history_created_at timestamp not null default CURRENT_TIMESTAMP)'); 

        -- SECURITY TABLE CREATION
        execute format('create table if not exists '|| security_table_name || ' ( __person_id int not null, __id int not null, foreign key(__person_id) references public.people_data(id), foreign key (__id) references ' ||  p_table_name || '(id))' );


        -- UPDATE BOTH SECURITY AND HISTORY TABLE 
         for rec2 in (select column_name,case 
        			  when (data_type = 'USER-DEFINED') then udt_name 
        			else data_type 
    				end as data_type from information_schema.columns
        			where table_schema = p_schema_name and table_name = p_table_name) loop
		raise info 'col-name: % | data-type: %', rec2.column_name, rec2.data_type;

            select column_name from information_schema.columns into existing_column where table_schema = p_schema_name
            and table_name = history_table_name and column_name = rec2.column_name ;

            if not found then
				
				status := 'history table updated';
                execute format('alter table ' || history_table_name || ' add column ' || rec2.column_name || ' ' ||
                rec2.data_type);

            end if;


			security_table_column := '_' || rec2.column_name;

            select column_name from information_schema.columns into existing_column where table_schema = p_schema_name and table_name = security_table_name and column_name = security_table_column ;

            if not found then 
				
				status := 'security table updated';
                execute format('alter table '|| security_table_name || ' add column '|| security_table_column || ' public.access_level');
            
            end if;

        end loop;

	end loop;
	raise info 'DONE';
	return status;
end; $$


select create_security_history_tables('public');
select create_security_history_tables('sc');
