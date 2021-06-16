-- bootstrap.data.sql

-- ensure we have person 0 to use as a default creator - todo: remove
insert into public.people("id") values (0) on conflict do nothing;

-- ensure we have org 0 to make other inserts in this script easier - todo: remove
insert into public.organizations("id", "name") values (0, 'default org') on conflict do nothing;

-- SYS LOCATIONS
insert into locations("name", "sensitivity", "type") values ('USA', 'Low', 'Country') on conflict do nothing;
insert into locations("name", "sensitivity", "type") values ('Arlington', 'High', 'City') on conflict do nothing;

-- SYS ORGANIZATIONS
insert into organizations ("name") values ('Seed Company') on conflict do nothing;
insert into organizations ("name") values ('SIL') on conflict  do nothing;
insert into organizations ("name") values ('Wycliffe USA') on conflict do nothing;

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
select * from sys_add_role_grant('Admin', 'Seed Company', 'public.people', 'public_first_name', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'public.locations', 'name', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'public.locations', 'created_at', 'Read');
select * from sys_add_role_grant('Admin', 'Seed Company', 'public.locations', 'sensitivity', 'Read');

-- ROLE MEMBERSHIPS
select * from sys_add_role_member('Admin', 'Seed Company', 'michael_marshall@tsco.org');

-- PROJECT ROLES
insert into public.project_roles("name", "org_id") values ('Project Manager', 0) on conflict do nothing;
insert into public.project_roles("name", "org_id") values ('Consultant', 0) on conflict do nothing;
insert into public.project_roles("name", "org_id") values ('Intern', 0) on conflict do nothing;

-- PROJECT ROLE GRANTS
-- todo: these have hard coded role ids, which we have to use until we have functions to add project roles.
insert into public.project_role_grants("access_level", "column_name", "project_role_id", "table_name") values ('Write', 'name', 1, 'public.projects') on conflict do nothing;
insert into public.project_role_grants("access_level", "column_name", "project_role_id", "table_name") values ('Read', 'name', 2, 'public.projects') on conflict do nothing;

-- PROJECTS
insert into public.projects("name") values ('proj 1') on conflict do nothing;
insert into public.projects("name") values ('proj 2') on conflict do nothing;
insert into public.projects("name") values ('proj 3') on conflict do nothing;

-- PROJECT MEMBERSHIP
-- todo: replace with functions
insert into public.project_memberships("person_id", "project_id") values (1,1) on conflict do nothing;
insert into public.project_memberships("person_id", "project_id") values (2,1) on conflict do nothing;

-- PROJECT ROLE MEMBERSHIPS
-- todo: need to use functions to avoid hard coded ids
insert into public.project_member_roles("person_id", "project_id", "project_role_id") values (1, 1, 1) on conflict do nothing;
insert into public.project_member_roles("person_id", "project_id", "project_role_id") values (2, 1, 1) on conflict do nothing;
insert into public.project_member_roles("person_id", "project_id", "project_role_id") values (3, 1, 1) on conflict do nothing;
insert into public.project_member_roles("person_id", "project_id", "project_role_id") values (4, 1, 1) on conflict do nothing;