create or replace function delete_security_on_grant_fn()
returns trigger
language PLPGSQL
as $$
declare
role_membership_count bigint;
entries_count_for_person bigint;
new_access_level text;
rec1 record;
security_table_name text;
security_column_name text;
begin
    security_table_name := old.table_name || '_security';
    security_column_name := '_' || old.column_name;
	raise info 'table: % - column: %', security_table_name, security_column_name;
		for rec1 in (select sys_person_id from sys_role_memberships
				     where sys_role_id = old.sys_role_id) loop
			select get_access_level(rec1.sys_person_id, old.table_name, old.column_name) into new_access_level;
            if new_access_level is null then 
				raise info 'new_access_level: %', new_access_level;
                execute format('update '|| security_table_name ||' set '|| security_column_name || ' = NULL  where __sys_person_id = '|| rec1.sys_person_id );
            else 
                execute format('update '|| security_table_name ||' set '|| security_column_name || ' = '|| new_access_level || ' where __sys_person_id = ' || rec1.sys_person_id);
            end if;
		end loop;
		raise info 'done';
	return new;
end; $$;

DROP TRIGGER sys_role_grants_delete_trigger on sys_role_grants;

CREATE TRIGGER sys_role_grants_delete_trigger
AFTER DELETE
ON sys_role_grants
FOR EACH ROW
EXECUTE PROCEDURE delete_security_on_grant_fn();

delete from sys_role_grants where  column_name = 'name' and access_level = 'Write';
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'name', 'Write');
select * from sys_role_grants;

delete  from sys_locations_security;
select * from sys_locations_security;