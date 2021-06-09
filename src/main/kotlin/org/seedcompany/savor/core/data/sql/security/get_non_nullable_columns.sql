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
p_secure_id int;
rec1 record;
rec2 record;
rec0 record;
output_string text;
current_access_level text;
non_nullable_columns text;
non_nullable_column_values text;
begin
	p_table_name := new.table_name || '_security';
	p_base_table_name := new.table_name;
	p_column_name := '_' || new.column_name;
	p_access_level := new.access_level;
	raise info '%', p_table_name;
	-- checking if there are members for the role
	select count(*) from sys_role_memberships
	into role_membership_count
	where sys_role_id = new.sys_role_id;
	
	non_nullable_columns := '';
	
	for rec0 in (SELECT column_name FROM 
		 information_schema.columns WHERE 
		 table_schema = 'public' AND is_nullable = 'NO' 
		 and table_name = 'sys_locations_security') loop
		
		raise info '%', rec0;
 		if rec0.column_name != '__sys_person_id' and rec0.column_name != 'sys_secure_id' then
			rec0.column_name := replace(rec0.column_name, '__', '');
			non_nullable_columns := non_nullable_columns || ',' || rec0.column_name;
		end if;
	end loop;
	non_nullable_columns := substr(non_nullable_columns, 2, length(non_nullable_columns) - 1);
	execute format('select '|| non_nullable_columns ||' from '|| new.table_name || ' limit 1') into rec1;
-- 	rec1 := cast(rec1 as text);
-- 	rec1 := substr(rec1, 2, length(rec1) - 2);
	raise info '%', rec1;
	
-- 	raise info '%', output_string;
	raise info '%', non_nullable_columns;
	return new;
end; $$;

-- 1. get the non-nullable columns of the security table (for example: __sys_location_id, __sys_person_id, __sys_secure_id )
-- 2. do some parsing to get the names of the columns we want from the base table (sys_location_id )
-- 3. use dynamic sql to get the values of the columns obtained from step 2 from the base table while looping through entries of base table
-- 4. convert the record we obtain in step 3 to a string
-- 5. use dynamic sql to insert all the non_nullable_columns into the security table in one query (using the string we get from step 4)