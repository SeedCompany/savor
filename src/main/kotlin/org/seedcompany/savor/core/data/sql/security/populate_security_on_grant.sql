CREATE OR REPLACE FUNCTION populate_security_on_grant_fn()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
  AS $$
  declare
  role_membership_count bigint;
  p_table_name text;
  p_column_name text;
  p_access_level text;
  rec1 record;
  rec2 record;
begin
	p_table_name := quote_ident(new.table_name || '_security');
	p_column_name := quote_ident(new.column_name);
	p_access_level := quote_ident(new.access_level);
-- 	checking if there are any members for the role
	select count(*) from sys_role_memberships
	into role_membership_count
	where sys_role_id = new.sys_role_id;
-- 	loop over all the persons belonging to the role and insert into 
--  corresponding security table.
	if role_membership_count > 0 then
		for rec1 in (select sys_person_id from sys_role_memberships
				    where sys_role_id = new.sys_role_id) loop
					raise info '%', rec.sys_person_id;
					
					for rec2 in (select )	
					execute procedure('insert into '|| p_table_name
					|| '( ' || p_column_name || ' ) values ( '
					|| p_access_level ') where  ');
	end if;
	RETURN NEW;
end; $$;


-- to get the non-nullable columns:

-- SELECT table_name, column_name FROM 
-- information_schema.columns WHERE 
-- table_schema = 'public' AND is_nullable = 'NO' 
-- and table_name = 'sys_locations_security';

-- PSEUDOCODE
-- check if any members exist for role 
-- if they do:
	-- get table_column, column_name and access_level, role_id
	-- loop over all people belonging to role_id
	-- for each person: 
		-- if no value exists for the person in the security table:
			-- find non-nullable columns and loop over them
				-- concat to string (could also look into arrays)
			-- extract the column_names from string
		-- loop over all the records in the base table 
			-- insert into the non-nullable columns of the security table
		-- check what is the existing of the incoming column_name
		-- if null, insert directly
		-- else
		-- if read, update to write
		-- if write, no change
-- else exit