package org.seedcompany.savor.core

import org.neo4j.driver.AuthTokens
import org.neo4j.driver.Driver
import org.neo4j.driver.GraphDatabase
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.annotation.Bean
import org.springframework.stereotype.Component

@Component
class Neo4j (
    @Autowired
    val config: Neo4jConfig,
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
            config.url,
            AuthTokens.basic(config.user, config.password),
            driverConfig
        )

        driver.verifyConnectivity()
    }

    @Bean
    fun getNeo4jDriver(): Driver {
        return this.driver
    }

    override fun close() {
        this.driver.close()
    }

}