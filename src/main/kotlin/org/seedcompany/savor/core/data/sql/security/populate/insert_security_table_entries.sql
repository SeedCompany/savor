-- each base table needs to have a serial column named reference_count 
create or replace function insert_security_table_entries(p_person_id int, p_table_name table_name, p_column_name varchar(255), p_access_level access_level)
returns void 
language PLPGSQL
as $$
declare
entries_count_for_person int;
security_table_name text;
rec1 record;
rec2 record;
base_table_column_value text;
non_nullable_columns text;
non_nullable_column_values text;
final_columns text;
final_values text;
current_access_level text;
begin 
	p_column_name := '_' || p_column_name;
    security_table_name := p_table_name || '_security';
    execute format('select count(*) from ' || quote_ident(security_table_name) ||' where __sys_person_id = '||p_person_id) into entries_count_for_person;
	
        if entries_count_for_person = 0 then
        -- loop over each record in the base table and insert the person id into security table 
        -- update the access level from NULL to Read/Write for the specific column
            for rec1 in execute format('select * from ' || p_table_name) loop

                non_nullable_columns := '';
                non_nullable_column_values := '';
                --  getting the non_nullable_column names from security table and values from the base table
                --  this loop is inside the rec1 loop as we need access to rec1.reference_count
                for rec2 in (SELECT column_name FROM information_schema.columns WHERE 
                            table_schema = 'public' AND is_nullable = 'NO' and table_name = security_table_name) loop

                    raise info 'rec2: %', rec2;
                    if rec2.column_name != '__sys_person_id' then
                        non_nullable_columns := non_nullable_columns || ',' || rec2.column_name;

                        rec2.column_name := replace(rec2.column_name, '__', '');
                        execute format('select ' || rec2.column_name || ' from ' || p_table_name ||
                            ' where reference_count = '|| rec1.reference_count) into base_table_column_value;

                        raise info 'base_table_column_name: % ', rec2.column_name;
                        raise info 'base_table_column_value: % ', base_table_column_value;
                        non_nullable_column_values := non_nullable_column_values || ',' || base_table_column_value;

                    end if;
                end loop;
-- 			    removing the first comma
                if length(non_nullable_columns) > 0 then 
                    non_nullable_columns := substr(non_nullable_columns, 2, length(non_nullable_columns) - 1);
                    final_columns := '__sys_person_id,'||non_nullable_columns;
                else 
                    final_columns := '__sys_person_id';
                end if; 
                if length(non_nullable_column_values) > 0 then
                    non_nullable_column_values := substr(non_nullable_column_values, 2, length(non_nullable_column_values) - 1);
                    final_values := p_person_id || ','|| non_nullable_column_values;
                else 
                    final_values := p_person_id;
                end if;
                raise info 'names: % | values: %', non_nullable_columns, non_nullable_column_values;
                
                
                raise info 'final names: % | final values: %', final_columns, final_values;

                execute format('insert into '|| security_table_name || '(' || final_columns ||  ') values(' 
                               || final_values || ')');

                execute format('update '|| security_table_name || ' set ' || p_column_name 
                                || ' = ' || quote_literal(p_access_level)|| ' where __sys_person_id = '|| p_person_id);

            end loop;
        else 
        --  get the current access level of the column
            execute format('select '|| p_column_name || ' from ' || security_table_name || ' 
            where __sys_person_id =' || p_person_id || ' limit 1') into current_access_level;
        --  if the access level isn't write, then update it 
            if current_access_level != 'Write' or current_access_level is NULL then
                execute format('update '|| security_table_name || ' set ' || p_column_name 
                                || ' = ' || quote_literal(p_access_level) || ' where __sys_person_id = '
                                || p_person_id);
            end if;
        end if;
end; $$; 

