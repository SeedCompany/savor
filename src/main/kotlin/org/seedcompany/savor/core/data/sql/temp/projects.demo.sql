create table if not exists sys_project_memberships (
    id serial primary key,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    created_by int not null default 0,
    person_id int not null,
    project_id int not null,
    foreign key (created_by) references sys_people(id),
    foreign key (project_id) references sys_projects(id),
    foreign key (person_id) references sys_people(id)
);
create table if not exists sys_project_roles (
	id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	name varchar(255) not null,
	org_id int,
	project int 
	unique (org_id, name),
	foreign key (created_by) references sys_people(id),
	foreign key (org_id) references sys_organizations(id)
);
create table if not exists sys_project_member_roles (
    id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
    person_id int not null,
    project_id int not null,
	project_role_id int not null,
	unique (project_id, person_id),
	foreign key (created_by) references sys_people(id),
	foreign key (person_id) references sys_people(id),
	foreign key (project_id) references sys_projects(id),
	foreign key (project_role_id) references sys_project_roles(id)
);
create table if not exists sys_project_role_grants (
    id serial primary key,
	access_level access_level not null,
	column_name varchar(32) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	project_role_id int not null,
	table_name table_name not null,
	unique (project_role_id, table_name, column_name, access_level),
	foreign key (created_by) references sys_people(id),
	foreign key (project_role_id) references sys_project_roles(id)
);
insert into sys_project_roles("name", "org_id") values ('Project Manager', 0) on conflict do nothing;
insert into sys_project_roles("name", "org_id") values ('Consultant', 0) on conflict do nothing;
insert into sys_project_roles("name", "org_id") values ('Intern', 0) on conflict do nothing;

-- PROJECT ROLE GRANTS
-- todo: these have hard coded role ids, which we have to use until we have functions to add project roles.
insert into sys_project_role_grants("access_level", "column_name", "project_role_id", "table_name") values ('Write', 'name', 1, 'sys_projects') on conflict do nothing;
insert into sys_project_role_grants("access_level", "column_name", "project_role_id", "table_name") values ('Read', 'name', 2, 'sys_projects') on conflict do nothing;

-- PROJECTS
insert into sys_projects("name") values ('proj 1') on conflict do nothing;
insert into sys_projects("name") values ('proj 2') on conflict do nothing;
insert into sys_projects("name") values ('proj 3') on conflict do nothing;

-- PROJECT MEMBERSHIP
-- todo: replace with functions
insert into sys_project_memberships("person_id", "project_id") values (1,1) on conflict do nothing;
insert into sys_project_memberships("person_id", "project_id") values (2,1) on conflict do nothing;

-- PROJECT ROLE MEMBERSHIPS
-- todo: need to use functions to avoid hard coded ids
insert into sys_project_member_roles("person_id", "project_id", "project_role_id") values (1, 1, 1) on conflict do nothing;
insert into sys_project_member_roles("person_id", "project_id", "project_role_id") values (2, 1, 1) on conflict do nothing;
insert into sys_project_member_roles("person_id", "project_id", "project_role_id") values (3, 1, 1) on conflict do nothing;
insert into sys_project_member_roles("person_id", "project_id", "project_role_id") values (4, 1, 1) on conflict do nothing;
