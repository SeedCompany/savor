-- system schema. org specific schema should go in an org-specific file.

-- ENUMS ----

set schema 'public';

DO $$ BEGIN
    create type access_level as enum (
          'Read',
          'Write',
          'Admin'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type mime_type as enum (
          'A',
          'B',
          'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type sensitivity as enum (
		'Low',
		'Medium',
		'High'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;


-- ROLES --------------------------------------------------------------------

create table if not exists sys_roles (
	sys_role_id serial primary key,
	sys_org_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	name varchar(255) not null,
	unique (sys_org_id, name)
);

create table if not exists sys_roles_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_role_id int,
	sys_org_id int,
	created_at timestamp,
	name varchar(255)
);

DO $$ BEGIN
    create type table_name as enum (
		'sys_scripture_references',
		'sys_locations',
		'sil_language_codes',
		'sil_country_codes',
		'sil_language_index',
		'sil_table_of_languages',
		'sys_people',
		'sys_people_history',
		'sys_education_entries',
		'sys_education_by_person',
		'sys_organizations',
		'sys_people_to_org_relationships',
		'sys_people_to_org_relationship_type',
		'sys_roles',
		'sys_role_grants',
		'sys_role_memberships',
		'sys_users',
		'sys_projects',
		'sys_tokens',

		'sc_funding_account',
		'sc_field_zone',
		'sc_field_regions',
		'sc_locations',
		'sc_organizations',
		'sc_organization_locations',
		'sc_partners',
		'sc_language_goal_definitions',
		'sc_languages',
		'sc_language_locations',
		'sc_language_goals',
		'sc_known_languages_by_person',
		'sc_people',
		'sc_person_unavailabilities',
		'sc_directories',
		'sc_files',
		'sc_file_versions',
		'sc_projects',
		'sc_partnerships',
		'sc_budgets',
		'sc_budget_records',
		'sc_project_locations',
		'sc_project_members',
		'sc_project_member_roles',
		'sc_language_engagements',
		'sc_products',
		'sc_product_scripture_references',
		'sc_internship_engagements',
		'sc_ceremonies'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sys_role_grants (
	sys_role_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	table_name table_name not null,
	column_name varchar(32) not null,
	access_level access_level not null,
	primary key (sys_role_id, table_name, column_name, access_level),
	foreign key (sys_role_id) references sys_roles(sys_role_id)
);

create table if not exists sys_role_grants_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_role_id int,
	created_at timestamp,
	table_name table_name,
	column_name varchar(32),
	access_level access_level
);

create table if not exists sys_role_memberships (
	sys_person_id int,
	sys_role_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_role_id) references sys_roles(sys_role_id)
);

create table if not exists sys_role_memberships_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_person_id int,
	sys_role_id int,
	created_at timestamp
);

-- SCRIPTURE REFERENCE -----------------------------------------------------------------

-- todo
DO $$ BEGIN
    create type book_name as enum (
          'Genesis',
          'Matthew',
          'Revelation'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sys_scripture_references (
    sys_scripture_reference_id serial primary key,
    book_start book_name,
    book_end book_name,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    chapter_start int,
    chapter_end int,
    verse_start int,
    verse_end int,
    unique (book_start, book_end, chapter_start, chapter_end, verse_start, verse_end)
);

-- LOCATION -----------------------------------------------------------------

DO $$ BEGIN
    create type location_type as enum (
          'City',
          'County',
          'State',
		  'Country',
          'CrossBorderArea'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sys_locations (
	sys_location_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	name varchar(255) unique not null,
	sensitivity sensitivity not null default 'High',
	type location_type not null
);

create table if not exists sys_locations_security (
    __sys_person_id int not null,
    -- __sys_location_id int not null,
	_sys_location_id access_level,
	_created_at access_level,
	_name access_level,
	_sensitivity access_level,
	_type access_level
	-- foreign key (__sys_location_id) references sys_locations(sys_location_id)
);

create table if not exists sys_locations_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_location_id int,
	created_at timestamp,
	name varchar(255),
	sensitivity sensitivity,
	type location_type
);

CREATE OR REPLACE FUNCTION locations_history_fn()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
  AS $$
begin
    insert into sys_locations_history("sys_location_id", "created_at", "name", "sensitivity", "type")
    values (new.sys_location_id, new.created_at, new.name, new.sensitivity, new.type);
	RETURN NEW;
end; $$;

DROP TRIGGER IF EXISTS locations_history_insert_trigger ON public.sys_locations;
CREATE TRIGGER locations_history_insert_trigger
  AFTER INSERT
  ON sys_locations
  FOR EACH ROW
  EXECUTE PROCEDURE locations_history_fn();

DROP TRIGGER IF EXISTS locations_history_update_trigger ON public.sys_locations;
CREATE TRIGGER locations_history_update_trigger
  AFTER UPDATE
  ON sys_locations
  FOR EACH ROW
  EXECUTE PROCEDURE locations_history_fn();

create materialized view if not exists sys_locations_secure_view as
    select
 		__sys_person_id,
 		__sys_location_id,
 		case when _sys_location_id = 'Read' or _sys_location_id = 'Write' then sys_location_id end sys_location_id,
 		case when _created_at = 'Read' or _created_at = 'Write' then created_at end created_at,
 		case when _name = 'Read' or _name = 'Write' then name end "name",
 		case when _sensitivity = 'Read' or _sensitivity = 'Write' then sensitivity end sensitivity,
 		case when _type = 'Read' or _type = 'Write' then type end "type"
  	from sys_locations_security
  	join sys_locations
  	on sys_locations_security.__sys_location_id = sys_locations.sys_location_id
with no data;

REFRESH MATERIALIZED VIEW sys_locations_secure_view;

CREATE UNIQUE INDEX IF NOT EXISTS sys_locations_secure_view_uniq
    ON sys_locations_secure_view (__sys_person_id, __sys_location_id);

CREATE INDEX IF NOT EXISTS sys_locations_secure_view_lookup
    ON sys_locations_secure_view (__sys_person_id);

-- LANGUAGE -----------------------------------------------------------------

-- sil tables are copied from SIL schema docs
-- https://www.ethnologue.com/codes/code-table-structure
-- http://www.ethnologue.com/sites/default/files/Ethnologue-19-Global%20Dataset%20Doc.pdf
CREATE TABLE if not exists sil_language_codes (
   lang_id char(3) not null,  -- Three-letter code
   country_id char(2) not null,  -- Main country where used
   lang_status char(1) not null,  -- L(iving), (e)X(tinct)
   name varchar(75) not null   -- Primary name in that country
);

CREATE TABLE if not exists sil_language_codes_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
   lang_id char(3),
   country_id char(2),
   lang_status char(1),
   name varchar(75)
);

