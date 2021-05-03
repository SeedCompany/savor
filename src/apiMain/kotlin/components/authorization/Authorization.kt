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
        	in pEmail VARCHAR (255),
            in pTableName e_table_name,
            in pColumnName e_column_name
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
        	vSysUserId INT;
        	vResponseCode INT;
        begin
        	SELECT sys_user_id
        	FROM sys_users
        	INTO vSysUserId
        	WHERE sys_users.email = pEmail;
        	IF found THEN
        		INSERT INTO sys_column_access_by_user("sys_user_id", "table_name","column_name")
        		VALUES (vSysUserId, pTableName, pColumnName)
        		ON CONFLICT
        		DO NOTHING;
        		vResponseCode := 0;
        	ELSE
        		vResponseCode := 1;
        	END IF;
        	return vResponseCode;
        end; ${'$'}${'$'};
    """.trimIndent()

    val sysAddColumnAccessForGroupProc = """
        create or replace function sys_add_column_access_for_group(
        	in pGroupName VARCHAR (255),
            in pTableName e_table_name,
            in pColumnName e_column_name
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
        	vSysGroupId INT;
        	vResponseCode INT;
        begin
            SELECT sys_group_id
            FROM sys_groups
            INTO vSysGroupId
            WHERE sys_groups.name = pGroupName;
        	IF found THEN
        		INSERT INTO sys_column_access_by_group("sys_group_id", "table_name","column_name")
        		VALUES (vSysGroupId, pTableName, pColumnName)
        		ON CONFLICT
        		DO NOTHING;
        		vResponseCode := 0;
        	ELSE
        		vResponseCode := 1;
        	END IF;
        	return vResponseCode;
        end; ${'$'}${'$'};
    """.trimIndent()

    val sysAddRowAccessForUserProc = """
        create or replace function sys_add_row_access_for_user(
        	in pEmailOfGrantee VARCHAR (255),
            in pTableName e_table_name,
            in pEmailOfGranter VARCHAR (255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
        	vSysUserIdGrantee INT;
            vSysUserIdGranter INT;
        	vResponseCode INT;
        begin
        	SELECT sys_user_id
        	FROM sys_users
        	INTO vSysUserIdGrantee
        	WHERE sys_users.email = pEmailOfGrantee;
        	IF found THEN
                SELECT sys_user_id
                FROM sys_users
                INTO vSysUserIdGranter
                WHERE sys_users.email = pEmailOfGranter;
                IF found THEN
                    INSERT INTO sys_row_access_by_user("sys_user_id", "table_name","row_id")
                    VALUES (vSysUserIdGrantee, pTableName, vSysUserIdGranter)
                    ON CONFLICT
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

    val sysAddRowAccessForGroupProc = """
        create or replace function sys_add_row_access_for_group(
        	in pGroupNameGrantee VARCHAR (255),
            in pTableName e_table_name,
            in pEmailOfGranter VARCHAR (255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
        	vSysGroupIdGrantee INT;
            vSysUserIdGranter INT;
        	vResponseCode INT;
        begin
        	SELECT sys_group_id
        	FROM sys_groups
        	INTO vSysGroupIdGrantee
        	WHERE sys_groups.name = pGroupNameGrantee;
        	IF found THEN
                SELECT sys_user_id
                FROM sys_users
                INTO vSysUserIdGranter
                WHERE sys_users.email = pEmailOfGranter;
                IF found THEN
                    INSERT INTO sys_row_access_by_group("sys_group_id", "table_name","row_id")
                    VALUES (vSysGroupIdGrantee, pTableName, vSysUserIdGranter)
                    ON CONFLICT
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

    init {
        val statement = conn.createStatement()

        statement.execute(this.sysAddMemberProc)
        statement.execute(this.sysAddColumnAccessForUserProc)
        statement.execute(this.sysAddColumnAccessForGroupProc)
        statement.execute(this.sysAddRowAccessForUserProc)
        statement.execute(this.sysAddRowAccessForGroupProc)

        statement.close()
    }
}