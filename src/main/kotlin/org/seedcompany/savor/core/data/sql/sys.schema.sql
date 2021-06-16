-- system schema. org specific schema should go in an org-specific file.

-- ENUMS ----
create schema if not exists public;
set schema 'public';

DO $$ BEGIN
    create type public.access_level as enum (
          'Read',
          'Write',
          'Admin'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type public.mime_type as enum (
          'A',
          'B',
          'C'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

DO $$ BEGIN
    create type public.sensitivity as enum (
		'Low',
		'Medium',
		'High'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;


-- ROLES --------------------------------------------------------------------

create table if not exists public.global_roles_data (
	id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	name varchar(255) not null,
	org_id int,
	unique (org_id, name)
--	foreign key (created_by) references public.people(id),
--	foreign key (org_id) references public.organizations(id)
);

create table if not exists public.global_roles_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	created_at timestamp,
	created_by int not null default 0,
	name varchar(255),
	org_id int
);

DO $$ BEGIN
    create type public.table_name as enum (
		'public.scripture_references',
		'public.locations',
		'public.language_index',
		'public.people',
		'public.people_history',
		'public.education_entries',
		'public.education_by_person',
		'public.organizations',
		'public.people_to_org_relationships',
		'public.people_to_org_relationship_type',
		'public.global_roles',
		'public.global_role_grants',
		'public.global_role_memberships',
		'public.users',
		'public.projects',
		'public.tokens',

		'sil.language_codes',
		'sil.country_codes',
		'sil.table_of_languages',

		'sc.funding_account',
		'sc.field_zone',
		'sc.field_regions',
		'sc.locations',
		'sc.organizations',
		'sc.organization_locations',
		'sc.partners',
		'sc.language_goal_definitions',
		'sc.languages',
		'sc.language_locations',
		'sc.language_goals',
		'sc.known_languages_by_person',
		'sc.people',
		'sc.person_unavailabilities',
		'sc.directories',
		'sc.files',
		'sc.file_versions',
		'sc.projects',
		'sc.partnerships',
		'sc.budgets',
		'sc.budget_records',
		'sc.project_locations',
		'sc.project_members',
		'sc.project_member_roles',
		'sc.language_engagements',
		'sc.products',
		'sc.product_scripture_references',
		'sc.internship_engagements',
		'sc.ceremonies'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists public.global_role_grants_data (
	id serial primary key,
	access_level access_level not null,
	column_name varchar(32) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	global_role_id int not null,
	table_name table_name not null,
	unique (global_role_id, table_name, column_name, access_level),
--	foreign key (created_by_id) references public.people(id),
	foreign key (global_role_id) references public.global_roles(id)
);

create table if not exists public.global_role_grants_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	global_role_id int,
	created_at timestamp,
	created_by int,
	table_name table_name,
	column_name varchar(32),
	access_level access_level
);

create table if not exists public.global_role_memberships_data (
    id serial primary key,
	global_role_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	person_id int,
--	foreign key (created_by) references public.people(id),
	foreign key (global_role_id) references global_roles(id)
);

create table if not exists public.global_role_memberships_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	created_at timestamp,
	created_by int,
	global_role_id int,
	person_id int
);

-- SCRIPTURE REFERENCE -----------------------------------------------------------------

-- todo
DO $$ BEGIN
    create type public.book_name as enum (
          'Genesis',
          'Matthew',
          'Revelation'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists public.scripture_references_data (
    id serial primary key,
    book_start book_name,
    book_end book_name,
    chapter_start int,
    chapter_end int,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    created_by int not null default 0,
    verse_start int,
    verse_end int,
    unique (book_start, book_end, chapter_start, chapter_end, verse_start, verse_end)
--    foreign key (created_by) references public.people(id)
);

-- LOCATION -----------------------------------------------------------------

DO $$ BEGIN
    create type public.location_type as enum (
          'City',
          'County',
          'State',
		  'Country',
          'CrossBorderArea'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists public.locations_data (
	id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	name varchar(255) unique not null,
	sensitivity sensitivity not null default 'High',
	type location_type not null
--	foreign key (created_by) references public.people(id)
);

create table if not exists public.locations_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	created_at timestamp,
	created_by int,
	name varchar(255),
	sensitivity sensitivity,
	type location_type
);

create table if not exists public.locations_security (
    __person_id int not null,
    __id int not null,
	_id access_level,
	_created_at access_level,
	_created_by access_level,
	_name access_level,
	_sensitivity access_level,
	_type access_level,
	foreign key (__id) references public.locations(id),
--	foreign key (__person_id) references public.people(id)
);

create materialized view if not exists public.locations_secure_view as
    select
 		__person_id,
 		__id,
 		case when _id = 'Read' or _id = 'Write' then id end id,
 		case when _created_at = 'Read' or _created_at = 'Write' then created_at end created_at,
 		case when _created_by = 'Read' or _created_by = 'Write' then created_by end created_by,
 		case when _name = 'Read' or _name = 'Write' then name end "name",
 		case when _sensitivity = 'Read' or _sensitivity = 'Write' then sensitivity end sensitivity,
 		case when _type = 'Read' or _type = 'Write' then type end "type"
  	from public.locations_security
  	join public.locations
  	on locations_security.__id = locations.id
with no data;

REFRESH MATERIALIZED VIEW public.locations_secure_view;

CREATE UNIQUE INDEX IF NOT EXISTS public_locations_secure_view_uniq
    ON locations_secure_view (__person_id, __id);

CREATE INDEX IF NOT EXISTS public_locations_secure_view_lookup
    ON locations_secure_view (__person_id);

-- LANGUAGE -----------------------------------------------------------------

-- sil tables are copied from SIL schema docs
-- https://www.ethnologue.com/codes/code-table-structure
-- http://www.ethnologue.com/sites/default/files/Ethnologue-19-Global%20Dataset%20Doc.pdf

create schema if not exists sil;

CREATE TABLE if not exists sil.language_codes (
   lang_id char(3) not null,  -- Three-letter code
   country_id char(2) not null,  -- Main country where used
   lang_status char(1) not null,  -- L(iving), (e)X(tinct)
   name varchar(75) not null   -- Primary name in that country
);

CREATE TABLE if not exists sil.language_codes_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
   lang_id char(3),
   country_id char(2),
   lang_status char(1),
   name varchar(75)
);

CREATE TABLE if not exists sil.country_codes (
   country_id char(2) not null,  -- Two-letter code from ISO3166
   name varchar(75) not null,  -- Country name
   area varchar(10) not null -- World area
);

CREATE TABLE if not exists sil.country_codes_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
   country_id char(2),
   name varchar(75),
   area varchar(10)
);

