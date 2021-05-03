-- ENUMS ------------------------------------------------------------

-- security only needed on certain tables
DO $$ BEGIN
    create type e_table_name as enum (
		'sc_engagements',
		'sc_languages',
		'sc_projects',
		'sc_projects_to_engagements',
		'sc_users'
	);    
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- security only on columns that users will access
DO $$ BEGIN
	create type e_column_name as enum (
		'created_at',
		'email',
		'engagement_id',
		'first_name',
		'full_name',
		'group_id',
		'id',
		'internal_id',
		'language_id',
		'last_name',
		'name',
		'private_name',
		'private_name_override',
		'project_id',
		'public_name',
		'public_name_override',
		'sys_org_id',
		'sys_project_id',
		'sys_user_id',
		'user_id'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- ORGANIZATIONS -----------------------------------------------------------------

create table if not exists sys_organizations(
	sys_org_id serial primary key,
	private_name varchar(255) unique not null,
	public_name varchar(255) unique not null,
	created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sc_organizations(
	sys_org_id int primary key not null,
	sc_internal_org_id varchar(32) unique not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_org_id) references sys_organizations(sys_org_id)
);

-- USERS + GROUPS ------------------------------------------------------------

create table if not exists sys_users(
	sys_user_id serial primary key,
	email varchar(255) unique not null,
	password varchar(255) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sc_users(
	sys_user_id int primary key not null,
	first_name varchar(64),
	last_name varchar(64),
	full_name varchar(128),
	created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sys_groups(
	sys_group_id serial primary key,
	name varchar(255) unique not null,
	created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sys_group_memberships_by_user(
	sys_user_id int not null,
	sys_group_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_user_id, sys_group_id),
	foreign key (sys_user_id) references sys_users(sys_user_id),
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

-- AUTHORIZATION ------------------------------------------------------------

create table if not exists sys_column_access_by_user (
	sys_user_id int not null,
	table_name e_table_name not null,
	column_name e_column_name not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_user_id, table_name, column_name),
	foreign key (sys_user_id) references sys_users(sys_user_id)
);

create table if not exists sys_column_access_by_group (
	sys_group_id int not null,
	table_name e_table_name not null,
	column_name e_column_name not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_group_id, table_name, column_name),
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

create table if not exists sys_row_access_by_user (
	sys_user_id int not null,
	table_name e_table_name not null,
	row_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_user_id, table_name, row_id),
	foreign key (sys_user_id) references sys_users(sys_user_id)
);

create table if not exists sys_row_access_by_group (
	sys_group_id int not null,
	table_name e_table_name not null,
	row_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_group_id, table_name, row_id),
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

-- AUTHENTICATION ------------------------------------------------------------

create table if not exists sys_tokens (
	token varchar(512) primary key,
	sys_user_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_user_id) references sys_users(sys_user_id)
);

-- SC DOMAIN ENTITIES ------------------------------------------------------------

create table if not exists sc_languages (
	sc_lang_id serial primary key,
	name varchar(255) unique not null,
	created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sc_engagements (
	sc_eng_id serial primary key,
	name varchar(255) unique not null,
	sc_lang_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sc_lang_id) references sc_languages(sc_lang_id)
);

create table if not exists sc_projects (
	sys_group_id int primary key not null,
	sc_internal_project_id varchar(32) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

create table if not exists sc_projects_to_engagements (
	sys_group_id int not null,
	sc_eng_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_group_id, sc_eng_id),
	foreign key (sys_group_id) references sc_projects(sys_group_id),
	foreign key (sc_eng_id) references sc_engagements(sc_eng_id)
);

