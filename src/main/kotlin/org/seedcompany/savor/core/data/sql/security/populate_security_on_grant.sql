CREATE OR REPLACE FUNCTION populate_security_on_grant_fn()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
  AS $$
  declare
  role_membership_count bigint;
  p_base_table_name text;
  p_table_name text;
  p_column_name text;
  p_access_level text;
  non_nullable_columns text;
  non_nullable_column text;
  non_nullable_column_values text;
  non_nullable_column_value text;
  existing_person_count bigint;
  base_table_column text;
  base_table_column_value text;
  rec1 record;
  rec2 record;
  rec3 record;
begin
	p_base_table_name := quote_ident(new.table_name);
	p_table_name_literal := new.table_name || '_security';
	p_table_name := quote_ident(p_table_name_literal);
	p_column_name := quote_ident(new.column_name);
	p_access_level := quote_ident(new.access_level);
	non_nullable_columns := '__sys_person_id';
	raise info '%', p_table_name;
	
-- 	checking if there are any members for the role
	select count(*) from sys_role_memberships
	into role_membership_count
	where sys_role_id = new.sys_role_id;
	
-- 	loop over all the persons belonging to the role and insert into corresponding security table.
	if role_membership_count > 0 then
		for rec1 in (select sys_person_id from sys_role_memberships
				    where sys_role_id = new.sys_role_id) loop
					raise info '%', rec.sys_person_id;
					non_nullable_column_values = rec.sys_person_id;
					
-- -- 					check if there are already entries in the security table for the user
-- 					select count(*) into existing_person_count from 
-- 					p_table_name where __sys_person_id =  rec.sys_person_id;
					
-- -- 					get all the non-nullable columns from the table
-- 					if existing_person_count > 0 then

					for rec2 in (select column_name FROM 
								information_schema.columns WHERE 
								table_schema = 'public' AND is_nullable = 'NO' 
								and table_name = p_table_name_literal) loop
-- 										non_nullable_column	:= replace(rec.column_name, '__', '');
										non_nullable_columns := non_nullable_columns || ',' || non_nullable_column;
									if non_nullable_column != '__sys_person_id' then
										base_table_column	:= replace(rec.column_name, '__', '');
										
									else 
-- 											
										
									endif;

-- 					else 					
-- -- 										array_append(non_nullable_columns, non_nullable_column);
-- 					endif;
					for rec3 in (select * from p_base_table_name) loop
						execute procedure('insert into '|| p_table_name ||'(' || non_nullable_columns || ')' values  )
					
								
					execute procedure('insert into '|| p_table_name
					|| '( ' || p_column_name || ' ) values ( '
					|| p_access_level ') where  ');
	RETURN NEW;
end; $$;



-- to get the non-nullable columns:

-- SELECT table_name, column_name FROM 
-- information_schema.columns WHERE 
-- table_schema = 'public' AND is_nullable = 'NO' 
-- and table_name = 'sys_locations_security';

-- PSEUDOCODE
-- check if any members exist for role *
-- if they do:
	-- get table_column, column_name and access_level, role_id *
	-- loop over all people belonging to role_id *
	-- for each person: 
		-- if no value exists for the person in the security table: 
			-- find non-nullable columns and loop over them *
				-- remove the __ if the column_name is not 'sys_person_id' and concat to string (could also look into arrays) *
		-- else do nothing *
		-- loop over all the records in the base table 
			-- insert into the non-nullable columns of the security table
			-- check what is the existing value of the incoming column_name
			-- if null, insert directly
			-- elif read, update to write
			-- else, no change
-- else exit




-- for each non_nullable_column
-- loop over the entire table and add it to an array
-- for each 