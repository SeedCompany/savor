-- DELETE EVERYTHING

-- TABLES -------------------------------------------------------------------------------

DO $$ DECLARE
    r RECORD;
BEGIN
    -- if the schema you operate on is not "current", you will want to
    -- replace current_schema() in query with 'schematodeletetablesfrom'
    -- *and* update the generate 'DROP...' accordingly.
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;

-- ENUMs -------------------------------------------------------------------------------

drop type if exists enum_table_name cascade;
drop type if exists enum_column_name cascade;
drop type if exists enum_location_type cascade;
drop type if exists enum_person_to_org_relationship_type cascade;
drop type if exists enum_group_type cascade;
drop type if exists enum_mime_type cascade;
drop type if exists enum_book_name cascade;

drop type if exists sc_enum_involvements cascade;
drop type if exists sc_enum_people_transitions cascade;
drop type if exists sc_enum_org_transitions cascade;
drop type if exists sc_enum_sensitivity cascade;
drop type if exists sc_enum_financial_reporting_types cascade;
drop type if exists sc_enum_partner_types cascade;
drop type if exists sc_enum_project_step cascade;
drop type if exists sc_enum_project_status cascade;
drop type if exists sc_enum_budget_status cascade;
drop type if exists sc_enum_engagement_status cascade;
drop type if exists sc_enum_project_engagement_tag cascade;
drop type if exists sc_enum_internship_methodology cascade;
drop type if exists sc_enum_internship_position cascade;
drop type if exists sc_enum_product_mediums cascade;
drop type if exists sc_enum_product_methodologies cascade;
drop type if exists sc_enum_product_purposes cascade;
drop type if exists sc_enum_product_type cascade;
drop type if exists sc_enum_change_to_plan_type cascade;
drop type if exists sc_enum_change_to_plan_status cascade;

-- FUNCTIONS ---------------------------------------------------------------------------

-- Migration
drop function if exists migrate_org_proc cascade;
drop function if exists migrate_user_proc cascade;

-- Authentication
drop function if exists sc_add_user cascade;
drop function if exists sys_login_proc cascade;
drop function if exists sys_register_proc cascade;

-- Organization
drop function if exists sc_add_org cascade;

-- Authorization
drop function if exists sys_add_member cascade;
drop function if exists sys_add_column_access_for_user cascade;
drop function if exists sys_add_column_access_for_group cascade;
drop function if exists sys_add_row_access_for_user cascade;
drop function if exists sys_add_row_access_for_group cascade;
