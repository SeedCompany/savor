
-- SYS USERS
insert into sys_users ("email", "password") values ('sys_admin@asdf.com', 'asdf') on conflict ("email") do nothing;
insert into sys_users ("email", "password") values ('sc_admin@asdf.com', 'asdf') on conflict ("email") do nothing;
insert into sys_users ("email", "password") values ('sc_project_manager@asdf.com', 'asdf') on conflict ("email") do nothing;
insert into sys_users ("email", "password") values ('sc_regional_director@asdf.com', 'asdf') on conflict ("email") do nothing;
insert into sys_users ("email", "password") values ('sc_consultant@asdf.com', 'asdf') on conflict ("email") do nothing;

-- SC USERS
select sc_add_user('sc_admin@asdf.com', 'SC', 'Admin');
select sc_add_user('sc_project_manager@asdf.com', 'Project', 'Manager');
select sc_add_user('sc_regional_director@asdf.com', 'Regional', 'Director');
select sc_add_user('sc_consultant@asdf.com', 'SC', 'Consultant');

-- GROUPS
insert into sys_groups ("name") values ('sys_admins') on conflict ("name") do nothing; 
insert into sys_groups ("name") values ('sc_admins') on conflict ("name") do nothing; 
insert into sys_groups ("name") values ('sc_project_managers') on conflict ("name") do nothing; 
insert into sys_groups ("name") values ('sc_regional_directors') on conflict ("name") do nothing; 
insert into sys_groups ("name") values ('sc_consultants') on conflict ("name") do nothing; 

-- GROUP MEMBERSHIPS
select sys_add_member('sys_admin@asdf.com', 'sys_admins');
select sys_add_member('sc_admin@asdf.com', 'sc_admins');
select sys_add_member('sc_project_manager@asdf.com', 'sc_project_managers');
select sys_add_member('sc_regional_director@asdf.com', 'sc_regional_directors');
select sys_add_member('sc_consultant@asdf.com', 'sc_consultants');

-- SYS ORGANIZATIONS
insert into sys_organizations ("private_name", "public_name") values ('Seed Company', 'Seed Company') on conflict do nothing;
insert into sys_organizations ("private_name", "public_name") values ('SIL', 'SIL') on conflict  do nothing;
insert into sys_organizations ("private_name", "public_name") values ('Wycliffe USA', 'Wycliffe USA') on conflict do nothing;

-- SC ORGANIZATIONS
select sc_add_org('Seed Company', 'org101');
select sc_add_org('SIL', 'org102');
select sc_add_org('Wycliffe USA', 'org103');
                
-- AUTHORIZATIONS

select sys_add_column_access_for_user('sc_admin@asdf.com', 'sc_users', 'sys_user_id');
select sys_add_column_access_for_user('sc_admin@asdf.com', 'sc_users', 'first_name');
select sys_add_column_access_for_user('sc_admin@asdf.com', 'sc_users', 'last_name');
select sys_add_column_access_for_user('sc_admin@asdf.com', 'sc_users', 'full_name');
select sys_add_column_access_for_user('sc_admin@asdf.com', 'sc_users', 'created_at');

select sys_add_column_access_for_group('sc_project_managers', 'sc_users', 'sys_user_id');
select sys_add_column_access_for_group('sc_project_managers', 'sc_users', 'first_name');
select sys_add_column_access_for_group('sc_project_managers', 'sc_users', 'created_at');

select sys_add_column_access_for_group('sc_regional_directors', 'sc_users', 'sys_user_id');
select sys_add_column_access_for_group('sc_regional_directors', 'sc_users', 'first_name');
select sys_add_column_access_for_group('sc_regional_directors', 'sc_users', 'created_at');

select sys_add_column_access_for_group('sc_consultants', 'sc_users', 'sys_user_id');
select sys_add_column_access_for_group('sc_consultants', 'sc_users', 'first_name');

select sys_add_row_access_for_user('sc_project_manager@asdf.com', 'sc_users', 'sc_project_manager@asdf.com');
select sys_add_row_access_for_user('sc_project_manager@asdf.com', 'sc_users', 'sc_regional_director@asdf.com');
select sys_add_row_access_for_user('sc_project_manager@asdf.com', 'sc_users', 'sc_consultant@asdf.com');

select sys_add_row_access_for_user('sc_regional_directors', 'sc_users', 'sc_project_manager@asdf.com');
select sys_add_row_access_for_user('sc_regional_directors', 'sc_users', 'sc_regional_director@asdf.com');
select sys_add_row_access_for_user('sc_regional_directors', 'sc_users', 'sc_consultant@asdf.com');

select sys_add_row_access_for_group('sc_regional_directors', 'sc_users', 'sc_regional_director@asdf.com');
select sys_add_row_access_for_group('sc_regional_directors', 'sc_users', 'sc_project_manager@asdf.com');
select sys_add_row_access_for_group('sc_regional_directors', 'sc_users', 'sc_consultant@asdf.com');