CREATE TABLE if not exists sil.language_index (
   lang_id char(3) not null,  -- Three-letter code for language
   country_id char(2) not null,  -- Country where this name is used
   name_type char(2) not null,  -- L(anguage), LA(lternate),
                                -- D(ialect), DA(lternate)
                                -- LP,DP (a pejorative alternate)
   name  varchar(75) not null
);

CREATE TABLE if not exists sil.language_index_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
   lang_id char(3),
   country_id char(2),
   name_type char(2),
   name  varchar(75)
);

create table if not exists sil.table_of_languages (
    sil_ethnologue_id serial primary key,
    sil_ethnologue_legacy_id varchar(32),
	iso_639 char(3),
	created_at timestamp not null default CURRENT_TIMESTAMP,
	code varchar(32),
	language_name varchar(50) not null,
	population int,
	provisional_code varchar(32)
);

create table if not exists sil.table_of_languages_history (
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

create table if not exists public.people_data (
    id serial primary key,
	reference_count serial,
    about text,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    created_by int default 0, -- don't make not null!
    phone varchar(32),
	picture varchar(255),
    primary_org_id int,
    private_first_name varchar(32),
    private_last_name varchar(32),
    public_first_name varchar(32),
    public_last_name varchar(32),
    primary_location_id int,
    private_full_name varchar(64),
    public_full_name varchar(64),
    sensitivity_clearance sensitivity default 'Low',
    time_zone varchar(32),
    title varchar(255),
    foreign key (created_by) references public.people(id),
--    foreign key (primary_org_id) references public.organizations(id),
    foreign key (primary_location_id) references public.locations(id)
);

create table if not exists public.people_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    id int,
    about text,
    created_at timestamp,
    created_by int,
    phone varchar(32),
	picture varchar(255),
    primary_org_id int,
    private_first_name varchar(32),
    private_last_name varchar(32),
    public_first_name varchar(32),
    public_last_name varchar(32),
    primary_location_id int,
    private_full_name varchar(64),
    public_full_name varchar(64),
    sensitivity_clearance sensitivity,
    time_zone varchar(32),
    title varchar(255)
);

