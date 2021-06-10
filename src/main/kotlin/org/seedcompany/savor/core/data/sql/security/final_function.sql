create or replace function populate_security_on_grant_fn()
returns trigger
language PLPGSQL
as $$
declare
role_membership_count bigint;
p_base_table_name text;
p_table_name text;
p_column_name text;
p_access_level text;
entries_count_for_person bigint;
rec1 record;
rec2 record;
rec3 record;
base_table_column_name text;
base_table_column_value text;
final_columns text;
final_values text;
non_nullable_columns text;
non_nullable_column_values text;
current_access_level text;
begin
	p_table_name := new.table_name || '_security';
	p_base_table_name := new.table_name;
	p_column_name := '_' || new.column_name;
	p_access_level := new.access_level;

	raise info 'security table: %', p_table_name;
	-- checking if there are members for the role
	select count(*) from sys_role_memberships
	into role_membership_count
	where sys_role_id = new.sys_role_id;
	
	if role_membership_count > 0 then					 
	-- looping over each person belonging to the role
		for rec1 in (select sys_person_id from sys_role_memberships
				     where sys_role_id = new.sys_role_id) loop
		    -- checking if the person has entries in the security table
	    	execute format('select count(*) from ' || quote_ident(p_table_name) ||' where __sys_person_id = '||rec1.sys_person_id) into entries_count_for_person;
	
			if entries_count_for_person = 0 then
			-- loop over each record in the base table and insert the person id into security table 
			-- update the access level from NULL to Read/Write for the specific column
				for rec2 in execute format('select * from ' || p_base_table_name) loop

					non_nullable_columns := '';
					non_nullable_column_values := '';
				--  getting the non_nullable_column names from security table and values from the base table
                --  this loop is inside the rec2 loop as we need access to rec2.reference_count
					for rec3 in (SELECT column_name FROM information_schema.columns WHERE 
		 			             table_schema = 'public' AND is_nullable = 'NO' and table_name = 'sys_locations_security') loop

						raise info 'rec3: %', rec3;
						if rec3.column_name != '__sys_person_id' and rec3.column_name != 'sys_secure_id' then
							non_nullable_columns := non_nullable_columns || ',' || rec3.column_name;

							rec3.column_name := replace(rec3.column_name, '__', '');
							execute format('select ' || rec3.column_name || ' from ' || p_base_table_name ||
							 ' where reference_count = '|| rec2.reference_count) into base_table_column_value;

							raise info 'base_table_column_name: % ', rec3.column_name;
						    raise info 'base_table_column_value: % ', base_table_column_value;
							non_nullable_column_values := non_nullable_column_values || ',' || base_table_column_value;

						end if;
					end loop;

					non_nullable_columns := substr(non_nullable_columns, 2, length(non_nullable_columns) - 1);
					non_nullable_column_values := substr(non_nullable_column_values, 2, length(non_nullable_column_values) - 1);
					raise info 'names: % | values: %', non_nullable_columns, non_nullable_column_values;
					
					final_columns := '__sys_person_id,'||non_nullable_columns;
					final_values := rec1.sys_person_id || ','|| non_nullable_column_values;
					raise info 'final names: % | final values: %', final_columns, final_values;

					execute format('insert into '|| p_table_name || '(' || final_columns ||  ') values(' || 
					final_values || ')');
					execute format('update '|| p_table_name || ' set ' || p_column_name 
								  || ' = ' || quote_literal(p_access_level)|| ' where __sys_person_id = '|| rec1.sys_person_id);

			    end loop;
			else 
			--  get the current access level of the column
				execute format('select '|| p_column_name || ' from ' || p_table_name || ' 
				where __sys_person_id =' || rec1.sys_person_id || ' limit 1') into current_access_level;
			--  if the access level isn't write, then update it 
				if current_access_level != 'Write' then
					execute format('update '|| p_table_name || ' set ' || p_column_name 
								  || ' = ' || quote_literal(p_access_level)|| ' where __sys_person_id = '|| rec1.sys_person_id);
				end if;
			end if;
		end loop;
		raise info 'done';
	end if;
	return new;
end; $$;

DROP TRIGGER sys_role_grants_insert_trigger on sys_role_grants;

CREATE TRIGGER sys_role_grants_insert_trigger
AFTER INSERT
ON sys_role_grants
FOR EACH ROW
EXECUTE PROCEDURE populate_security_on_grant_fn();

delete from sys_role_grants;
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'name', 'Write');

select * from sys_people;
select * from sys_role_memberships;
select * from sys_locations;
select * from sys_locations_security;
delete  from sys_locations_security;


