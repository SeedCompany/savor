create or replace function sys_create_role(
    in pRoleName VARCHAR(255),
    in pOrgName VARCHAR(255)
)
returns INT
language plpgsql
as $$
declare
    vResponseCode INT;
    vSysRoleId INT;
    vOrgId INT;
begin
    SELECT id
    FROM public.organizations
    INTO vOrgId
    WHERE organizations.name = pOrgName;
    IF FOUND THEN
        SELECT id
        FROM public.global_roles
        INTO vSysRoleId
        WHERE global_roles.org_id = vOrgId
            AND global_roles.name = pRoleName;
        IF NOT FOUND THEN
            INSERT INTO public.global_roles("org_id", "name")
            VALUES (vOrgId, pRoleName);
            vResponseCode := 0;
        ELSE
            vResponseCode := 1;
        END IF;
    ELSE
        vResponseCode := 1;
    END IF;
    return vResponseCode;
end; $$;

create or replace function sys_add_role_grant(
    in pRoleName VARCHAR(255),
    in pOrgName VARCHAR(255),
    in pTableName table_name,
    in pColumnName VARCHAR(255),
    in pAccessLevel access_level
)
returns INT
language plpgsql
as $$
declare
    vResponseCode INT;
    vSysRoleId INT;
    vSysRoleId2 INT;
    vOrgId INT;
begin
    SELECT id
    FROM public.organizations
    INTO vOrgId
    WHERE organizations.name = pOrgName;
    IF FOUND THEN
        SELECT id
        FROM public.global_roles
        INTO vSysRoleId
        WHERE global_roles.org_id = vOrgId
            AND global_roles.name = pRoleName;
        IF FOUND THEN
            SELECT global_role_id
            FROM global_role_grants
            INTO vSysRoleId2
            WHERE global_role_grants.global_role_id = vSysRoleId
                AND global_role_grants.table_name = pTableName
                AND global_role_grants.column_name = pColumnName
                AND global_role_grants.access_level = pAccessLevel;
            IF NOT FOUND THEN
                INSERT INTO global_role_grants("global_role_id", "table_name", "column_name", "access_level")
                VALUES (vSysRoleId, pTableName, pColumnName, pAccessLevel);
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
        ELSE
            vResponseCode := 1;
        END IF;
    ELSE
        vResponseCode := 1;
    END IF;
    return vResponseCode;
end; $$;

create or replace function sys_add_role_member(
    in pRoleName VARCHAR(255),
    in pOrgName VARCHAR(255),
    in pUserEmail VARCHAR(255)
)
returns INT
language plpgsql
as $$
declare
    vResponseCode INT;
    vSysRoleId INT;
    vOrgId INT;
    vSysPersonId INT;
begin
    SELECT id
    FROM public.organizations
    INTO vOrgId
    WHERE organizations.name = pOrgName;
    IF FOUND THEN
        SELECT id
        FROM public.global_roles
        INTO vSysRoleId
        WHERE global_roles.org_id = vOrgId
            AND global_roles.name = pRoleName;
        IF FOUND THEN
            select person_id
            from public.users
            into vSysPersonId
            where users.email = pUserEmail;
            if found then
                INSERT INTO global_role_memberships("person_id", "global_role_id")
                VALUES (vSysPersonId, vSysRoleId);
                vResponseCode := 0;
            else
                vResponseCode := 1;
            end if;
        ELSE
            vResponseCode := 1;
        END IF;
    ELSE
        vResponseCode := 1;
    END IF;
    return vResponseCode;
end; $$;