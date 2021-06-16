-- Seed Company Schema -------------------------------------------------------------

-- ENUMs ----------------------------------------------------------


-- ACCOUNTING TABLES --------------------------------------------------------

create table if not exists sc_funding_account (
	account_number varchar(32) not null primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	name varchar(32)
);

create table if not exists sc_funding_account_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	account_number varchar(32),
	created_at timestamp,
	name varchar(32)
);
https://wiki.seedconnect.org/admin/attachmentstoragesetup.action
admin/attachmentstoragesetup.action
/var/atlassian/application-data/confluence/attachments/ver003
-- LOCATION TABLES ----------------------------------------------------------

create table if not exists sc_field_zone (
	sc_field_zone_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	director_sys_person_id int,
	name varchar(32) unique not null,
	foreign key (director_sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_field_zone_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sc_field_zone_id int,
	created_at timestamp,
	director_sys_person_id int,
	name varchar(32)
);

create table if not exists sc_field_regions (
	sc_field_region_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	director_sys_person_id int,
	name varchar(32) unique not null,
	foreign key (director_sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_field_regions_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sc_field_region_id int,
	created_at timestamp,
	director_sys_person_id int,
	name varchar(32)
);

create table if not exists sc_locations (
	sys_location_id int primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	default_sc_field_region_id int,
	funding_account_number varchar(32),
	iso_alpha_3 char(3),
	name varchar(32) unique not null,
	type location_type not null,
	foreign key (sys_location_id) references sys_locations(sys_location_id),
	foreign key (funding_account_number) references sc_funding_account(account_number)
);

create table if not exists sc_locations_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_location_id int,
	created_at timestamp,
	default_sc_field_region_id int,
	funding_account_number varchar(32),
	iso_alpha_3 char(3),
	name varchar(32),
	type location_type
);

-- ORGANIZATION TABLES

create table if not exists sc_organizations (
	sys_org_id int primary key not null,
	address varchar(255),
	created_at timestamp not null default CURRENT_TIMESTAMP,
	sc_internal_org_id varchar(32) unique not null,
	foreign key (sys_org_id) references sys_organizations(sys_org_id)
);

create table if not exists sc_organizations_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_org_id int,
	address varchar(255),
	created_at timestamp,
	sc_internal_org_id varchar(32)
);

create table if not exists sc_organization_locations(
	sys_org_id int not null,
	sys_location_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_org_id, sys_location_id),
	foreign key (sys_org_id) references sys_organizations(sys_org_id),
	foreign key (sys_location_id) references sys_locations(sys_location_id)
);

create table if not exists sc_organization_locations_history(
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_org_id int,
	sys_location_id int,
	created_at timestamp
);

DO $$ BEGIN
    create type sc_financial_reporting_types as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_partner_types as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_partners (
	sys_org_id int primary key,
	active bool,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	financial_reporting_types sc_financial_reporting_types[],
	is_global_innovations_client bool,
	modified_at timestamp not null default CURRENT_TIMESTAMP,
	pmc_entity_code varchar(32),
	point_of_contact_sys_person_id int,
	foreign key (point_of_contact_sys_person_id) references sys_people(sys_person_id),
	types sc_partner_types[],
	foreign key (sys_org_id) references sys_organizations(sys_org_id)
);

create table if not exists sc_partners_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_org_id int,
	active bool,
	created_at timestamp,
	financial_reporting_types sc_financial_reporting_types[],
	is_global_innovations_client bool,
	modified_at timestamp,
	pmc_entity_code varchar(32),
	point_of_contact_sys_person_id int,
	types sc_partner_types[]
);

-- LANGUAGE TABLES ----------------------------------------------------------

create table if not exists sc_language_goal_definitions (
	sc_goal_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP
	-- todo
);

create table if not exists sc_language_goal_definitions_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sc_goal_id int,
	created_at timestamp
	-- todo
);

