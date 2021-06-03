package org.seedcompany.savor.components.migration.scripts

import org.seedcompany.savor.core.Neo4j
import java.sql.Connection


class MigrateUsers(val neo4j: Neo4j, val connection: Connection) {
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

    public fun migrateUsers() {

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
}