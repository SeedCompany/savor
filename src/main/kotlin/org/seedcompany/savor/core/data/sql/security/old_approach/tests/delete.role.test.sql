DROP TRIGGER sys_role_memberships_delete_trigger on sys_role_memberships;

delete from sys_role_memberships;
delete from sys_locations_security;
delete from sys_roles_security;

CREATE TRIGGER sys_role_memberships_delete_trigger
AFTER DELETE
ON sys_role_memberships
FOR EACH ROW
EXECUTE PROCEDURE delete_security_on_role_fn();

select * from sys_add_role_member('Admin', 'Seed Company', 'michael_marshall@tsco.org');
select * from sys_add_role_member('Admin', 'Seed Company', 'sc_admin@asdf.com');

select * from sys_locations_security;

select * from sys_users s join sys_people p on s.sys_person_id = p.sys_person_id;

delete from sys_role_memberships where sys_person_id = 2;

select * from sys_add_role_grant('Project Manager', 'Seed Company', 'sys_roles', 'name', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_roles', 'name', 'Write');
select * from sys_add_role_member('Admin', 'Seed Company', 'michael_marshall@tsco.org');
select * from sys_add_role_member('Project Manager', 'Seed Company', 'michael_marshall@tsco.org');

select * from sys_roles_security;

delete from sys_role_memberships where sys_person_id = 1 and sys_role_id = 2;