create table if not exists sc_languages (
	sil_ethnologue_id int primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	is_dialect bool,
	is_sign_language bool,
	is_least_of_these bool,
--	display_name varchar(255) unique not null,
	least_of_these_reason varchar(255),
	name varchar(255) unique not null,
	population_override int,
	registry_of_dialects_code varchar(32),
	sensitivity sensitivity,
	sign_language_code varchar(32),
	sponsor_estimated_eng_date timestamp,
	foreign key (sil_ethnologue_id) references sil_table_of_languages(sil_ethnologue_id)
);

create table if not exists sc_languages_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sil_ethnologue_id int,
	created_at timestamp,
	is_dialect bool,
	is_sign_language bool,
	is_least_of_these bool,
--	display_name varchar(255) unique not null,
	least_of_these_reason varchar(255),
	name varchar(255),
	population_override int,
	registry_of_dialects_code varchar(32),
	sensitivity sensitivity,
	sign_language_code varchar(32),
	sponsor_estimated_eng_date timestamp
);

create table if not exists sc_language_locations (
	sil_ethnologue_id int not null,
	sys_location_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sil_ethnologue_id, sys_location_id),
	foreign key (sil_ethnologue_id) references sil_table_of_languages(sil_ethnologue_id)
	-- todo
);

create table if not exists sc_language_locations_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sil_ethnologue_id int,
	sys_location_id int,
	created_at timestamp
	-- todo
);

create table if not exists sc_language_goals (
    sil_ethnologue_id int not null,
	sc_goal_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sil_ethnologue_id, sc_goal_id),
	foreign key (sil_ethnologue_id) references sil_table_of_languages(sil_ethnologue_id)
	-- todo
);

create table if not exists sc_language_goals_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sil_ethnologue_id int,
	sc_goal_id int,
	created_at timestamp
	-- todo
);

-- USER TABLES --------------------------------------------------------------

create table if not exists sc_known_languages_by_person (
    sys_person_id int not null,
    known_language_sil_ethnologue_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_person_id) references sys_people(sys_person_id),
	foreign key (known_language_sil_ethnologue_id) references sil_table_of_languages(sil_ethnologue_id)
);

create table if not exists sc_known_languages_by_person_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_person_id int,
    known_language_sil_ethnologue_id int,
	created_at timestamp
);

create table if not exists sc_people (
    sys_person_id int primary key,
    sc_internal_person_id varchar(32) unique,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	skills varchar(32)[],
	status varchar(32),
	foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_people_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_person_id int,
    sc_internal_person_id varchar(32),
	created_at timestamp,
	skills varchar(32)[],
	status varchar(32)
);

create table if not exists sc_person_unavailabilities (
    sys_person_id int primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	description text,
	period_end timestamp not null,
	period_start timestamp not null,
	foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_person_unavailabilities_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_person_id int,
	created_at timestamp,
	description text,
	period_end timestamp,
	period_start timestamp
);

-- FILES & DIRECTORIES ----------------------------------------------------------

create table if not exists sc_directories (
    sc_directory_id serial primary key,
    name varchar(255),
    creator_sys_person_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
    foreign key (creator_sys_person_id) references sys_people(sys_person_id)
	-- todo
);

create table if not exists sc_directories_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sc_directory_id int,
    name varchar(255),
    creator_sys_person_id int,
	created_at timestamp
	-- todo
);

