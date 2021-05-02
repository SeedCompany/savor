
-- SYS USERS
insert into sys_users ("email", "password") values ('sys_admin@asdf.com', 'asdf') on conflict ("email") do nothing;
insert into sys_users ("email", "password") values ('sc_admin@asdf.com', 'asdf') on conflict ("email") do nothing;
insert into sys_users ("email", "password") values ('sc_project_manager@asdf.com', 'asdf') on conflict ("email") do nothing;
insert into sys_users ("email", "password") values ('sc_regional_director@asdf.com', 'asdf') on conflict ("email") do nothing;
insert into sys_users ("email", "password") values ('sc_consultant@asdf.com', 'asdf') on conflict ("email") do nothing;

-- SC USERS
select sc_add_user('sc_admin@asdf.com', 'SC', 'Admin');
select sc_add_user('sc_project_manager@asdf.com', 'SC', 'Admin');
select sc_add_user('sc_regional_director@asdf.com', 'SC', 'Admin');
select sc_add_user('sc_consultant@asdf.com', 'SC', 'Admin');

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
insert into sys_organizations ("private_name", "public_name") values ('Seed Company', 'Seed Company') on conflict ("private_name", "public_name") do nothing;
insert into sys_organizations ("private_name", "public_name") values ('SIL', 'SIL') on conflict ("private_name", "public_name") do nothing;
insert into sys_organizations ("private_name", "public_name") values ('Wycliffe USA', 'Wycliffe USA') on conflict ("private_name", "public_name") do nothing;

-- SC ORGANIZATIONS
select sc_add_org('Seed Company', 'org101');
select sc_add_org('SIL', 'org102');
select sc_add_org('Wycliffe USA', 'org103');
                
-- AUTHORIZATIONS
insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (1, 'sc_users', 'sys_user_id');
insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (1, 'sc_users', 'first_name');
insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (1, 'sc_users', 'last_name');
insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (1, 'sc_users', 'full_name');
insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (1, 'sc_users', 'created_at');

insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (2, 'sc_users', 'sys_user_id');
insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (2, 'sc_users', 'first_name');
insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (2, 'sc_users', 'last_name');
insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (2, 'sc_users', 'full_name');
insert into sys_column_access_by_user ("sys_user_id", "table_name", "column_name") values (2, 'sc_users', 'created_at');

insert into sys_column_access_by_group ("sys_group_id", "table_name", "column_name") values (3, 'sc_users', 'sys_user_id');
insert into sys_column_access_by_group ("sys_group_id", "table_name", "column_name") values (3, 'sc_users', 'first_name');
insert into sys_column_access_by_group ("sys_group_id", "table_name", "column_name") values (3, 'sc_users', 'created_at');

insert into sys_column_access_by_group ("sys_group_id", "table_name", "column_name") values (4, 'sc_users', 'sys_user_id');
insert into sys_column_access_by_group ("sys_group_id", "table_name", "column_name") values (4, 'sc_users', 'first_name');
insert into sys_column_access_by_group ("sys_group_id", "table_name", "column_name") values (4, 'sc_users', 'created_at');

insert into sys_column_access_by_group ("sys_group_id", "table_name", "column_name") values (3, 'sc_users', 'sys_user_id');
insert into sys_column_access_by_group ("sys_group_id", "table_name", "column_name") values (3, 'sc_users', 'first_name');

insert into sys_row_access_by_user ("sys_user_id", "table_name", "row_id") values (3, 'sc_users', 2);
insert into sys_row_access_by_user ("sys_user_id", "table_name", "row_id") values (3, 'sc_users', 3);
insert into sys_row_access_by_user ("sys_user_id", "table_name", "row_id") values (3, 'sc_users', 4);

insert into sys_row_access_by_group ("sys_group_id", "table_name", "row_id") values (4, 'sc_users', 2);
insert into sys_row_access_by_group ("sys_group_id", "table_name", "row_id") values (4, 'sc_users', 3);
insert into sys_row_access_by_group ("sys_group_id", "table_name", "row_id") values (4, 'sc_users', 4);