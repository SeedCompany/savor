DROP TRIGGER sys_role_grants_delete_trigger on sys_role_grants;

delete from sys_locations_security;
delete from sys_role_grants;

CREATE TRIGGER sys_role_grants_delete_trigger
AFTER DELETE
ON sys_role_grants
FOR EACH ROW
EXECUTE PROCEDURE delete_security_on_grant_fn();

select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_people', 'public_first_name', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'name', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'created_at', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'sensitivity', 'Read');


select * from sys_locations_security;
select * from sys_role_grants;

delete from sys_role_grants where column_name = 'name' and access_level = 'Read';
select * from sys_locations_security;
-- should be null 

select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'name', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'name', 'Write');
delete from sys_role_grants where column_name = 'name' and access_level = 'Write';