create table if not exists sc_files (
    sc_file_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	creator_sys_person_id int not null,
	name varchar(255),
--  sc_directory_id int not null,
--	foreign key (sc_directory_id) references sc_directories(sc_directory_id),
	foreign key (creator_sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_files_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sc_file_id int,
	created_at timestamp,
	creator_sys_person_id int,
	name varchar(255)
--  sc_directory_id int not null
);

create table if not exists sc_file_versions (
    sc_file_version_id serial primary key,
    category varchar(255),
	created_at timestamp not null default CURRENT_TIMESTAMP,
    creator_sys_person_id int not null,
--    mime_type mime_type not null,
    name varchar(255) not null,
--    sc_file_id int not null,
--    sc_file_url varchar(255) not null,
    file_size int, -- bytes
--    foreign key (sc_file_id) references sc_files(sc_file_id),
	foreign key (creator_sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sc_file_versions_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sc_file_version_id int,
    category varchar(255),
	created_at timestamp,
    creator_sys_person_id int,
--    mime_type mime_type,
    name varchar(255),
--    sc_file_id int,
--    sc_file_url varchar(255),
    file_size int -- bytes
);

-- PROJECT TABLES ----------------------------------------------------------

-- todo
DO $$ BEGIN
    create type sc_project_step as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_project_status as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_change_to_plans (
    sc_change_to_plan_id serial primary key,
    type sc_change_to_plan_type,
    summary text,
    status sc_change_to_plan_status,
	created_at timestamp not null default CURRENT_TIMESTAMP
);

-- todo
DO $$ BEGIN
    create type sc_change_to_plan_type as enum (
		'a',
		'b',
		'c'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_change_to_plan_status as enum (
		'a',
		'b',
		'c'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_projects (
	project_sys_group_id int not null,
	sc_change_to_plan_id int not null default 0,
	sc_internal_project_id varchar(255) not null,
	active bool,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	department_id varchar(255),
	estimated_submission timestamp,
	field_region_sys_location_id int,
	initial_mou_end timestamp,
	marketing_sys_location_id int,
	modified_at timestamp not null default CURRENT_TIMESTAMP,
	mou_start timestamp,
	mou_end timestamp,
	name varchar(255) unique not null,
	owning_organization_sys_group_id int,
	primary_sys_location_id int,
	root_directory_sc_directory_id int,
	status sc_enum_project_status,
	status_changed_at timestamp,
	step sc_enum_project_step,
	primary key (project_sys_group_id, sc_change_to_plan_id),
--    primary key (project_sys_group_id),
	foreign key (project_sys_group_id) references sys_groups(sys_group_id),
	foreign key (root_directory_sc_directory_id) references sc_directories(sc_directory_id),
	foreign key (field_region_sys_location_id) references sys_locations(sys_location_id)
--	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_projects_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_project_id int,
--	sc_change_to_plan_id int,
	sc_internal_project_id varchar(32),
	active bool,
	created_at timestamp,
	department_id varchar(32),
	estimated_submission timestamp,
	field_region_sys_location_id int,
	initial_mou_end timestamp,
	marketing_sys_location_id int,
	modified_at timestamp,
	mou_start timestamp,
	mou_end timestamp,
	name varchar(32),
	owning_organization_sys_org_id int,
	primary_sys_location_id int,
	root_directory_sc_directory_id int,
	status sc_project_status,
	status_changed_at timestamp,
	step sc_project_step
);

create table if not exists sc_partnerships (
    sys_project_id int not null,
    partner_sys_org_id int not null,
--    sc_change_to_plan_id int not null default 0,
    active bool,
    agreement_sc_file_version_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_project_id, partner_sys_org_id),
--	sc_change_to_plan_id),
	foreign key (sys_project_id) references sys_projects(sys_project_id),
	foreign key (partner_sys_org_id) references sys_organizations(sys_org_id),
	--	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
	foreign key (agreement_sc_file_version_id) references sc_file_versions(sc_file_version_id)
);

create table if not exists sc_partnerships_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_project_id int,
    partner_sys_org_id int,
--    sc_change_to_plan_id int,
    active bool,
    agreement_sc_file_version_id int,
	created_at timestamp
);

-- PROJECT BUDGETS

-- todo
DO $$ BEGIN
    create type sc_budget_status as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_budgets (
    sc_budget_id serial primary key,
    sys_project_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
    status sc_budget_status,
    universal_template_sys_file_id int,
    universal_template_file_url varchar(255),
	foreign key (sys_project_id) references sys_projects(sys_project_id),
	foreign key (universal_template_sys_file_id) references sc_file_versions(sc_file_version_id)
);

create table if not exists sc_budgets_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sc_budget_id int,
    sys_project_id int,
	created_at timestamp,
    status sc_budget_status,
    universal_template_sys_file_id int,
    universal_template_file_url varchar(255)
);

