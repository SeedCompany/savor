-- ENUMS ------------------------------------------------------------

DO $$ BEGIN
    create type enum_table_name as enum (
		'sc_engagements',
		'sc_involvements',
		'sc_languages',
		'sc_org_to_org_rels',
		'sc_organizations',
		'sc_person_to_person_rels',
		'sc_people',
		'sc_partner_performance',
		'sc_projects',
		'sc_projects_to_engagements',
		'sc_roles',
		'sc_role_memberships',

        'sys_column_access_by_group',
        'sys_column_access_by_user',
        'sys_groups',
        'sys_group_memberships_by_user',
        'sys_organizations',
		'sys_people',
		'sys_row_access_by_group',
		'sys_row_access_by_user',
		'sys_tokens',
        'sys_users',
        'sys_column_security',
        'sys_row_security'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
	create type enum_column_name as enum (
		'column_name',
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
		'password',
		'private_name',
		'private_name_override',
		'project_id',
		'public_name',
		'public_name_override',
		'row_id',
		'sys_org_id',
		'sys_group_id',
		'sys_project_id',
		'sys_user_id',
		'table_name',
		'token',
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

-- USERS + GROUPS ------------------------------------------------------------

create table if not exists sys_users(
	sys_user_id serial primary key,
	email varchar(255) unique not null,
	password varchar(255) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sys_people(
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
	table_name enum_table_name not null,
	column_name enum_column_name not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_user_id, table_name, column_name),
	foreign key (sys_user_id) references sys_users(sys_user_id)
);

create table if not exists sys_column_access_by_group (
	sys_group_id int not null,
	table_name enum_table_name not null,
	column_name enum_column_name not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_group_id, table_name, column_name),
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

create table if not exists sys_row_access_by_user (
	sys_user_id int not null,
	table_name enum_table_name not null,
	row_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_user_id, table_name, row_id),
	foreign key (sys_user_id) references sys_users(sys_user_id)
);

create table if not exists sys_row_access_by_group (
	sys_group_id int not null,
	table_name enum_table_name not null,
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

-- VIEWS ----------------------------------------------------------------------

-- temp, doesn't use group security. need to research the best way to produce view
create materialized view if not exists sys_column_security
as
    select sys_users.sys_user_id, sys_column_access_by_user.table_name, sys_column_access_by_user.column_name
    from sys_users
    left join sys_column_access_by_user
    on sys_users.sys_user_id = sys_column_access_by_user.sys_user_id
    where sys_column_access_by_user.column_name is not null
with no data;

create unique index if not exists pk_sys_column_security on sys_column_security ("sys_user_id", "table_name", "column_name");

REFRESH MATERIALIZED VIEW sys_column_security;

create materialized view if not exists sys_row_security
    as
    select sys_users.sys_user_id, sys_row_access_by_user.table_name, sys_row_access_by_user.row_id
    from sys_users
    left join sys_row_access_by_user
    on sys_users.sys_user_id = sys_row_access_by_user.sys_user_id
    where sys_row_access_by_user.row_id is not null
with no data;

create unique index if not exists pk_sys_row_security on sys_row_security ("sys_user_id", "table_name", "row_id");

REFRESH MATERIALIZED VIEW sys_row_security;