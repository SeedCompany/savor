package components.organization

import java.sql.Connection

class Organization (conn: Connection) {

    val scAddOrgProc = """
        create or replace function sc_add_org(
        	in pPrivateName VARCHAR ( 255 ),
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

        statement.execute(this.scAddOrgProc)

        statement.close()
    }
}