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
    SELECT sys_org_id
    FROM sys_organizations
    INTO vOrgId
    WHERE sys_organizations.name = pOrgName;
    IF FOUND THEN
        SELECT sys_role_id
        FROM sys_roles
        INTO vSysRoleId
        WHERE sys_roles.sys_org_id = vOrgId
            AND sys_roles.name = pRoleName;
        IF NOT FOUND THEN
            INSERT INTO sys_roles("sys_org_id", "name")
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
    SELECT sys_org_id
    FROM sys_organizations
    INTO vOrgId
    WHERE sys_organizations.name = pOrgName;
    IF FOUND THEN
        SELECT sys_role_id
        FROM sys_roles
        INTO vSysRoleId
        WHERE sys_roles.sys_org_id = vOrgId
            AND sys_roles.name = pRoleName;
        IF FOUND THEN
            SELECT sys_role_id
            FROM sys_role_grants
            INTO vSysRoleId2
            WHERE sys_role_grants.sys_role_id = vSysRoleId
                AND sys_role_grants.table_name = pTableName
                AND sys_role_grants.column_name = pColumnName
                AND sys_role_grants.access_level = pAccessLevel;
            IF NOT FOUND THEN
                INSERT INTO sys_role_grants("sys_role_id", "table_name", "column_name", "access_level")
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
    SELECT sys_org_id
    FROM sys_organizations
    INTO vOrgId
    WHERE sys_organizations.name = pOrgName;
    IF FOUND THEN
        SELECT sys_role_id
        FROM sys_roles
        INTO vSysRoleId
        WHERE sys_roles.sys_org_id = vOrgId
            AND sys_roles.name = pRoleName;
        IF FOUND THEN
            select sys_person_id
            from sys_users
            into vSysPersonId
            where sys_users.email = pUserEmail;
            if found then
                INSERT INTO sys_role_memberships("sys_person_id", "sys_role_id")
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