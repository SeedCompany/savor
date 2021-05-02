package components.authorization

import java.sql.Connection

class Authorization (conn: Connection) {

    val sysAddMemberProc = """
        create or replace function sys_add_member(
        	in pEmail VARCHAR ( 255 ),
        	in pGroupName VARCHAR ( 32 )
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
        	vSysUserId INT;
        	vSysGroupId INT;
        	vResponseCode INT;
        begin
        	SELECT sys_user_id
        	FROM sys_users
        	INTO vSysUserId
        	WHERE sys_users.email = pEmail;
        	IF found THEN
        		SELECT sys_group_id
        		FROM sys_groups
        		INTO vSysGroupId
        		WHERE sys_groups.name = pGroupName;
        		IF found THEN
        			INSERT INTO sys_group_memberships_by_user("sys_user_id", "sys_group_id")
        			VALUES (vSysUserId, vSysGroupId)
        			ON CONFLICT ("sys_user_id", "sys_group_id")
        			DO NOTHING;
        			vResponseCode := 0;
        		ELSE
        			vResponseCode := 1;
        		END IF;
        	ELSE
        		vResponseCode := 1;
        	END IF;
        	return vResponseCode;
        end; ${'$'}${'$'};
    """.trimIndent()

    val sysAddColumnAccessForUserProc = """
        create or replace function sys_add_column_access_for_user(
        	in pPrivateName VARCHAR (255),
        	in pInternalOrgId VARCHAR ( 32 )
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
        	vSysOrgId INT;
        	vResponseCode INT;
        begin
        	SELECT sys_org_id
        	FROM sys_organizations
        	INTO vSysOrgId
        	WHERE sys_organizations.private_name = pPrivateName;
        	IF found THEN
        		INSERT INTO sc_organizations("sys_org_id", "sc_internal_org_id")
        		VALUES (vSysOrgId, pInternalOrgId)
        		ON CONFLICT
        		DO NOTHING;
        		vResponseCode := 0;
        	ELSE
        		vResponseCode := 1;
        	END IF;
        	return vResponseCode;
        end; ${'$'}${'$'};
    """.trimIndent()

    init {
        val statement = conn.createStatement()

        statement.execute(this.sysAddMemberProc)
        statement.execute(this.sysAddColumnAccessForUserProc)

        statement.close()
    }
}