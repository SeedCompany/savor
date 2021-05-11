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

-- todo
DO $$ BEGIN
    create type sc_enum_budget_status as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_engagement_status as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_project_engagement_tag as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_internship_methodology as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_internship_position as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_product_mediums as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_product_methodologies as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_product_purposes as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_product_type as enum (
		'Film',
		'Literacy Material',
		'Scripture',
		'Song',
		'Story'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_change_to_plan_type as enum (
		'a',
		'b',
		'c'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_enum_change_to_plan_status as enum (
		'a',
		'b',
		'c'
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
	foreign key (director_sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_field_regions (
	sc_field_region_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	director_sys_person_id int,
	name varchar(32) unique not null,
	foreign key (director_sys_person_id) references sys_people(sys_person_id)
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
	foreign key (sys_group_id) references sys_groups(sys_group_id),
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
	point_of_contact_sys_person_id int,
	foreign key (point_of_contact_sys_person_id) references sys_people(sys_person_id),
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
    known_language_ISO_639 char(3) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_person_id) references sys_people(sys_person_id),
	foreign key (known_language_ISO_639) references sil_table_of_languages(ISO_639)
);

create table if not exists sc_people_ext_sys_people (
    sys_person_id int primary key,
    sc_internal_person_id varchar(32) unique,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	skills varchar(32)[],
	status varchar(32),
	foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_person_unavailabilities (
    sys_person_id int primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	description text,
	period_end timestamp not null,
	period_start timestamp not null,
	foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_roles_ext_sys_groups (
    sys_group_id int primary key,
    name varchar(255) unique not null,
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
	created_at timestamp not null default CURRENT_TIMESTAMP
	-- todo
);

create table if not exists sc_files (
    sc_file_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	creator_sys_person_id int not null,
	name varchar(255),
    sc_directory_id int not null,
	foreign key (sc_directory_id) references sc_directories(sc_directory_id),
	foreign key (creator_sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_file_versions (
    sc_file_version_id serial primary key,
    category varchar(255),
	created_at timestamp not null default CURRENT_TIMESTAMP,
    creator_sys_person_id int not null,
    mime_type enum_mime_type not null,
    name varchar(255) not null,
    sc_file_id int not null,
    sc_file_url varchar(255) not null,
    file_size int, -- bytes
    foreign key (sc_file_id) references sc_files(sc_file_id),
	foreign key (creator_sys_person_id) references sys_people(sys_person_id)
);

-- PROJECT TABLES ----------------------------------------------------------

create table if not exists sc_change_to_plans (
    sc_change_to_plan_id serial primary key,
    type sc_enum_change_to_plan_type,
    summary text,
    status sc_enum_change_to_plan_status,
	created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sc_projects (
	project_sys_group_id int not null,
	sc_change_to_plan_id int not null default 0,
	sc_internal_project_id varchar(32) not null,
	active bool,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	department_id varchar(32),
	estimated_submission timestamp,
	field_region_sys_location_id int,
	initial_mou_end timestamp,
	marketing_sys_location_id int,
	modified_at timestamp not null default CURRENT_TIMESTAMP,
	mou_start timestamp,
	mou_end timestamp,
	name varchar(32) unique not null,
	owning_organization_sys_group_id int,
	primary_sys_location_id int,
	root_directory_sc_directory_id int,
	status sc_enum_project_status,
	status_changed_at timestamp,
	step sc_enum_project_step,
	primary key (project_sys_group_id, sc_change_to_plan_id),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (root_directory_sc_directory_id) references sc_directories(sc_directory_id),
	foreign key (field_region_sys_location_id) references sys_locations(sys_location_id),
	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_partnerships (
    project_sys_group_id int not null,
    partner_sys_group_id int not null,
    sc_change_to_plan_id int not null default 0,
    active bool,
    agreement_sc_file_version_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (project_sys_group_id, partner_sys_group_id, sc_change_to_plan_id),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (partner_sys_group_id) references sys_groups(sys_group_id),
	foreign key (agreement_sc_file_version_id) references sc_file_versions(sc_file_version_id),
	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_budgets (
    sc_budget_id serial primary key,
    project_sys_group_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
    status sc_enum_budget_status,
    universal_template_sys_file_id int,
    universal_template_file_url varchar(255),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (universal_template_sys_file_id) references sc_file_versions(sc_file_version_id)
);

create table if not exists sc_budget_records (
    sc_budget_id int not null,
    sc_change_to_plan_id int not null default 0,
    active bool,
    amount decimal,
    fiscal_year int,
    partnership_sys_group_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sc_budget_id, sc_change_to_plan_id),
	foreign key (sc_budget_id) references sc_budgets(sc_budget_id),
	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_project_locations (
    project_sys_group_id int not null,
    sys_location_id int not null,
    sc_change_to_plan_id int not null default 0,
    active bool,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (project_sys_group_id, sys_location_id, sc_change_to_plan_id),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (sys_location_id) references sys_locations(sys_location_id),
	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_project_members (
    project_sys_group_id int not null,
    sys_person_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	modified_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (project_sys_group_id, sys_person_id),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_project_member_roles (
    project_sys_group_id int not null,
    sys_person_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	modified_at timestamp not null default CURRENT_TIMESTAMP,
	role_sys_group_id int,
	primary key (project_sys_group_id, sys_person_id),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (sys_person_id) references sys_people(sys_person_id),
	foreign key (role_sys_group_id) references sys_groups(sys_group_id)
);

create table if not exists sc_language_engagements (
	project_sys_group_id int not null,
	ISO_639 char(3) not null,
	sc_change_to_plan_id int not null default 0,
    active bool,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	communications_complete_date timestamp,
	complete_date timestamp,
	disbursement_complete_date timestamp,
	end_date timestamp,
	end_date_override timestamp,
	initial_end_date timestamp,
	is_first_scripture bool,
	is_luke_partnership bool,
	is_sent_printing bool,
	last_reactivated_at timestamp,
	paratext_registry_id varchar(32),
	pnp varchar(255),
	pnp_sc_file_version_id int,
	product_engagement_tag sc_enum_project_engagement_tag,
	start_date timestamp,
	start_date_override timestamp,
	status sc_enum_engagement_status,
	updated_at timestamp,
	primary key (project_sys_group_id, ISO_639, sc_change_to_plan_id),
	foreign key (ISO_639) references sil_table_of_languages(ISO_639),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (pnp_sc_file_version_id) references sc_file_versions(sc_file_version_id),
	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_products (
    sc_product_id serial unique not null,
    sc_change_to_plan_id int not null default 0,
    active bool,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    mediums sc_enum_product_mediums[],
    methodologies sc_enum_product_methodologies[],
    purposes sc_enum_product_purposes[],
    type sc_enum_product_type,
    name varchar(64),
    primary key (sc_product_id, sc_change_to_plan_id),
    foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_product_scripture_references (
    sc_product_id int not null,
    sys_scripture_reference_id int not null,
    sc_change_to_plan_id int not null default 0,
    active bool,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_product_id, sys_scripture_reference_id, sc_change_to_plan_id),
    foreign key (sc_product_id) references sc_products(sc_product_id),
    foreign key (sys_scripture_reference_id) references sys_scripture_references(sys_scripture_reference_id),
    foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_internship_engagements (
	project_sys_group_id int not null,
	ISO_639 char(3) not null,
	sc_change_to_plan_id int not null default 0,
    active bool,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	communications_complete_date timestamp,
	complete_date timestamp,
	country_of_origin_sys_location_id int,
	disbursement_complete_date timestamp,
	end_date timestamp,
	end_date_override timestamp,
	growth_plan_sc_file_version_id int,
	initial_end_date timestamp,
	intern_sys_person_id int,
	last_reactivated_at timestamp,
	mentor_sys_person_id int,
	methodology sc_enum_internship_methodology,
	paratext_registry_id varchar(32),
	position sc_enum_internship_position,
	start_date timestamp,
	start_date_override timestamp,
	status sc_enum_engagement_status,
	updated_at timestamp,
	primary key (project_sys_group_id, ISO_639, sc_change_to_plan_id),
	foreign key (ISO_639) references sil_table_of_languages(ISO_639),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (country_of_origin_sys_location_id) references sys_locations(sys_location_id),
	foreign key (growth_plan_sc_file_version_id) references sc_file_versions(sc_file_version_id),
	foreign key (intern_sys_person_id) references sys_people(sys_person_id),
	foreign key (mentor_sys_person_id) references sys_people(sys_person_id),
	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_ceremonies (
    sc_ceremony_id serial primary key,
    project_sys_group_id int not null,
	ISO_639 char(3) not null,
	actual_date timestamp,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	estimated_date timestamp,
	is_planned bool,
	type varchar(255),
	foreign key (ISO_639) references sil_table_of_languages(ISO_639),
    foreign key (project_sys_group_id) references sys_groups(sys_group_id)
);




-- CRM TABLES, WIP ------------------------------------------------------------------
--
--create table if not exists sc_org_to_org_rels (
--    from_sys_group_id varchar(32) not null,
--    to_sys_group_id varchar(32) not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (from_sys_group_id, to_sys_group_id),
--    foreign key (from_sys_group_id) references sc_organizations(sys_group_id),
--    foreign key (to_sys_group_id) references sc_organizations(sys_group_id)
--);
--
--create table if not exists sc_partner_performance (
--    sc_internal_org_id varchar(32) not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (sc_internal_org_id),
--    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
--);
--
--create table if not exists sc_partner_finances (
--    sc_internal_org_id varchar(32) not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (sc_internal_org_id),
--    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
--);
--
--create table if not exists sc_partner_reporting (
--    sc_internal_org_id varchar(32) not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (sc_internal_org_id),
--    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
--);
--
--create table if not exists sc_partner_translation_progress (
--    sc_internal_org_id varchar(32) not null,
--    sc_internal_project_id varchar(32) not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (sc_internal_org_id, sc_internal_project_id),
--    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
--);
--
--create table if not exists sc_partner_notes (
--    sc_internal_org_id varchar(32) not null,
--    author_sys_person_id int not null,
--    note_text text not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (sc_internal_org_id, author_sys_person_id, created_at),
--    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id),
--    foreign key (author_sys_person_id) references sys_people(sys_person_id)
--);
--
--create table if not exists sc_org_transitions (
--    sc_internal_org_id varchar(32) not null,
--    transition_type sc_enum_org_transitions not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (sc_internal_org_id),
--    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
--);
--
--create table if not exists sc_roles (
--    sc_role_id serial primary key,
--    name varchar(32) unique not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP
--);
--
--create table if not exists sc_role_memberships (
--    sys_person_id int not null,
--    sc_role_id int not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (sys_person_id, sc_role_id),
--    foreign key (sys_person_id) references sys_people(sys_person_id)
--);
--
--create table if not exists sc_person_to_person_rels (
--    from_sys_person_id int not null,
--    to_sys_person_id int not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (from_sys_person_id, to_sys_person_id),
--    foreign key (from_sys_person_id) references sys_people(sys_person_id),
--    foreign key (to_sys_person_id) references sys_people(sys_person_id)
--);
--
--create table if not exists sys_people_transitions (
--    sys_person_id int not null,
--    transition_type sc_enum_people_transitions not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (sys_person_id, transition_type),
--    foreign key (sys_person_id) references sys_people(sys_person_id)
--);
--
--create table if not exists sc_involvements (
--    sc_internal_org_id varchar(32) not null,
--    type sc_enum_involvements not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--	primary key (sc_internal_org_id, type),
--    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
--);