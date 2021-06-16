create or replace function populate_security_global_grant()
returns trigger
language PLPGSQL
as $$
declare
role_membership_count bigint;
entries_count_for_person bigint;
rec1 record;
begin
	-- checking if there are members for the role
	select count(*) from global_role_memberships
	into role_membership_count
	where global_role_id = new.global_role_id;
	
	if role_membership_count > 0 then					 
	-- looping over each person belonging to the role
		for rec1 in (select person_id from global_role_memberships
				     where global_role_id = new.global_role_id) loop
			perform insert_security_table_entries(rec1.person_id, new.table_name, new.column_name,new.access_level);
		end loop;
		raise info 'done';
	end if;
	return new;
end; $$;

DROP TRIGGER sys_role_grants_insert_trigger on global_role_grants;

CREATE TRIGGER sys_role_grants_insert_trigger
AFTER INSERT
ON global_role_grants
FOR EACH ROW
EXECUTE PROCEDURE populate_security_global_grant();