-- fkey for a bunch of stuff
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'public_global_roles_created_by_fk') THEN
ALTER TABLE public.global_roles ADD CONSTRAINT public_global_roles_created_by_fk foreign key (created_by) references people(id);
END IF; END; $$;

DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'public_global_role_grants_created_by_fk') THEN
ALTER TABLE public.global_role_grants ADD CONSTRAINT public_global_role_grants_created_by_fk foreign key (created_by) references people(id);
END IF; END; $$;

DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'public_global_role_memberships_person_id_fk') THEN
ALTER TABLE public.global_role_memberships ADD CONSTRAINT public_global_role_memberships_person_id_fk foreign key (person_id) references people(id);
END IF; END; $$;

DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'public_global_role_memberships_created_by_fk') THEN
ALTER TABLE public.global_role_memberships ADD CONSTRAINT public_global_role_memberships_created_by_fk foreign key (created_by) references people(id);
END IF; END; $$;

DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'public_secripture_references_created_by_fk') THEN
ALTER TABLE public.scripture_references ADD CONSTRAINT public_secripture_references_created_by_fk foreign key (created_by) references people(id);
END IF; END; $$;

DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'public_locations_created_by_fk') THEN
ALTER TABLE public.locations ADD CONSTRAINT public_locations_created_by_fk foreign key (created_by) references people(id);
END IF; END; $$;

create table if not exists public.people_security (
    __id int not null,
    _id access_level,
    _about access_level,
    _created_at access_level,
    _created_by access_level,
    _phone access_level,
	_picture access_level,
    _primary_org_id access_level,
    _private_first_name access_level,
    _private_last_name access_level,
    _public_first_name access_level,
    _public_last_name access_level,
    _primary_location_id access_level,
    _private_full_name access_level,
    _public_full_name access_level,
    _time_zone access_level,
    _title access_level,
    foreign key (__id) references people(id)
);

-- Education

create table if not exists public.education_entries_data (
    id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
    degree varchar(64),
    institution varchar(64),
    major varchar(64)
);

create table if not exists public.education_entries_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    id int,
	created_at timestamp,
    degree varchar(64),
    institution varchar(64),
    major varchar(64)
);

create table if not exists public.education_by_person_data (
    id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
    education_id int not null,
    graduation_year int,
    person_id int not null,
    foreign key (created_by) references public.people(id),
	foreign key (person_id) references public.people(id),
	foreign key (education_id) references public.education_entries(id)
);

create table if not exists public.education_by_person_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	created_at timestamp,
	created_by int,
    education_id int,
    graduation_year int,
    person_id int
);

-- ORGANIZATIONS ------------------------------------------------------------

create table if not exists public.organizations_data (
	id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	name varchar(255) unique not null,
	sensitivity sensitivity default 'High',
	primary_location_id int,
	foreign key (created_by) references public.people(id),
	foreign key (primary_location_id) references locations(id)
);

create table if not exists public.organizations_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	created_at timestamp,
	created_by int,
	name varchar(255),
	primary_location_id int
);


DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'public_global_roles_org_id_fk') THEN
ALTER TABLE public.global_roles ADD CONSTRAINT public_global_roles_org_id_fk foreign key (org_id) references organizations(id);
END IF; END; $$;

-- fkey for people
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'primary_org_id_fkey') THEN
ALTER TABLE public.people ADD CONSTRAINT primary_org_id_fkey foreign key (primary_org_id) references public.organizations(id);
END IF; END; $$;

-- fkey for global_roles
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'global_role_org_id_fkey') THEN
ALTER TABLE global_roles ADD CONSTRAINT global_role_org_id_fkey foreign key (org_id) references public.organizations(id);
END IF; END; $$;

DO $$ BEGIN
    create type public.person_to_org_relationship_type as enum (
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

create table if not exists public.organization_grants_data(
    id serial primary key,
    access_level access_level not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    created_by int not null default 0,
    column_name varchar(32) not null,
    org_id int not null,
    table_name table_name not null,
    unique (org_id, table_name, column_name, access_level),
    foreign key (created_by) references public.people(id),
    foreign key (org_id) references organizations(id)
);

create table if not exists public.organization_memberships_data(
    id serial primary key,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    created_by int not null default 0,
    org_id int not null,
    person_id int not null,
    foreign key (created_by) references public.people(id),
    foreign key (org_id) references organizations(id),
    foreign key (person_id) references people(id)
);

create table if not exists public.organization_memberships_history(
    _history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
    created_at timestamp,
    created_by int,
    org_id int,
    person_id int
);

create table if not exists public.people_to_org_relationships_data (
    id serial primary key,
	org_id int,
	person_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	foreign key (created_by) references public.people(id),
	foreign key (org_id) references organizations(id),
	foreign key (person_id) references people(id)
);

create table if not exists public.people_to_org_relationships_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
    id int,
	org_id int,
	person_id int,
	created_at timestamp,
	created_by int
);

