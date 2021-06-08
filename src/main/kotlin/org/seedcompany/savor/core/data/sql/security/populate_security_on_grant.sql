-- CREATE OR REPLACE FUNCTION populate_security_on_grant_fn()
--   RETURNS TRIGGER
--   LANGUAGE PLPGSQL
--   AS $$
--   declare
--   role_membership_count bigint;
--   p_base_table_name text;
--   p_table_name text;
--   p_column_name text;
--   p_access_level text;
--   non_nullable_columns text;
--   non_nullable_column text;
--   non_nullable_column_values text;
--   non_nullable_column_value text;
--   existing_person_count bigint;
--   base_table_column text;
--   base_table_column_value text;
--   rec1 record;
--   rec2 record;
--   rec3 record;
-- begin
-- 	p_base_table_name := quote_ident(new.table_name);
-- 	p_table_name_literal := new.table_name || '_security';
-- 	p_table_name := quote_ident(p_table_name_literal);
-- 	p_column_name := quote_ident(new.column_name);
-- 	p_access_level := quote_ident(new.access_level);
-- 	non_nullable_columns := '__sys_person_id';
-- 	raise info '%', p_table_name;
	
-- -- 	checking if there are any members for the role
-- 	select count(*) from sys_role_memberships
-- 	into role_membership_count
-- 	where sys_role_id = new.sys_role_id;
	
-- -- 	loop over all the persons belonging to the role and insert into corresponding security table.
-- 	if role_membership_count > 0 then
-- 		for rec1 in (select sys_person_id from sys_role_memberships
-- 				    where sys_role_id = new.sys_role_id) loop
-- 					raise info '%', rec.sys_person_id;
-- 					non_nullable_column_values = rec.sys_person_id;
					
-- -- -- 					check if there are already entries in the security table for the user
-- -- 					select count(*) into existing_person_count from 
-- -- 					p_table_name where __sys_person_id =  rec.sys_person_id;
					
-- -- -- 					get all the non-nullable columns from the table
-- -- 					if existing_person_count > 0 then

-- 					for rec2 in (select column_name FROM 
-- 								information_schema.columns WHERE 
-- 								table_schema = 'public' AND is_nullable = 'NO' 
-- 								and table_name = p_table_name_literal) loop
-- -- 										non_nullable_column	:= replace(rec.column_name, '__', '');
-- 										non_nullable_columns := non_nullable_columns || ',' || non_nullable_column;
-- 									if non_nullable_column != '__sys_person_id' then
-- 										base_table_column	:= replace(rec.column_name, '__', '');
										
-- 									else 
-- -- 											
										
-- 									endif;

-- -- 					else 					
-- -- -- 										array_append(non_nullable_columns, non_nullable_column);
-- -- 					endif;
-- 					for rec3 in (select * from p_base_table_name) loop
-- 						execute procedure('insert into '|| p_table_name ||'(' || non_nullable_columns || ')' values  )
					
								
-- 					execute procedure('insert into '|| p_table_name
-- 					|| '( ' || p_column_name || ' ) values ( '
-- 					|| p_access_level ') where  ');
-- 	RETURN NEW;
-- end; $$;



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


-- might be better to create a function just for locations security table and then generalise

--  AFTER REMOVING FOREIGN KEY CONSTRAINT

-- create or replace function populate_security_on_grant_fn()
-- returns trigger
-- language PLPGSQL
-- as $$
-- declare
-- role_membership_count bigint;
-- p_table_name text;
-- p_column_name text;
-- p_access_level text;
-- entries_count_for_person bigint;
-- p_secure_id int;
-- rec1 record;
-- rec2 record;
-- current_access_level text;
-- begin
-- 	p_table_name := quote_ident(new.table_name || '_security');
-- 	p_column_name := quote_ident(new.column_name);
-- 	p_access_level := quote_ident(new.access_level);
	
-- 	select count(*) from sys_role_memberships
-- 	into role_membership_count
-- 	where sys_role_id = new.sys_role_id;
	
-- 	if role_membership_count > 0 then
	
-- 		for rec1 in (select sys_person_id from sys_role_memberships
-- 				     where sys_role_id = new.sys_role_id) loop
					 
-- 			select count(*) from p_table_name into entries_count_for_person
-- 			where __sys_person_id = rec1.sys_person_id;
			
-- 			if entries_count_for_person == 0 then
-- 				for rec2 in (select * from quote_ident(new.table_name)) loop 
				
-- 					execute format('insert into '|| p_table_name || '(__sys_person_id) values(' || 
-- 					rec1.sys_person_id ||') returning sys_secure_id')into p_secure_id; 
-- 					execute format('update '|| p_table_name || ' set ' || p_column_name 
-- 								  || ' = ' || p_access_level|| ' where __sys_person_id = '|| rec1.sys_person_id);
-- 			    end loop;
-- 			else 
-- 				select p_column_name from p_table_name into current_access_level 
-- 				where __sys_person_id = rec1.sys_person_id limit 1;
-- 				if current_access_level != 'Write' then
-- 					execute format('update '|| p_table_name || ' set ' || p_column_name 
-- 								  || ' = ' || p_access_level|| ' where __sys_person_id = '|| rec1.sys_person_id);
-- -- 				else 
-- -- 					do nothing
-- 				end if;
-- 			end if;
-- 		end loop;
-- 		raise info 'done';
-- -- 	else 
-- -- -- 		do nothing
-- 	end if;
-- 	return new;
-- end; $$;
					
				
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
current_access_level text;
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
	
	if role_membership_count > 0 then
	-- looping over each person belonging to the role
		for rec1 in (select sys_person_id from sys_role_memberships
				     where sys_role_id = new.sys_role_id) loop

	-- checking if the person has entries in the security table
		execute format('select count(*) from ' || quote_ident(p_table_name) ||' where __sys_person_id = '||rec1.sys_person_id)
		into entries_count_for_person;
	
			if entries_count_for_person = 0 then
			-- loop over each record in the base table and insert the person id into security table 
			-- update the access level from NULL to Read/Write for the specific column
				for rec2 in execute format('select * from ' || p_base_table_name) loop 
				
					execute format('insert into '|| p_table_name || '(__sys_person_id) values(' || 
					rec1.sys_person_id ||') returning sys_secure_id')into p_secure_id; 
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