create table if not exists sc_budget_records (
    sc_budget_id int not null,
--    sc_change_to_plan_id int not null default 0,
    active bool,
    amount decimal,
    fiscal_year int,
    partnership_sys_org_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sc_budget_id),
--	sc_change_to_plan_id),
	foreign key (sc_budget_id) references sc_budgets(sc_budget_id)
--	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_budget_records_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sc_budget_id int,
--    sc_change_to_plan_id int not null default 0,
    active bool,
    amount decimal,
    fiscal_year int,
    partnership_sys_org_id int,
	created_at timestamp
);

-- PROJECT LOCATION

create table if not exists sc_project_locations (
    sys_project_id int not null,
    sys_location_id int not null,
--    sc_change_to_plan_id int not null default 0,
    active bool,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sys_project_id, sys_location_id),
--	sc_change_to_plan_id),
	foreign key (sys_project_id) references sys_projects(sys_project_id),
	foreign key (sys_location_id) references sys_locations(sys_location_id)
--	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_project_locations_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_project_id int,
    sys_location_id int,
--    sc_change_to_plan_id int,
    active bool,
	created_at timestamp
);

-- LANGUAGE ENGAGEMENTS

-- todo
DO $$ BEGIN
    create type sc_engagement_status as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_project_engagement_tag as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_language_engagements (
	sys_project_id int not null,
	sil_ethnologue_id int not null,
--	sc_change_to_plan_id int not null default 0,
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
	product_engagement_tag sc_project_engagement_tag,
	start_date timestamp,
	start_date_override timestamp,
	status sc_engagement_status,
	updated_at timestamp,
	primary key (sys_project_id, sil_ethnologue_id),
--	sc_change_to_plan_id),
	foreign key (sil_ethnologue_id) references sil_table_of_languages(sil_ethnologue_id),
	foreign key (sys_project_id) references sys_projects(sys_project_id),
	foreign key (pnp_sc_file_version_id) references sc_file_versions(sc_file_version_id)
--	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_language_engagements_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_project_id int,
	sil_ethnologue_id int,
--	sc_change_to_plan_id int,
    active bool,
	created_at timestamp,
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
	product_engagement_tag sc_project_engagement_tag,
	start_date timestamp,
	start_date_override timestamp,
	status sc_engagement_status,
	updated_at timestamp
--	sc_change_to_plan_id)
);

-- PRODUCTS

-- todo
DO $$ BEGIN
    create type sc_product_mediums as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_product_methodologies as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_product_purposes as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_product_type as enum (
		'Film',
		'Literacy Material',
		'Scripture',
		'Song',
		'Story'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_products (
    sc_product_id serial unique not null,
--    sc_change_to_plan_id int not null default 0,
    active bool,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    mediums sc_product_mediums[],
    methodologies sc_product_methodologies[],
    purposes sc_product_purposes[],
    type sc_product_type,
    name varchar(64),
    primary key (sc_product_id)
--    sc_change_to_plan_id)
--    foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_products_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sc_product_id int,
--    sc_change_to_plan_id int,
    active bool,
    created_at timestamp,
    mediums sc_product_mediums[],
    methodologies sc_product_methodologies[],
    purposes sc_product_purposes[],
    type sc_product_type,
    name varchar(64)
);

create table if not exists sc_product_scripture_references (
    sc_product_id int not null,
    sys_scripture_reference_id int not null,
--    sc_change_to_plan_id int not null default 0,
    active bool,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_product_id, sys_scripture_reference_id),
