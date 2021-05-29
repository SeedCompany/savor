package core.database.scripts

import core.Config
import core.database.Neo4j
import java.sql.Connection

class MigrateLanguages(val config: Config, val neo4j: Neo4j, val connection: Connection)  {
    val migrateLanguagesProc = """
        create or replace function migrate_languages_proc(
            in pEthId varchar(50),
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
            WHERE sil_table_of_languages.sys_ethnologue_legacy_id = pEthId;
            IF found THEN
                INSERT INTO sc_languages("sys_ethnologue_id","name")
                VALUES (vEthId, pLangName)
                RETURNING sys_ethnologue_id
                INTO vEthId;
                vResponseCode := 0;
            ELSE
                vResponseCode := 2;
            return vResponseCode;
        end; ${'$'}${'$'}
    """.trimIndent()

    init {
        val statement = this.connection.createStatement()
        statement.execute(this.migrateLanguagesProc)
        statement.close()
    }

    public fun migrateLanguages() {

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
                            eth.id as ethIdValue
                    """.trimIndent()
                )

                // var langId: String? = null
                var ethId: String? = null
                var langName: String? = null

                while (getUserResult.hasNext()) {
                    val record = getUserResult.next()

                    // langId = record.get("langId").asString()
                    val propName = record.get("propName").asString()
                    ethId = record.get("ethIdValue").asString()
                    when (propName) {
//                        "ethIdValue" -> {
//                            if (!record.get("propValue").isNull){
//                                ethId = record.get("propValue").asString()
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
                createLanguageSQL.setString(1, ethId)
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
}