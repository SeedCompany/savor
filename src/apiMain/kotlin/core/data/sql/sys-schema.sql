-- system schema. org specific schema should go in an org-specific file.

-- SCRIPTURE REFERENCE -----------------------------------------------------------------

-- todo
DO $$ BEGIN
    create type enum_book_name as enum (
          'Genesis',
          'Matthew',
          'Revelation'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sys_scripture_references (
    sys_scripture_reference_id serial primary key,
    book_start enum_book_name,
    book_end enum_book_name,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    chapter_start int,
    chapter_end int,
    verse_start int,
    verse_end int,
    unique (book_start, book_end, chapter_start, chapter_end, verse_start, verse_end)
);

-- LOCATION -----------------------------------------------------------------

DO $$ BEGIN
    create type enum_location_type as enum (
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
	type enum_location_type not null
);

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

CREATE TABLE if not exists sil_country_codes (
   country_id char(2) not null,  -- Two-letter code from ISO3166
   name varchar(75) not null,  -- Country name
   area varchar(10) not null -- World area
);

CREATE TABLE if not exists sil_language_index (
   lang_id char(3) not null,  -- Three-letter code for language
   country_id char(2) not null,  -- Country where this name is used
   name_type char(2) not null,  -- L(anguage), LA(lternate),
                                -- D(ialect), DA(lternate)
                                -- LP,DP (a pejorative alternate)
   name  varchar(75) not null   -- The name
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

-- Education

create table if not exists sys_education_entries (
    sys_education_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
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

-- ORGANIZATIONS ------------------------------------------------------------

DO $$ BEGIN
    create type enum_person_to_org_relationship_type as enum (
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

create table if not exists sys_organizations (
	sys_org_id serial primary key,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	name varchar(255) unique not null,
	primary_sys_location_id int,
	foreign key (primary_sys_location_id) references sys_locations(sys_location_id)
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'primary_sys_org_id_fkey') THEN
        ALTER TABLE sys_people
            ADD CONSTRAINT primary_sys_org_id_fkey
            foreign key (primary_sys_org_id) references sys_organizations(sys_org_id);
    END IF;
END;
$$;

create table if not exists sys_people_to_org_relationships (
    sys_people_to_org_id serial primary key,
	sys_org_id int,
	sys_person_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_org_id) references sys_organizations(sys_org_id),
	foreign key (sys_person_id) references sys_people(sys_person_id)
);

create table if not exists sys_people_to_org_relationship_type (
    sys_people_to_org_id int,
    begin_at timestamp not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	end_at timestamp,
	relationship_type enum_person_to_org_relationship_type,
	foreign key (sys_people_to_org_id) references sys_people_to_org_relationships(sys_people_to_org_id)
);

-- ROLES --------------------------------------------------------------------

create table if not exists sys_roles (
	sys_role_id serial primary key,
	sys_org_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	name varchar(255) not null,
	unique (sys_org_id, name),
	foreign key (sys_org_id) references sys_organizations(sys_org_id)
);

create table if not exists sys_role_memberships (
	sys_person_id int,
	sys_role_id int,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_role_id) references sys_roles(sys_role_id),
	foreign key (sys_person_id) references sys_people(sys_person_id)
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

-- AUTHENTICATION ------------------------------------------------------------

create table if not exists sys_tokens (
	token varchar(512) primary key,
	sys_person_id int not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_person_id) references sys_people(sys_person_id)
);

















-- VIEWS ----------------------------------------------------------------------

-- temp, doesn't use group security. need to research the best way to produce view
--create materialized view if not exists sys_column_security
--as
--    select sys_person_id, table_name, column_name
--    from sys_column_access_by_person
--with no data;
--
--create unique index if not exists pk_sys_column_security on sys_column_security ("sys_person_id", "table_name", "column_name");
--
--REFRESH MATERIALIZED VIEW sys_column_security;
--
--create materialized view if not exists sys_row_security
--    as
--    select sys_people.sys_person_id, sys_row_access_by_person.table_name, sys_row_access_by_person.row_id
--    from sys_people
--    left join sys_row_access_by_person
--    on sys_people.sys_person_id = sys_row_access_by_person.sys_person_id
--    where sys_row_access_by_person.row_id is not null
--with no data;
--
--create unique index if not exists pk_sys_row_security on sys_row_security ("sys_person_id", "table_name", "row_id");
--
--REFRESH MATERIALIZED VIEW sys_row_security;


-- SECURE TABLES ------------------------------------------------------------------------


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
        'sys_group_membership_by_person',
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
		'sys_group_id',
		'sys_person_id',
		'sys_project_id',
		'table_name',
		'token',
		'user_id'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

-- todo
DO $$ BEGIN
    create type enum_access_level as enum (
          'Read',
          'Write',
          'Admin'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

--create or replace function x_read_sc_people(
--    in pSysPersonId varchar(255)
--)
--returns table(
--    _sys_person_id int,
--	_sc_internal_person_id varchar(32),
--    _public_first_name varchar(32)
--)
--language plpgsql
--as $$
--declare
--    vRecord record;
--begin
--    for vRecord in(
--        select sys_people.sys_person_id, sys_people.public_first_name
--        from sys_people
--    ) loop
--        _sys_person_id := vRecord.sys_person_id;
--        _public_first_name := vRecord.public_first_name;
--		_sc_internal_person_id := 42;
--        return next;
--    end loop;
--end; $$;