create table if not exists public.people_to_org_relationship_type_data (
    id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
    begin_at timestamp not null,
	end_at timestamp,
    people_to_org_id int,
	relationship_type person_to_org_relationship_type,
	foreign key (created_by) references public.people(id),
	foreign key (people_to_org_id) references people_to_org_relationships(id)
);

create table if not exists public.people_to_org_relationship_type_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
    begin_at timestamp,
	created_at timestamp,
	created_by int,
	end_at timestamp,
    people_to_org_id int,
	relationship_type person_to_org_relationship_type
);

-- USERS ---------------------------------------------------------------------

create table if not exists public.users_data(
    id serial primary key,
	person_id int not null,
	owning_org_id int not null,
	email varchar(255) unique not null,
	password varchar(255) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	foreign key (created_by) references public.people(id),
	foreign key (person_id) references public.people(id),
	foreign key (owning_org_id) references public.organizations(id)
);

create table if not exists public.users_history(
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	person_id int,
	owning_org_id int,
	email varchar(255),
	password varchar(255),
	created_at timestamp,
	created_by int
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'loc_sec_person_id_fkey') THEN
        ALTER TABLE locations_security
            ADD CONSTRAINT loc_sec_person_id_fkey
            foreign key (__person_id) references people(id);
    END IF;
END;
$$;

-- PROJECTS ------------------------------------------------------------------

create table if not exists public.projects_data (
	id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	name varchar(32) not null,
	primary_org_id int,
	primary_location_id int,
	sensitivity sensitivity default 'High',
	unique (primary_org_id, name),
	foreign key (created_by) references public.people(id),
	foreign key (primary_org_id) references organizations(id),
	foreign key (primary_location_id) references locations(id)
);

create table if not exists public.projects_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	created_at timestamp,
	created_by int,
	name varchar(32),
	primary_org_id int,
	primary_location_id int,
	sensitivity sensitivity
);

create table if not exists public.project_memberships_data (
    id serial primary key,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    created_by int not null default 0,
    person_id int not null,
    project_id int not null,
    foreign key (created_by) references public.people(id),
    foreign key (project_id) references projects(id),
    foreign key (person_id) references people(id)
);

create table if not exists public.project_members_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	created_at timestamp,
	created_by int,
    person_id int,
    project_id int
);

create table if not exists public.project_roles_data (
	id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	name varchar(255) not null,
	org_id int,
	unique (org_id, name),
	foreign key (created_by) references public.people(id),
	foreign key (org_id) references public.organizations(id)
);

create table if not exists public.project_roles_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	created_at timestamp,
	created_by int,
	name varchar(255),
	org_id int,
	project_role_id int
);

create table if not exists public.project_role_grants_data (
    id serial primary key,
	access_level access_level not null,
	column_name varchar(32) not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
	project_role_id int not null,
	table_name table_name not null,
	unique (project_role_id, table_name, column_name, access_level),
	foreign key (created_by) references public.people(id),
	foreign key (project_role_id) references project_roles(id)
);

create table if not exists public.project_role_grants_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
	access_level access_level,
	column_name varchar(32),
	created_at timestamp,
	created_by int,
	project_role_id int,
	table_name table_name
);

create table if not exists public.project_member_roles_data (
    id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	created_by int not null default 0,
    person_id int not null,
    project_id int not null,
	project_role_id int,
	unique (project_id, person_id),
	foreign key (created_by) references public.people(id),
	foreign key (person_id) references people(id),
	foreign key (project_id) references projects(id),
	foreign key (project_role_id) references project_roles(id)
);

create table if not exists public.project_member_roles_history (
	_history_id serial primary key,
	_history_created_at timestamp not null default CURRENT_TIMESTAMP,
	id int,
    person_id int,
    project_id int,
	project_role_id int,
	created_at timestamp,
	created_by int
);


-- AUTHENTICATION ------------------------------------------------------------

create table if not exists public.tokens (
	token varchar(512) primary key,
	person_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (person_id) references people(id)
);