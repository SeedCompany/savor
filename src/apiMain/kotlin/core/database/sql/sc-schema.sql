-- Seed Company Schema -------------------------------------------------------------

-- ENUMs ----------------------------------------------------------

DO $$ BEGIN
    create type sc_enum_involvements as enum (
		'CIT',
		'Engagements'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_enum_people_transitions as enum (
		'New Org',
		'Other'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_enum_org_transitions as enum (
		'To Manager',
		'To Other'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_enum_sensitivity as enum (
		'Low',
		'Medium',
		'High'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_enum_financial_reporting_types as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_partner_types as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_project_step as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_project_status as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- ACCOUNTING TABLES --------------------------------------------------------

create table if not exists sc_funding_account (
	account_number varchar(32) not null primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	name varchar(32)
);

-- LOCATION TABLES ----------------------------------------------------------

create table if not exists sc_field_zone (
	sc_field_zone_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	director_sys_person_id int,
	name varchar(32) unique not null,
	foreign key (director_sys_person_id) references sys_users(sys_user_id)
);

create table if not exists sc_field_regions (
	sc_field_region_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	director_sys_person_id int,
	name varchar(32) unique not null,
	foreign key (director_sys_person_id) references sys_users(sys_user_id)
);

create table if not exists sc_locations_ext_sys_locations (
	sys_location_id int primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	default_sc_field_region_id int,
	funding_account_number varchar(32),
	iso_alpha_3 char(3),
	name varchar(32) unique not null,
	type enum_location_type not null,
	foreign key (sys_location_id) references sys_locations(sys_location_id),
	foreign key (funding_account_number) references sc_funding_account(account_number)
);

-- ORGANIZATION TABLES

create table if not exists sc_organizations_ext_sys_groups(
	sys_group_id int primary key not null,
	address varchar(255),
	created_at timestamp not null default CURRENT_TIMESTAMP,
	sc_internal_org_id varchar(32) unique not null,
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

create table if not exists sc_organization_locations(
	sys_group_id int not null,
	sys_location_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_group_id, sys_location_id),
	foreign key (sys_group_id) references sys_groups(sys_group_id)
	foreign key (sys_location_id) references sys_locations(sys_location_id)
);

create table if not exists sc_partners (
	sys_group_id int primary key,
	active bool,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	financial_reporting_types sc_enum_financial_reporting_types[],
	is_global_innovations_client bool,
	modified_at timestamp not null default CURRENT_TIMESTAMP,
	pmc_entity_code varchar(32),
	point_of_contact_sys_user_id int,
	foreign key (point_of_contact_sys_user_id) references sys_people(sys_person_id),
	types sc_enum_partner_types[],
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

-- LANGUAGE TABLES ----------------------------------------------------------

create table if not exists sc_language_goal_definitions (
	sc_goal_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP
	-- todo
);

create table if not exists sc_languages (
	ISO_639 char(3) primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	is_dialect bool,
	is_sign_language bool,
	is_least_of_these bool,
	display_name varchar(255) unique not null,
	least_of_these_reason varchar(255),
	name varchar(255) unique not null,
	population_override int,
	registry_of_dialects_code varchar(32),
	sensitivity sc_enum_sensitivity,
	sign_language_code varchar(32),
	sponsor_estimated_eng_date timestamp,
	foreign key (ISO_639) references sil_table_of_languages(ISO_639)
);

create table if not exists sc_language_locations (
	ISO_639 char(3) not null,
	sys_location_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (ISO_639, sys_location_id)
	-- todo
);

create table if not exists sc_language_goals (
    ISO_639 char(3) not null,
	sc_goal_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (ISO_639, sc_goal_id),
	foreign key (ISO_639) references sil_table_of_languages(ISO_639)
	-- todo
);

-- USER TABLES --------------------------------------------------------------

create table if not exists sc_known_languages_by_person (
    sys_person_id int not null,
    known_language_ISO_639 char(3) int not null
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_person_id) references sys_people(sys_user_id),
	foreign key (known_language_ISO_639) references sil_table_of_languages(ISO_639)
);

create table if not exists sc_people_ext_sys_people (
    sys_person_id int primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	skills varchar(32)[],
	status varchar(32),
	foreign key (sys_person_id) references sys_people(sys_user_id)
);

create table if not exists sc_person_unavailabilities (
    sys_person_id int primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	description text,
	end timestamp not null,
	start timestamp not null,
	foreign key (sys_person_id) references sys_people(sys_user_id)
);

create table if not exists sc_roles_ext_sys_groups (
    sys_group_id int primary key,
    name varchar(32) unique not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

create table if not exists sc_global_role_memberships (
    sys_person_id int not null,
    sys_group_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_person_id, sys_group_id),
	foreign key (sys_person_id) references sys_people(sys_person_id),
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

-- FILES & DIRECTORIES ----------------------------------------------------------

create table if not exists sc_directories (
    sc_directory_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	-- todo
);

-- PROJECT TABLES ----------------------------------------------------------

create table if not exists sc_projects (
	project_sys_group_id int primary key not null,
	sc_internal_project_id varchar(32) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	department_id varchar(32),
	estimated_submission timestamp,
	initial_mou_end timestamp,
	marketing_sys_location_id int,
	modified_at timestamp not null default CURRENT_TIMESTAMP,
	mou_start timestamp,
	mou_end timestamp,
	name varchar(32) unique not null,
	primary_sys_location_id int,
	root_directory_sc_directory_id int,
	status sc_enum_project_status,
	status_changed_at timestamp,
	step sc_enum_project_step,
	owning_organization_sys_group_id int,
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (root_directory_sc_directory_id) references sc_directories(sc_directory_id)
);

create table if not exists sc_project_locations (
    project_sys_group_id int not null,
    sys_location_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (project_sys_group_id, sys_location_id),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (sys_location_id) references sys_locations(sys_location_id)
);

create table if not exists sc_project_members (
    project_sys_group_id int not null,
    sys_person_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (project_sys_group_id, sys_person_id),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_engagements (
	sc_eng_id serial primary key,
	name varchar(255) unique not null,
	ISO_639 char(3) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (ISO_639) references sil_table_of_languages(ISO_639)
);

create table if not exists sc_projects_to_engagements (
	sys_group_id int not null,
	sc_eng_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_group_id, sc_eng_id),
	foreign key (sys_group_id) references sc_projects(sys_group_id),
	foreign key (sc_eng_id) references sc_engagements(sc_eng_id)
);







-- CRM TABLES, WIP ------------------------------------------------------------------

create table if not exists sc_org_to_org_rels (
    from_sys_group_id varchar(32) not null,
    to_sys_group_id varchar(32) not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (from_sys_group_id, to_sc_internal_org_id),
    foreign key (from_sys_group_id) references sc_organizations(sys_group_id),
    foreign key (to_sys_group_id) references sc_organizations(sys_group_id)
);

create table if not exists sc_partner_performance (
    sc_internal_org_id varchar(32) not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_internal_org_id),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);

create table if not exists sc_partner_finances (
    sc_internal_org_id varchar(32) not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_internal_org_id),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);

create table if not exists sc_partner_reporting (
    sc_internal_org_id varchar(32) not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_internal_org_id),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);

create table if not exists sc_partner_translation_progress (
    sc_internal_org_id varchar(32) not null,
    sc_internal_project_id varchar(32) not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_internal_org_id, sc_internal_project_id),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);

create table if not exists sc_partner_notes (
    sc_internal_org_id varchar(32) not null,
    author_sys_person_id int not null,
    note_text text not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_internal_org_id, author_sys_person_id, created_at),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id),
    foreign key (author_sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_org_transitions (
    sc_internal_org_id varchar(32) not null,
    transition_type sc_enum_org_transitions not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_internal_org_id),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);

create table if not exists sc_roles (
    sc_role_id serial primary key,
    name varchar(32) unique not null,
    created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sc_role_memberships (
    sys_person_id int not null,
    sc_role_id int not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sys_person_id, sc_role_id),
    foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_person_to_person_rels (
    from_sys_person_id int not null,
    to_sys_person_id int not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (from_sys_person_id, to_sys_person_id),
    foreign key (from_sys_person_id) references sys_people(sys_person_id),
    foreign key (to_sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sys_people_transitions (
    sys_person_id int not null,
    transition_type sc_enum_people_transitions not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sys_person_id, transition_type),
    foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_involvements (
    sc_internal_org_id varchar(32) not null,
    type sc_enum_involvements not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sc_internal_org_id, type),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);