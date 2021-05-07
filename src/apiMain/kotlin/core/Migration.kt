package core

import core.database.Neo4j
import java.sql.Connection

import org.neo4j.driver.Values.parameters


class Migration (
    val config: Config,
    val neo4j: Neo4j,
    val connection: Connection,
) {
    fun migrate(){
        val session = neo4j.driver.session()
        session.readTransaction {
            val result = it.run("", parameters("", ""))

            while (result.hasNext()){
                val record = result.next()
                val asdf = record.get("name").asString()
            }
        }
    }
}