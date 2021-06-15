create or replace function delete_security_on_roles_fn()
returns trigger
language PLPGSQL
as $$
declare
p_person_id int;
p_role_id int;
new_access_level text;
security_table_name text;
security_column_name text;
rec1 record;
begin
    p_role_id := old.sys_role_id;
    p_person_id := old.sys_person_id; 
    for rec1 in (select * from sys_role_grants where sys_role_id = p_role_id) loop
        -- the security_grant function except no looping over all persons
        select get_access_level(p_person_id,rec1.table_name, rec1.column_name) into new_access_level;
        security_column_name := '_' || rec1.column_name;
        security_table_name := rec1.table_name || '_security';
        if new_access_level is null then 
				raise info 'new_access_level: %', new_access_level;
                execute format('update '|| security_table_name ||' set '|| security_column_name || ' = NULL  where __sys_person_id = '|| p_person_id );
            else 
                execute format('update '|| security_table_name ||' set '|| security_column_name || ' = '|| quote_literal(new_access_level) || ' where __sys_person_id = ' || p_person_id);
        end if;

    end loop;
    raise info 'done';
	return new;
end; $$;



DROP TRIGGER sys_role_memberships_delete_trigger on sys_role_memberships;

CREATE TRIGGER sys_role_memberships_delete_trigger
AFTER DELETE
ON sys_role_memberships
FOR EACH ROW
EXECUTE PROCEDURE delete_security_on_roles_fn();