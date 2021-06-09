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