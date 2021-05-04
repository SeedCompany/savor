-- Seed Company Schema -------------------------------------------------------------

-- ENUMs ----------------------------------------------------------

DO $$ BEGIN
    create type sc_enum_involvements as enum (
		'CIT',
		'ENGAGEMENTS'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_enum_people_transitions as enum (
		'NEW ORG',
		'OTHER'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_enum_org_transitions as enum (
		'TO MANAGER',
		'OTHER'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_enum_sensitivity as enum (
		'LOW',
		'MEDIUM',
		'HIGH'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_enum_location_type as enum (
		'MARKETING'
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

create table if not exists sc_locations (
	sc_location_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	default_sc_field_region_id int,
	funding_account_number varchar(32),
	iso_alpha_3 char(3),
	name varchar(32) unique not null,
	type sc_enum_location_type not null,
	foreign key (funding_account_number) references sc_funding_account(account_number)
);

-- ORGANIZATION TABLES

create table if not exists sc_org_to_org_rels (
    from_sc_internal_org_id varchar(32) not null,
    to_sc_internal_org_id varchar(32) not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (from_sc_internal_org_id, to_sc_internal_org_id),
    foreign key (from_sc_internal_org_id) references sc_organizations(sc_internal_org_id),
    foreign key (to_sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);

create table if not exists sc_organizations(
	sys_org_id int primary key not null,
	sc_internal_org_id varchar(32) unique not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_org_id) references sys_organizations(sys_org_id)
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

-- USER TABLES --------------------------------------------------------------

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

-- LANGUAGE TABLES ----------------------------------------------------------

create table if not exists sil_ethnologue_entry (
	sil_eth_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	code varchar(32),
	name varchar(255) unique not null,
	population int,
	provisional_code varchar(32)
);

create table if not exists sc_language_goal_definitions (
	sc_goal_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP
	-- todo
);

create table if not exists sc_languages (
	sc_lang_id serial primary key,
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
	sil_eth_id int
);

create table if not exists sc_language_locations (
	sc_lang_id int not null,
	sc_location_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sc_lang_id, sc_location_id)
	-- todo
);

create table if not exists sc_language_goals (
    sc_lang_id int not null,
	sc_goal_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sc_lang_id, sc_goal_id)
	-- todo
);

-- PROJECT TABLES ----------------------------------------------------------

create table if not exists sc_projects (
	sys_group_id int primary key not null,
	sc_internal_project_id varchar(32) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_group_id) references sys_groups(sys_group_id)
);

create table if not exists sc_engagements (
	sc_eng_id serial primary key,
	name varchar(255) unique not null,
	sc_lang_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sc_lang_id) references sc_languages(sc_lang_id)
);

create table if not exists sc_projects_to_engagements (
	sys_group_id int not null,
	sc_eng_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_group_id, sc_eng_id),
	foreign key (sys_group_id) references sc_projects(sys_group_id),
	foreign key (sc_eng_id) references sc_engagements(sc_eng_id)
);

create table if not exists sc_involvements (
    sc_internal_org_id varchar(32) not null,
    type sc_enum_involvements not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sc_internal_org_id, type),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);



