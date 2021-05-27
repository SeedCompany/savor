package components.migration.scripts

import org.seedcompany.api.core.Neo4j
import java.sql.Connection
import java.sql.Types

class MigrateEthnologue(val neo4j: Neo4j, val connection: Connection) {
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

    public fun migrateEthnologue() {

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
}