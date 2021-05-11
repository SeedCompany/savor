package core.database

import core.Config
import org.neo4j.driver.AuthTokens
import org.neo4j.driver.Driver
import org.neo4j.driver.GraphDatabase

class Neo4j (
    val config: Config,
) : AutoCloseable {
    val driver: Driver

    init {
        val driverConfig = org.neo4j.driver.Config
            .builder()
            .withoutEncryption()
            .withTrustStrategy(
                org.neo4j.driver.Config.TrustStrategy.trustAllCertificates()
                    .withoutHostnameVerification()
            )
            .build()

        this.driver = GraphDatabase.driver(
            config.neo4jUrl,
            AuthTokens.basic(config.neo4jUser, config.neo4jPassword),
            driverConfig
        )

        driver.verifyConnectivity()
    }

    override fun close() {
        this.driver.close()
    }

}