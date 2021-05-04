-- SC DOMAIN ENTITIES -------------------------------------------------------------

create table if not exists sc_organizations(
	sys_org_id int primary key not null,
	sc_internal_org_id varchar(32) unique not null,
	created_at timestamp not null default CURRENT_TIMESTAMP,
	foreign key (sys_org_id) references sys_organizations(sys_org_id)
);

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

create table if not exists sc_people (
    sc_person_id serial primary key,
    private_first_name varchar(32),
    private_last_name varchar(32),
    public_first_name varchar(32),
    public_last_name varchar(32),
    primary_sys_org_id int,
    created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sc_roles (
    sc_role_id serial primary key,
    name varchar(32) unique not null,
    created_at timestamp not null default CURRENT_TIMESTAMP
);

create table if not exists sc_role_memberships (
    sc_person_id int not null,
    sc_role_id int not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_person_id, sc_role_id),
    foreign key (sc_person_id) references sc_people(sc_person_id)
);

DO $$ BEGIN
    create type sc_enum_involvements as enum (
		'CIT',
		'ENGAGEMENTS'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_involvements (
    sc_internal_org_id varchar(32) not null,
    type sc_enum_involvements not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
	primary key (sc_internal_org_id, type),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);

create table if not exists sc_person_to_person_rels (
    from_sc_person_id int not null,
    to_sc_person_id int not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (from_sc_person_id, to_sc_person_id),
    foreign key (from_sc_person_id) references sc_people(sc_person_id),
    foreign key (to_sc_person_id) references sc_people(sc_person_id)
);

create table if not exists sc_org_to_org_rels (
    from_sc_internal_org_id varchar(32) not null,
    to_sc_internal_org_id varchar(32) not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (from_sc_internal_org_id, to_sc_internal_org_id),
    foreign key (from_sc_internal_org_id) references sc_organizations(sc_internal_org_id),
    foreign key (to_sc_internal_org_id) references sc_organizations(sc_internal_org_id)
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
    author_sc_person_id int not null,
    note_text text not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_internal_org_id, author_sc_person_id, created_at),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id),
    foreign key (author_sc_person_id) references sc_people(sc_person_id)
);

DO $$ BEGIN
    create type sc_enum_people_transitions as enum (
		'NEW ORG',
		'OTHER'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_people_transitions (
    sc_person_id int not null,
    transition_type sc_enum_people_transitions not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_person_id, transition_type),
    foreign key (sc_person_id) references sc_people(sc_person_id)
);

DO $$ BEGIN
    create type sc_enum_org_transitions as enum (
		'TO MANAGER',
		'OTHER'
	);
	EXCEPTION
	WHEN duplicate_object THEN null;
END; $$;

create table if not exists sc_org_transitions (
    sc_internal_org_id varchar(32) not null,
    transition_type sc_enum_org_transitions not null,
    created_at timestamp not null default CURRENT_TIMESTAMP,
    primary key (sc_internal_org_id),
    foreign key (sc_internal_org_id) references sc_organizations(sc_internal_org_id)
);