--    sc_change_to_plan_id),
    foreign key (sc_product_id) references sc_products(sc_product_id),
    foreign key (sys_scripture_reference_id) references sys_scripture_references(sys_scripture_reference_id)
--    foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

-- INTERNSHIP ENGAGEMENTS

-- todo
DO $$ BEGIN
    create type sc_internship_methodology as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type sc_internship_position as enum (
		'A',
		'B',
		'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_internship_engagements (
	project_sys_org_id int not null,
	sil_ethnologue_id int not null,
--	sc_change_to_plan_id int not null default 0,
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
	methodology sc_internship_methodology,
	paratext_registry_id varchar(32),
	position sc_internship_position,
	start_date timestamp,
	start_date_override timestamp,
	status sc_engagement_status,
	updated_at timestamp,
	primary key (project_sys_org_id, sil_ethnologue_id),
--	sc_change_to_plan_id),
	foreign key (sil_ethnologue_id) references sil_table_of_languages(sil_ethnologue_id),
	foreign key (project_sys_org_id) references sys_organizations(sys_org_id),
	foreign key (country_of_origin_sys_location_id) references sys_locations(sys_location_id),
	foreign key (growth_plan_sc_file_version_id) references sc_file_versions(sc_file_version_id),
	foreign key (intern_sys_person_id) references sys_people(sys_person_id),
	foreign key (mentor_sys_person_id) references sys_people(sys_person_id)
--	foreign key (sc_change_to_plan_id) references sc_change_to_plans(sc_change_to_plan_id)
);

create table if not exists sc_internship_engagements_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	project_sys_org_id int,
	sil_ethnologue_id int,
--	sc_change_to_plan_id int,
    active bool,
	created_at timestamp,
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
	methodology sc_internship_methodology,
	paratext_registry_id varchar(32),
	position sc_internship_position,
	start_date timestamp,
	start_date_override timestamp,
	status sc_engagement_status,
	updated_at timestamp
);

create table if not exists sc_ceremonies (
    sc_ceremony_id serial primary key,
    project_sys_org_id int not null,
	sil_ethnologue_id int not null,
	actual_date timestamp,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	estimated_date timestamp,
	is_planned bool,
	type varchar(255),
	foreign key (sil_ethnologue_id) references sil_table_of_languages(sil_ethnologue_id),
    foreign key (project_sys_org_id) references sys_organizations(sys_org_id)
);

create table if not exists sc_ceremonies_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sc_ceremony_id int,
    project_sys_org_id int,
	sil_ethnologue_id int,
	actual_date timestamp,
	created_at timestamp,
	estimated_date timestamp,
	is_planned bool,
	type varchar(255)
);

-- CRM TABLES, WIP ------------------------------------------------------------------

DO $$ BEGIN
    create type sc_involvements as enum (
		'CIT',
		'Engagements'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_people_transitions as enum (
		'New Org',
		'Other'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sc_org_transitions as enum (
		'To Manager',
		'To Other'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

--
--create table if not exists sc_org_to_org_rels (
--    from_sys_org_id varchar(32) not null,
--    to_sys_org_id varchar(32) not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (from_sys_org_id, to_sys_org_id),
--    foreign key (from_sys_org_id) references sc_organizations(sys_org_id),
--    foreign key (to_sys_org_id) references sc_organizations(sys_org_id)
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
--    transition_type sc_org_transitions not null,
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
--    transition_type sc_people_transitions not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--    primary key (sys_person_id, transition_type),
--    foreign key (sys_person_id) references sys_people(sys_person_id)
--);
--
--create table if not exists sc_involvements (
--    sc_internal_org_id varchar(32) not null,
--    type sc_involvements not null,
--    created_at timestamp not null default CURRENT_TIMESTAMP,
--	primary key (sc_internal_org_id, type),
--    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
--);