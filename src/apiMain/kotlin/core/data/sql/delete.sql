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

drop type if exists table_name cascade;
drop type if exists column_name cascade;
drop type if exists location_type cascade;
drop type if exists person_to_org_relationship_type cascade;
drop type if exists group_type cascade;
drop type if exists mime_type cascade;
drop type if exists book_name cascade;
drop type if exists access_level cascade;
drop type if exists sensitivity cascade;

drop type if exists sc_involvements cascade;
drop type if exists sc_people_transitions cascade;
drop type if exists sc_org_transitions cascade;
drop type if exists sc_sensitivity cascade;
drop type if exists sc_financial_reporting_types cascade;
drop type if exists sc_partner_types cascade;
drop type if exists sc_project_step cascade;
drop type if exists sc_project_status cascade;
drop type if exists sc_budget_status cascade;
drop type if exists sc_engagement_status cascade;
drop type if exists sc_project_engagement_tag cascade;
drop type if exists sc_internship_methodology cascade;
drop type if exists sc_internship_position cascade;
drop type if exists sc_product_mediums cascade;
drop type if exists sc_product_methodologies cascade;
drop type if exists sc_product_purposes cascade;
drop type if exists sc_product_type cascade;
drop type if exists sc_change_to_plan_type cascade;
drop type if exists sc_change_to_plan_status cascade;

-- FUNCTIONS ---------------------------------------------------------------------------

-- Triggers
DROP TRIGGER IF EXISTS locations_history_trigger ON public.sys_locations cascade;
drop function if exists locations_history_fn cascade;

-- Migration
drop function if exists migrate_org cascade;
drop function if exists migrate_user cascade;
drop function if exists create_sc_role cascade;
drop function if exists add_user_role cascade;

-- Authentication
drop function if exists sc_add_user cascade;
drop function if exists sys_login cascade;
drop function if exists sys_register cascade;

-- Organization
drop function if exists sc_add_org cascade;

-- Authorization
drop function if exists sys_add_member cascade;
drop function if exists sys_add_column_access_for_user cascade;
drop function if exists sys_add_column_access_for_group cascade;
drop function if exists sys_add_row_access_for_user cascade;
drop function if exists sys_add_row_access_for_group cascade;
