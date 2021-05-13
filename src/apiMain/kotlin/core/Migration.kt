package core

import core.database.Neo4j
import java.sql.Connection

import java.time.ZonedDateTime


class Migration (
    val config: Config,
    val neo4j: Neo4j,
    val connection: Connection,
) {


    fun migrate(){
//        this.migrateOrganizations()
//        this.migrateUsers()
//        this.migrateRoles()
        this.migrateEthnologue()
    }

    // ORGS ////////////////////////////////////////////////////////////////////////////////////////////////

    val migrateOrgProc = """
        create or replace function migrate_org_proc(
            in pInternalId VARCHAR(32),
            in pName VARCHAR(255),
            in pAddress VARCHAR(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vId INT;
        begin
            SELECT sys_group_id 
            FROM sys_groups
            INTO vId
            WHERE sys_groups.name = pName;
            IF NOT found THEN
                INSERT INTO sys_groups("name", "type")
                VALUES (pName, 'Organization')
                RETURNING sys_group_id
                INTO vId;
                INSERT INTO sc_organizations_ext_sys_groups("sys_group_id", "address", "sc_internal_org_id")
                VALUES (vId, pAddress, pInternalId);
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateOrgProc)
        statement.close()
    }

    private fun migrateOrganizations(){

        //language=SQL
        val callFun = this.connection.prepareStatement("""
            select migrate_org_proc from migrate_org_proc(?, ?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            print("Organizations ")
            val result = it.run(
            "match (n:Organization) return count(n) as orgs"
            )

            while (result.hasNext()){
                val record = result.next()
                count = record.get("orgs").asInt()
                print("Count: $count ")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i+1} ")
                val getOrgResult = it.run(
                    """
                        match (n:Organization)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        return 
                            n.id as orgId, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt
                    """.trimIndent()
                )

                var orgId: String? = null
                var orgAddress: String? = null
                var orgAddressCreatedAt: ZonedDateTime? = null
                var orgName: String? = null
                var orgNameCreatedAt: ZonedDateTime? = null

                while (getOrgResult.hasNext()){
                    val record = getOrgResult.next()

                    orgId = record.get("orgId").asString()
                    val propName = record.get("propName").asString()

                    when (propName){
                        "address" -> {
                            orgAddress = record.get("propValue").asString()
                            orgAddressCreatedAt = record.get("createdAt").asZonedDateTime()
                        }
                        "name" -> {
                            orgName = record.get("propValue").asString()
                            orgNameCreatedAt = record.get("createdAt").asZonedDateTime()
                        }
                        "canDelete" -> {}
                        else -> {
                            print("orgId $orgId: failed to recognize property $propName ")
                        }
                    }
                }

                it.commit()
                it.close()

                // write to postgres
                callFun.setString(1, orgId)
                callFun.setString(2, orgName)
                callFun.setString(3, orgAddress)
                val createOrgResult = callFun.executeQuery()
                createOrgResult.next()
                val code = createOrgResult.getInt(1)
                print("internal org id: $orgId code: $code")
                createOrgResult.close()
            }
        }
    }

    // USERS ////////////////////////////////////////////////////////////////////////////////////////////////

    val migratePeopleProc = """
        create or replace function migrate_people_proc(
            in pInternalId varchar(32),
            in pAbout text,
            in pEmail varchar(255),
            in pPrivateFirstName varchar(32),
            in pPrivateLastName varchar(32),
            in pPassword varchar(255),
            in pPhone varchar(32),
            in pPublicFirstName varchar(32),
            in pPublicLastName varchar(32),
            in pStatus varchar(32),
            in pTimezone varchar(32),
            in pTitle varchar(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vSysPersonId INT;
        begin
            SELECT sys_person_id 
            FROM sc_people_ext_sys_people
            INTO vSysPersonId
            WHERE sc_people_ext_sys_people.sc_internal_person_id = pInternalId;
            IF NOT found THEN
                INSERT INTO sys_people("about", "phone", "private_first_name", "private_last_name", "public_first_name", "public_last_name", "time_zone", "title")
                VALUES (pAbout, pPhone, pPrivateFirstName, pPrivateLastName, pPublicFirstName, pPublicLastName, pTimezone, pTitle)
                RETURNING sys_person_id
                INTO vSysPersonId;
                INSERT INTO sc_people_ext_sys_people("sys_person_id", "sc_internal_person_id", "status")
                VALUES (vSysPersonId, pInternalId, pStatus);
                IF pEmail IS NOT NULL AND pPassword IS NOT NULL THEN
                    INSERT INTO sys_users("sys_person_id", "email", "password")
                    VALUES (vSysPersonId, pEmail, pPassword);
                END IF;
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migratePeopleProc)
        statement.close()
    }

    private fun migrateUsers(){

        //language=SQL
        val createUserSQL = this.connection.prepareStatement("""
            select migrate_people_proc from migrate_people_proc(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nUsers ")
            val result = it.run(
                "match (n:User) return count(n) as users"
            )

            while (result.hasNext()){
                val record = result.next()
                count = record.get("users").asInt()
                print("Count: $count \n")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i+1} ")
                val getUserResult = it.run(
                    """
                        match (n:User)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        return 
                            n.id as userId, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt
                    """.trimIndent()
                )

                var userId: String? = null

                var about: String? = null
                var email: String? = null
                var displayFirstName: String? = null
                var displayLastName: String? = null
                var password: String? = null
                var phone: String? = null
                var realFirstName: String? = null
                var realLastName: String? = null
                var status: String? = null
                var timezone: String? = null
                var title: String? = null

                while (getUserResult.hasNext()){
                    val record = getUserResult.next()

                    userId = record.get("userId").asString()
                    val propName = record.get("propName").asString()

                    when(propName){
                        "about" -> {
                            about = record.get("propValue").asString()
                        }
                        "email" -> {
                            email = record.get("propValue").asString()
                        }
                        "displayFirstName" -> {
                            displayFirstName = record.get("propValue").asString()
                        }
                        "displayLastName" -> {
                            displayLastName = record.get("propValue").asString()
                        }
                        "password" -> {
                            password = record.get("propValue").asString()
                        }
                        "phone" -> {
                            phone = record.get("propValue").asString()
                        }
                        "realFirstName" -> {
                            realFirstName = record.get("propValue").asString()
                        }
                        "realLastName" -> {
                            realLastName = record.get("propValue").asString()
                        }
                        "status" -> {
                            status = record.get("propValue").asString()
                        }
                        "timezone" -> {
                            timezone = record.get("propValue").asString()
                        }
                        "title" -> {
                            title = record.get("propValue").asString()
                        }
                        "canDelete" -> {}
                        "roles" -> {}
                        else -> {
                            print("userId $userId: failed to recognize property $propName ")
                        }
                    }
                }

                it.commit()
                it.close()

                // write to postgres
                createUserSQL.setString(1, userId)
                createUserSQL.setString(2, about)
                createUserSQL.setString(3, email)
                createUserSQL.setString(4, realFirstName)
                createUserSQL.setString(5, realLastName)
                createUserSQL.setString(6, password)
                createUserSQL.setString(7, phone)
                createUserSQL.setString(8, displayFirstName)
                createUserSQL.setString(9, displayLastName)
                createUserSQL.setString(10, status)
                createUserSQL.setString(11, timezone)
                createUserSQL.setString(12, title)

                val createResult = createUserSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print("internal user id: $userId code: $code ")
                createResult.close()
            }
        }
    }

    // ROLES /////////////////////////////////////////////////////////////////////////////////////////////////

    val createSCRoleProc = """
        create or replace function create_sc_role(
            in pRoleName varchar(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vSysGroupId INT;
        begin
            SELECT sys_group_id 
            FROM sys_groups
            INTO vSysGroupId
            WHERE sys_groups.name = pRoleName AND sys_groups.type = 'SC Global Role';
            IF NOT found THEN
                INSERT INTO sys_groups("name", "type")
                VALUES (pRoleName, 'SC Global Role')
                RETURNING sys_group_id
                INTO vSysGroupId;
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    val addUserRoleProc = """
        create or replace function add_user_role_proc(
            in pInternalId varchar(32),
            in pRoleName varchar(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vSysPersonId INT;
            vSysGroupId INT;
        begin
            SELECT sys_group_id 
            FROM sys_groups
            INTO vSysGroupId
            WHERE sys_groups.name = pRoleName AND sys_groups.type = 'SC Global Role';
            IF FOUND THEN
                SELECT sys_person_id
                FROM sc_people_ext_sys_people
                INTO vSysPersonId
                WHERE sc_people_ext_sys_people.sc_internal_person_id = pInternalId;
                IF FOUND THEN
                    INSERT INTO sys_group_membership_by_person("sys_person_id", "sys_group_id")
                    VALUES (vSysPersonId, vSysGroupId);
                    vResponseCode := 0;
                ELSE
                    vResponseCode := 2;
                END IF;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.createSCRoleProc)
        statement.execute(this.addUserRoleProc)
        statement.close()
    }

    private fun migrateRoles(){

        // create roles

        val roles = listOf(
            "Administrator",
            "Consultant",
            "Consultant Manager",
            "Controller",
            "Field Operations Director",
            "Financial Analyst",
            "Fundraising",
            "Intern",
            "Leadership",
            "Lead Financial Analyst",
            "Liaison",
            "Marketing",
            "Mentor",
            "Project Manager",
            "Regional Communications Coordinator",
            "Regional Director",
            "Staff Member",
            "Translator"
        )

        //language=SQL
        val createRoleSQL = this.connection.prepareStatement("""
            select create_sc_role from create_sc_role(?);
        """.trimIndent()
        )

        for (role in roles){
            createRoleSQL.setString(1, role)
            val createResult = createRoleSQL.executeQuery()
            createResult.next()
            val code = createResult.getInt(1)
            println("role created: $role code: $code ")
            createResult.close()
        }

        // add user roles

        //language=SQL
        val addUserRoleSQL = this.connection.prepareStatement("""
            select add_user_role_proc from add_user_role_proc(?, ?);
        """.trimIndent()
        )

        neo4j.driver.session().readTransaction {

            var count = 0

            val getUserRoles = it.run(
                """
                    match (n:User)-[r:roles {active: true}]->(prop:Property)
                    return n.id as id, prop.value as role
                    """.trimIndent()
            )

            var userId: String? = null

            while (getUserRoles.hasNext()){
                val record = getUserRoles.next()

                userId = record.get("id").asString()
                val neoRole = record.get("role").asString()
                var newRole: String? = null

                when(neoRole){
                    "Administrator" -> newRole = "Administrator"
                    "ProjectManager" -> newRole = "Project Manager"
                    "FinancialAnalyst" -> newRole = "Financial Analyst"
                    "Marketing" -> newRole = "Marketing"
                    "Fundraising" -> newRole = "Fundraising"
                    "RegionalDirector" -> newRole = "Regional Director"
                    "Consultant" -> newRole = "Consultant"
                    "BibleTranslationLiaison" -> newRole = "Bible Translation Liaison"
                    "Mentor" -> newRole = "Mentor"
                    "Leadership" -> newRole = "Leadership"
                    "FieldOperationsDirector" -> newRole = "Field Operations Director"
                    "LeadFinancialAnalyst" -> newRole = "Lead Financial Analyst"
                    "Intern" -> newRole = "Intern"
                    "Controller" -> newRole = "Controller"
                    "ConsultantManager" -> newRole = "Consultant Manager"
                    "FieldPartner" -> newRole = "Field Partner"
                    "Translator" -> newRole = "Translator"
                    "RegionalCommunicationsCoordinator" -> newRole = "Regional Communications Coordinator"
                    "StaffMember" -> newRole = "Staff Member"

                    else -> {
                        print("userId $userId: failed to recognize role $neoRole ")
                    }
                }

                if (newRole != null){

                    // write to postgres
                    addUserRoleSQL.setString(1, userId)
                    addUserRoleSQL.setString(2, newRole)

                    val createResult = addUserRoleSQL.executeQuery()
                    createResult.next()
                    val code = createResult.getInt(1)
                    count++
                    println("$count role added for internal user id: $userId code: $code role: $newRole")
                    createResult.close()

                }
            }

            it.commit()
            it.close()

            println("added $count role entries")

        }

    }

    // LANGUAGES ////////////////////////////////////////////////////////////////////////////////////////////////

    val migrateEthnologueProc = """
        create or replace function migrate_ethnologue_proc(
            in pInternalId varchar(32),
            in pISO639 char(3),
            in pLanguageName varchar(50),
            in pPopulation int,
            in provisionalCode varchar(32)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vSysEthnologueId INT;
        begin
            SELECT sys_ethnologue_id 
            FROM sil_table_of_languages
            INTO vSysEthnologueId
            WHERE sil_table_of_languages.sys_ethnologue_legacy_id = pInternalId;
            IF NOT found THEN
                INSERT INTO sil_table_of_languages("sys_ethnologue_legacy_id","ISO_639","code","Language_Name","population","provisional_code")
                VALUES (pInternalId, pISO639, provisionalCode, pLanguageName, pPopulation, provisionalCode)
                RETURNING sys_ethnologue_id
                INTO vSysEthnologueId;
                vResponseCode := 0;
            ELSE
                vResponseCode := 1;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateEthnologueProc)
        statement.close()
    }

    private fun migrateEthnologue(){

        //language=SQL
        val createEthnologueSQL = this.connection.prepareStatement("""
            select migrate_ethnologue_proc from migrate_ethnologue_proc(?, ?, ?, ?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nEthnologue ")
            val result = it.run(
                "match (n:EthnologueLanguage) return count(n) as eth"
            )

            while (result.hasNext()){
                val record = result.next()
                count = record.get("eth").asInt()
                print("Count: $count \n")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i+1} ")
                val getUserResult = it.run(
                    """
                        match (n:EthnologueLanguage)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        return 
                            n.id as ethId, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt
                    """.trimIndent()
                )

                var ethId: String? = null

                var ISO_639: String? = null
                var provisionalCode: String? = null
                var name: String? = null
                var population: Int? = null

                while (getUserResult.hasNext()){
                    val record = getUserResult.next()

                    ethId = record.get("ethId").asString()
                    val propName = record.get("propName").asString()

                    when(propName){
                        "code" -> {
//                            about = record.get("propValue").asString()
                        }
                        "provisionalCode" -> {
//                            email = record.get("propValue").asString()
                        }
                        "population" -> {
//                            displayFirstName = record.get("propValue").asString()
                        }
                        "name" -> {
//                            displayLastName = record.get("propValue").asString()
                        }
                        "canDelete" -> {}
                        else -> {
                            print("userId $ethId: failed to recognize property $propName ")
                        }
                    }
                }

                it.commit()
                it.close()

                // write to postgres
//                createEthnologueSQL.setString(1, userId)
//                createEthnologueSQL.setString(2, about)
//                createEthnologueSQL.setString(3, email)
//                createEthnologueSQL.setString(4, realFirstName)
//                createEthnologueSQL.setString(5, realLastName)
//                createEthnologueSQL.setString(6, password)
//                createEthnologueSQL.setString(7, phone)
//                createEthnologueSQL.setString(8, displayFirstName)
//                createEthnologueSQL.setString(9, displayLastName)
//                createEthnologueSQL.setString(10, status)
//                createEthnologueSQL.setString(11, timezone)
//                createEthnologueSQL.setString(12, title)

                val createResult = createEthnologueSQL.executeQuery()
                createResult.next()
                val returnCode = createResult.getInt(1)
                print("internal user id: $ethId returnCode: $returnCode ")
                createResult.close()
            }
        }
    }
}