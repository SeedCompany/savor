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
    WHERE table_schema = p_schema_name and table_name=p_table_name and column_name='sensitivity';

    if found then 
        p_table_name := p_schema_name || '.' || p_table_name;
        select sensitivity into data_table_row_sensitivity 
        from p_table_name where id = p_id;
        raise info 'data_table_row_sensitivity: %', data_table_row_sensitivity;
        if (data_table_row_sensitivity = 'Mid' and p_sensitivity_clearance='Low') or 
        (data_table_row_sensitivity = 'High' and (p_sensitivity_clearance = 'Mid' or p_sensitivity_clearance = 'Low')) then 
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