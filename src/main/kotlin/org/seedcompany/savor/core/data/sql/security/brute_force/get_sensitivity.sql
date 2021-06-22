create or replace function public.get_sensitivity_clearance(p_id int, p_person_id int, p_sensitivity_clearance public.sensitivity, p_schema_name text,  p_table_name text)
returns boolean
language plpgsql
as $$
declare 
    rec1 record;
    data_table_row_sensitivity public.sensitivity;
begin
    perform column_name 
    FROM information_schema.columns 
    WHERE table_schema = p_schema_name and table_name = p_table_name and column_name='sensitivity';

    if found then 
        p_table_name := p_schema_name || '.' || p_table_name;
        execute format('select sensitivity from ' || p_table_name || ' where id = ' || p_id) into data_table_row_sensitivity;
        raise info 'data_table_row_sensitivity: %', data_table_row_sensitivity;
        if (data_table_row_sensitivity = 'Medium' and p_sensitivity_clearance='Low') or 
        (data_table_row_sensitivity = 'High' and (p_sensitivity_clearance = 'Medium' or p_sensitivity_clearance = 'Low')) then 
            if p_table_name = 'public.locations_data' then 
                for rec1 in (select id from public.projects_data where primary_location = p_id)
                loop
                    perform id from public.project_memberships_data where project = rec1.id;
                        if found then 
                            return true;
                        else 
                            return false;
                        end if; 
                end loop; 
                return false;
            else 
                return false;
            end if; 
        else  
            return true; 
        end if; 
    else 
        return true; 
    end if; 
end; $$;