CREATE TABLE if not exists sil_country_codes (
   country_id char(2) not null,  -- Two-letter code from ISO3166
   name varchar(75) not null,  -- Country name
   area varchar(10) not null -- World area
);

CREATE TABLE if not exists sil_country_codes_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
   country_id char(2),
   name varchar(75),
   area varchar(10)
);

CREATE TABLE if not exists sil_language_index (
   lang_id char(3) not null,  -- Three-letter code for language
   country_id char(2) not null,  -- Country where this name is used
   name_type char(2) not null,  -- L(anguage), LA(lternate),
                                -- D(ialect), DA(lternate)
                                -- LP,DP (a pejorative alternate)
   name  varchar(75) not null
);

CREATE TABLE if not exists sil_language_index_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
   lang_id char(3),
   country_id char(2),
   name_type char(2),
   name  varchar(75)
);

create table if not exists sil_table_of_languages (
    sil_ethnologue_id serial primary key,
    sil_ethnologue_legacy_id varchar(32),
	iso_639 char(3),
	created_at timestamp not null default CURRENT_TIMESTAMP,
	code varchar(32),
	language_name varchar(50) not null,
	population int,
	provisional_code varchar(32)
);

create table if not exists sil_table_of_languages_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sil_ethnologue_id int,
    sil_ethnologue_legacy_id varchar(32),
	iso_639 char(3),
	created_at timestamp,
	code varchar(32),
	language_name varchar(50),
	population int,
	provisional_code varchar(32)
);

-- PEOPLE ------------------------------------------------------------

create table if not exists sys_people (
    sys_person_id serial primary key,
    about text,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    phone varchar(32),
	picture varchar(255),
    primary_sys_org_id int,
    private_first_name varchar(32),
    private_last_name varchar(32),
    public_first_name varchar(32),
    public_last_name varchar(32),
    primary_sys_location_id int,
    private_full_name varchar(64),
    public_full_name varchar(64),
    time_zone varchar(32),
    title varchar(255),
    --foreign key (primary_sys_org_id) references sys_organizations(sys_org_id),
    foreign key (primary_sys_location_id) references sys_locations(sys_location_id)
);

create table if not exists sys_people_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_person_id int,
    about text,
    created_at timestamp,
    phone varchar(32),
	picture varchar(255),
    primary_sys_org_id int,
    private_first_name varchar(32),
    private_last_name varchar(32),
    public_first_name varchar(32),
    public_last_name varchar(32),
    primary_sys_location_id int,
    private_full_name varchar(64),
    public_full_name varchar(64),
    time_zone varchar(32),
    title varchar(255)
);

-- fkey for sys_role_memberships
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sys_role_memberships_person_id_fkey') THEN
        ALTER TABLE sys_role_memberships
            ADD CONSTRAINT sys_role_memberships_person_id_fkey
            foreign key (sys_person_id) references sys_people(sys_person_id);
    END IF;
END;
$$;

