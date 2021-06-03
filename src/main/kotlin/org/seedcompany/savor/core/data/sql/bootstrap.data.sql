-- bootstrap.data.sql

-- SYS LOCATIONS
insert into sys_locations("name", "sensitivity", "type") values ('USA', 'Low', 'Country') on conflict do nothing;
insert into sys_locations("name", "sensitivity", "type") values ('Arlington', 'High', 'City') on conflict do nothing;

-- SYS ORGANIZATIONS
insert into sys_organizations ("name") values ('Seed Company') on conflict do nothing;
insert into sys_organizations ("name") values ('SIL') on conflict  do nothing;
insert into sys_organizations ("name") values ('Wycliffe USA') on conflict do nothing;

-- SYS USERS
select * from sys_register('devops@tsco.org', 'asdf', 'Seed Company');
select * from sys_register('michael_marshall@tsco.org', 'asdf', 'Seed Company');
select * from sys_register('sc_admin@asdf.com', 'asdf', 'Seed Company');
select * from sys_register('sc_project_manager@asdf.com', 'asdf', 'Seed Company');
select * from sys_register('sc_regional_director@asdf.com', 'asdf', 'Seed Company');
select * from sys_register('sc_consultant@asdf.com', 'asdf', 'Seed Company');

-- SYS ROLES
select * from sys_create_role('SYS ADMIN', 'Seed Company');
select * from sys_create_role('Admin', 'Seed Company');
select * from sys_create_role('Project Manager', 'Seed Company');
select * from sys_create_role('Regional Director', 'Seed Company');
select * from sys_create_role('Consultant', 'Seed Company');

-- SYS ROLE GRANTS
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_people', 'public_first_name', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'name', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'created_at', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'sys_locations', 'sensitivity', 'Read');

-- ROLE MEMBERSHIPS
select * from sys_add_role_member('Admin', 'Seed Company', 'michael_marshall@tsco.org');