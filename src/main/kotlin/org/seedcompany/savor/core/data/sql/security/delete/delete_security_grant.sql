create or replace function delete_security_on_grant_fn()
returns trigger
language PLPGSQL
as $$
declare
role_membership_count bigint;
entries_count_for_person bigint;
new_access_level text;
rec1 record;
begin
	-- checking if there are members for the role
	select count(*) from sys_role_memberships
	into role_membership_count
	where sys_role_id = new.sys_role_id;
	
	if role_membership_count > 0 then					 
	-- looping over each person belonging to the role
		for rec1 in (select sys_person_id from sys_role_memberships
				     where sys_role_id = new.sys_role_id) loop
			select get_access_level(rec1.sys_person_id, new.table_name, new.column_name) into new_access_level;
		end loop;
		raise info 'done';
	end if;
	return new;
end; $$;

DROP TRIGGER sys_role_grants_delete_trigger on sys_role_grants;

CREATE TRIGGER sys_role_grants_delete_trigger
AFTER DELETE
ON sys_role_grants
FOR EACH ROW
EXECUTE PROCEDURE delete_security_on_grant_fn();

delete from sys_role_grants;
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'name', 'Write');
select * from sys_role_grants;

delete  from sys_locations_security;
select * from sys_locations_security;