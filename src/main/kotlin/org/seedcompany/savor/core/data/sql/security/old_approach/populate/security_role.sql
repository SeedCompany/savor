create or replace function populate_security_global_member()
returns trigger
language PLPGSQL
as $$
declare
p_person_id int;
p_role_id int;
rec1 record;
begin
    p_role_id := new.sys_role_id;
    p_person_id := new.sys_person_id; 
    for rec1 in (select * from sys_role_grants where sys_role_id = p_role_id) loop
        -- the security_grant function except no looping over all persons
        perform insert_security_table_entries(p_person_id,rec1.table_name, rec1.column_name, rec1.access_level);
    end loop;
    raise info 'done';
	return new;
end; $$;

DROP TRIGGER sys_role_memberships_insert_trigger on sys_role_memberships;

CREATE TRIGGER sys_role_memberships_insert_trigger
AFTER INSERT
ON global_role_memberships
FOR EACH ROW
EXECUTE PROCEDURE populate_security_global_member_fn();
