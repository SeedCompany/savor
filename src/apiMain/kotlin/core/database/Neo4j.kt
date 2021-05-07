package core.database

import core.Config
import org.neo4j.driver.AuthTokens
import org.neo4j.driver.Driver
import org.neo4j.driver.GraphDatabase

class Neo4j (
    val config: Config,
) : AutoCloseable {
    val driver: Driver = GraphDatabase.driver(
        config.neo4jUrl,
        AuthTokens.basic(config.neo4jUser, config.neo4jPassword)
    )

    override fun close() {
        this.driver.close()
    }

}