create table if not exists sys_people_security (
    _sys_person_id int,
    sys_person_id access_level,
    about access_level,
    created_at access_level,
    phone access_level,
	picture access_level,
    primary_sys_org_id access_level,
    private_first_name access_level,
    private_last_name access_level,
    public_first_name access_level,
    public_last_name access_level,
    primary_sys_location_id access_level,
    private_full_name access_level,
    public_full_name access_level,
    time_zone access_level,
    title access_level,
    foreign key (_sys_person_id) references sys_people(sys_person_id)
);

-- Education

create table if not exists sys_education_entries (
    sys_education_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
    degree varchar(64),
    institution varchar(64),
    major varchar(64)
);

create table if not exists sys_education_entries_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_education_id int,
	created_at timestamp,
    degree varchar(64),
    institution varchar(64),
    major varchar(64)
);

create table if not exists sys_education_by_person (
    sys_person_id int not null,
    sys_education_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
    graduation_year int,
	foreign key (sys_person_id) references sys_people(sys_person_id),
	foreign key (sys_education_id) references sys_education_entries(sys_education_id)
);

create table if not exists sys_education_by_person_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_person_id int,
    sys_education_id int,
	created_at timestamp,
    graduation_year int
);

-- ORGANIZATIONS ------------------------------------------------------------

create table if not exists sys_organizations (
	sys_org_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	name varchar(255) unique not null,
	primary_sys_location_id int,
	foreign key (primary_sys_location_id) references sys_locations(sys_location_id)
);

-- fkey for sys_people
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'primary_sys_org_id_fkey') THEN
        ALTER TABLE sys_people
            ADD CONSTRAINT primary_sys_org_id_fkey
            foreign key (primary_sys_org_id) references sys_organizations(sys_org_id);
    END IF;
END;
$$;

-- fkey for sys_roles
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sys_role_org_id_fkey') THEN
        ALTER TABLE sys_roles
            ADD CONSTRAINT sys_role_org_id_fkey
            foreign key (sys_org_id) references sys_organizations(sys_org_id);
    END IF;
END;
$$;

create table if not exists sys_organizations_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_org_id int,
	created_at timestamp,
	name varchar(255),
	primary_sys_location_id int
);

DO $$ BEGIN
    create type person_to_org_relationship_type as enum (
          'Vendor',
          'Customer',
          'Investor',
          'Associate',
          'Employee',
          'Member',
		  'Executive',
		  'President/CEO',
          'Board of Directors',
          'Retired',
          'Other'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sys_people_to_org_relationships (
    sys_people_to_org_id serial primary key,
	sys_org_id int,
	sys_person_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_org_id) references sys_organizations(sys_org_id),
	foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sys_people_to_org_relationships_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_people_to_org_id int,
	sys_org_id int,
	sys_person_id int,
	created_at timestamp
);

create table if not exists sys_people_to_org_relationship_type (
    sys_people_to_org_id int,
    begin_at timestamp not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	end_at timestamp,
	relationship_type person_to_org_relationship_type,
	foreign key (sys_people_to_org_id) references sys_people_to_org_relationships(sys_people_to_org_id)
);

create table if not exists sys_people_to_org_relationship_type_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    sys_people_to_org_id int,
    begin_at timestamp,
	created_at timestamp,
	end_at timestamp,
	relationship_type person_to_org_relationship_type
);

-- USERS ---------------------------------------------------------------------

create table if not exists sys_users(
	sys_person_id int primary key,
	owning_sys_org_id int not null,
	email varchar(255) unique not null,
	password varchar(255) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_person_id) references sys_people(sys_person_id),
	foreign key (owning_sys_org_id) references sys_organizations(sys_org_id)
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'loc_sec_sys_person_id_fkey') THEN
        ALTER TABLE sys_locations_security
            ADD CONSTRAINT loc_sec_sys_person_id_fkey
            foreign key (__sys_person_id) references sys_users(sys_person_id);
    END IF;
END;
$$;

create table if not exists sys_users_history(
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_person_id int,
	owning_sys_org_id int,
	email varchar(255),
	password varchar(255),
	created_at timestamp
);

-- PROJECTS ------------------------------------------------------------------

create table if not exists sys_projects (
	sys_project_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	name varchar(32) not null,
	primary_sys_org_id int,
	primary_sys_location_id int,
	unique (primary_sys_org_id, name),
	foreign key (primary_sys_org_id) references sys_organizations(sys_org_id),
	foreign key (primary_sys_location_id) references sys_locations(sys_location_id)
);

create table if not exists sys_projects_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	sys_project_id int,
	created_at timestamp,
	name varchar(32),
	primary_sys_org_id int,
	primary_sys_location_id int
);

-- AUTHENTICATION ------------------------------------------------------------

create table if not exists sys_tokens (
	token varchar(512) primary key,
	sys_person_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_person_id) references sys_people(sys_person_id)
);