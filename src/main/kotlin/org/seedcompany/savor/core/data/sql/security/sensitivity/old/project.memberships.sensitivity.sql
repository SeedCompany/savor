-- go to locations_security and update all the __is_cleared columns 

-- create or replace function refresh__location_is_cleared_on_project_memberships()
-- returns trigger 
-- language plpgsql
-- as $$
-- declare
-- rec1 record; 
-- project_location_id int;
-- begin 
--     -- new.project, new.person
--     select primary_location into project_location_id from public.projects_data where id = new.project; 
--     update public.locations_security set __is_cleared = true where __person_id = new.person and __id = project_location_id;
-- return new;
-- end; $$;

-- drop trigger if exists location_project_memberships  on public.projects_data;

-- create trigger location_project_memberships after insert 
-- on public.project_memberships_data 
-- for each row 
-- execute procedure refresh__location_is_cleared_on_project_memberships();
