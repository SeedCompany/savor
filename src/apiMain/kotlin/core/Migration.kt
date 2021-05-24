package core

import core.database.Neo4j
import java.sql.Connection
import java.sql.Types

import java.time.ZonedDateTime


class Migration (
    val config: Config,
    val neo4j: Neo4j,
    val connection: Connection,
) {


    fun migrate() {
//        this.migrateOrganizations()
//        this.migrateUsers()
//        this.migrateRoles()
//        this.migrateEthnologue()
//        this.migrateLanguages()
        this.migratePartners()

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

    private fun migrateOrganizations() {

        //language=SQL
        val callFun = this.connection.prepareStatement(
            """
            select migrate_org_proc from migrate_org_proc(?, ?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            print("Organizations ")
            val result = it.run(
                "match (n:Organization) return count(n) as orgs"
            )

            while (result.hasNext()) {
                val record = result.next()
                count = record.get("orgs").asInt()
                print("Count: $count ")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i + 1} ")
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

                while (getOrgResult.hasNext()) {
                    val record = getOrgResult.next()

                    orgId = record.get("orgId").asString()
                    val propName = record.get("propName").asString()

                    when (propName) {
                        "address" -> {
                            orgAddress = record.get("propValue").asString()
                            orgAddressCreatedAt = record.get("createdAt").asZonedDateTime()
                        }
                        "name" -> {
                            orgName = record.get("propValue").asString()
                            orgNameCreatedAt = record.get("createdAt").asZonedDateTime()
                        }
                        "canDelete" -> {
                        }
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

    private fun migrateUsers() {

        //language=SQL
        val createUserSQL = this.connection.prepareStatement(
            """
            select migrate_people_proc from migrate_people_proc(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nUsers ")
            val result = it.run(
                "match (n:User) return count(n) as users"
            )

            while (result.hasNext()) {
                val record = result.next()
                count = record.get("users").asInt()
                print("Count: $count \n")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i + 1} ")
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

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()

                    userId = record.get("userId").asString()
                    val propName = record.get("propName").asString()

                    when (propName) {
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
                        "canDelete" -> {
                        }
                        "roles" -> {
                        }
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

    private fun migrateRoles() {

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
        val createRoleSQL = this.connection.prepareStatement(
            """
            select create_sc_role from create_sc_role(?);
        """.trimIndent()
        )

        for (role in roles) {
            createRoleSQL.setString(1, role)
            val createResult = createRoleSQL.executeQuery()
            createResult.next()
            val code = createResult.getInt(1)
            println("role created: $role code: $code ")
            createResult.close()
        }

        // add user roles

        //language=SQL
        val addUserRoleSQL = this.connection.prepareStatement(
            """
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

            while (getUserRoles.hasNext()) {
                val record = getUserRoles.next()

                userId = record.get("id").asString()
                val neoRole = record.get("role").asString()
                var newRole: String? = null

                when (neoRole) {
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

                if (newRole != null) {

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
                INSERT INTO sil_table_of_languages("sys_ethnologue_legacy_id","iso_639","code","language_name","population","provisional_code")
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

    private fun migrateEthnologue() {

        //language=SQL
        val createEthnologueSQL = this.connection.prepareStatement(
            """
            select migrate_ethnologue_proc from migrate_ethnologue_proc(?, ?, ?, ?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nEthnologue ")
            val result = it.run(
                "match (n:EthnologueLanguage) return count(n) as eth"
            )

            while (result.hasNext()) {
                val record = result.next()
                count = record.get("eth").asInt()
                print("Count: $count \n")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i + 1} ")
                val getUserResult = it.run(
                    """
                        match (n:EthnologueLanguage)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        return 
                            n.id as id, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt
                    """.trimIndent()
                )

                var id: String? = null

                var ISO_639: String? = null
                var provisionalCode: String? = null
                var name: String? = null
                var population: Int? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()

                    id = record.get("id").asString()
                    val propName = record.get("propName").asString()

                    when (propName) {
                        "code" -> {
                            if (!record.get("propValue").isNull) {
                                ISO_639 = record.get("propValue").asString()
                            }
                        }
                        "provisionalCode" -> {
                            if (!record.get("propValue").isNull) {
                                provisionalCode = record.get("propValue").asString()
                            }
                        }
                        "population" -> {
                            if (!record.get("propValue").isNull) {
                                population = record.get("propValue").asInt()
                            }
                        }
                        "name" -> {
                            name = record.get("propValue").asString()
                        }
                        "canDelete" -> {
                        }
                        else -> {
                            print("ethId $id: failed to recognize property $propName ")
                        }
                    }
                }

                it.commit()
                it.close()

                // write to postgres
                createEthnologueSQL.setString(1, id)

                if (ISO_639 != null) {
                    createEthnologueSQL.setString(2, ISO_639)
                } else {
                    createEthnologueSQL.setNull(2, Types.NULL)
                }

                createEthnologueSQL.setString(3, name)

                if (population != null) {
                    createEthnologueSQL.setInt(4, population)
                } else {
                    createEthnologueSQL.setNull(4, Types.NULL)
                }

                if (provisionalCode != null) {
                    createEthnologueSQL.setString(5, provisionalCode)
                } else {
                    createEthnologueSQL.setNull(5, Types.NULL)
                }

                val createResult = createEthnologueSQL.executeQuery()
                createResult.next()
                val returnCode = createResult.getInt(1)
                print("internal ethId: $id returnCode: $returnCode ")
                createResult.close()
            }
        }
    }

    val migrateLanguagesProc = """
        create or replace function migrate_languages_proc(
            in pEthName varchar(50),
            in pLangName varchar(255)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vEthId INT;
        begin
            SELECT sys_ethnologue_id 
            FROM sil_table_of_languages
            INTO vEthId
            WHERE sil_table_of_languages.language_name = pEthName;
            IF found THEN
                INSERT INTO sc_languages("sys_ethnologue_id","name")
                VALUES (vEthId, pLangName)
                RETURNING sys_ethnologue_id
                INTO vEthId;
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateLanguagesProc)
        statement.close()
    }

    private fun migrateLanguages() {

        //language=SQL
        val createLanguageSQL = this.connection.prepareStatement(
            """
            select migrate_languages_proc from migrate_languages_proc(?, ?);
        """.trimIndent()
        )

        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nLanguages ")
            val result = it.run(
                "match (n:Language) return count(n) as count"
            )

            while (result.hasNext()) {
                val record = result.next()
                count = record.get("count").asInt()
                print("Count: $count \n")
            }

            result.consume()
        }

        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i + 1} ")
                val getUserResult = it.run(
                    """
                        match (n:Language)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        with * 
                        match (n)-[:ethnologue {active: true}]->(eth:EthnologueLanguage)
                        -[:name {active: true}]->(ethName:Property) 
                        return 
                            n.id as id, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt,
                            ethName.value as ethNameValue
                    """.trimIndent()
                )

                // var langId: String? = null
                var ethName: String? = null
                var langName: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()

                    // langId = record.get("langId").asString()
                    val propName = record.get("propName").asString()
                    ethName = record.get("ethNameValue").asString()
                    when (propName) {
//                        "ethNameValue" -> {
//                            if (!record.get("propValue").isNull){
//                                ethName = record.get("propValue").asString()
//                            }
//                        }
                        "name" -> {
                            if (!record.get("propValue").isNull) {
                                langName = record.get("propValue").asString()
                            }
                        }
                        else -> {
                            // print("lang xxx: failed to recognize property $propName ")
                        }
                    }
                }

                it.commit()
                it.close()

                // write to postgres
                createLanguageSQL.setString(1, ethName)
                createLanguageSQL.setString(2, langName)
//
//                if (langName != null) {
//                } else {
//
//                     createLanguageSQL.setNull(2, Types.NULL)
//                }
//
//                createLanguageSQL.setString(3, name)
//
//                if (population != null) {
//                    createLanguageSQL.setInt(4, population)
//                } else {
//                    createLanguageSQL.setNull(4, Types.NULL)
//                }
//
//                if (provisionalCode != null) {
//                    createLanguageSQL.setString(5, provisionalCode)
//                } else {
//                    createLanguageSQL.setNull(5, Types.NULL)
//                }

                val createResult = createLanguageSQL.executeQuery()
                createResult.next()
                val returnCode = createResult.getInt(1)
                print("internal ethId: xxx returnCode: $returnCode ")
                createResult.close()
            }
        }
    }

    val migratePartnersProc = """
        create or replace function migrate_partners_proc(
            in groupName varchar(255),
            in globalInnovationsClient bool,
            in pmcEntityCode varchar(32)
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vGroupId INT;
            vPersonId INT;
        begin
            SELECT sys_group_id
            FROM sys_groups
            INTO vGroupId
            WHERE sys_groups.name = groupName;
            IF found THEN
                INSERT INTO sc_partners("sys_group_id","is_global_innovations_client", "pmc_entity_code")
                VALUES (vGroupId, globalInnovationsClient, pmcEntityCode)
                RETURNING sys_group_id
                INTO vGroupId;
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migratePartnersProc)
        statement.close()
    }
    private fun migratePartners() {
        val createPartnerSQL = this.connection.prepareStatement(
            """
            select migrate_partners_proc from migrate_partners_proc(?, ?, ?);
        """.trimIndent()
        )
        var count = 0

        neo4j.driver.session().readTransaction {
            print("\nPartners ")
            val result = it.run(
                "match (n:Partner) return count(n) as count"
            )

            while (result.hasNext()) {
                val record = result.next()
                count = record.get("count").asInt()
                print("Count: $count \n")
            }

            result.consume()
        }
        for (i in 0 until count) {
            neo4j.driver.session().readTransaction {
                print("\n${i + 1} ")
                val getUserResult = it.run(
                    """
                        match (n:Partner)
                        with *
                        skip $i
                        limit 1
                        match (n)-[r {active: true}]->(prop:Property)
                        with * 
                        match (n)-[:organization {active: true}]->(org:Organization)
                        -[:name {active: true}]->(orgName:Property) 
                        return 
                            n.id as groupId, 
                            type(r) as propName, 
                            prop.value as propValue, 
                            prop.createdAt as createdAt,
                            orgName.value as groupName
                    """.trimIndent()
                )
                var globalInnovationsClient: Boolean? = null
                var pmcEntityCode: String? = null
                var groupName: String? = null

                while(getUserResult.hasNext()){
                    val record = getUserResult.next()
                    val propName = record.get("propName").asString()

                    groupName = record.get("groupName").asString()
                    when(propName){
                        "globalInnovationsClient"->{
                            globalInnovationsClient = record.get("propValue").asBoolean()
                        }
                        "pmcEntityCode" ->{
                            pmcEntityCode = record.get("propValue").asString()
                        }
                        else -> {
                            print(" failed to recognize property $propName ")
                        }
                    }
                }
                it.commit()
                it.close()

                createPartnerSQL.setString(1,groupName)
                if (globalInnovationsClient != null) {
                    createPartnerSQL.setBoolean(2, globalInnovationsClient)
                } else {
                    createPartnerSQL.setNull(2, Types.NULL)
                }
                createPartnerSQL.setString(3,pmcEntityCode)

                val createResult = createPartnerSQL.executeQuery()
                createResult.next()
                val code = createResult.getInt(1)
                print(" code:$code")
                createResult.close()
            }
        }

    }

    val migrateProjectsProc = """
        create or replace function migrate_projects_proc(
            in departmentId varchar(32),
            in marketingLocation int,
            in name varchar(32),
            in primaryLocation int,
        )
        returns INT
        language plpgsql
        as ${'$'}${'$'}
        declare
            vResponseCode INT;
            vProjectId INT;
            vPersonId INT;
        begin
            SELECT sys_group_id
            FROM sys_groups
            INTO vGroupId
            WHERE sys_group_id = pGroupId;
            IF found THEN
                INSERT INTO sc_partners("sys_group_id","is_global_innovations_client", "pmc_entity_code")
                VALUES (vGroupId, globalInnovationsClient, pmcEntityCode)
                RETURNING sys_groups.sys_group_id
                INTO vGroupId;
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            END IF;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateProjectsProc)
        statement.close()
    }


    private fun migrateProjects(){

    }

}

