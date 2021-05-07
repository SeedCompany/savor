package core

import com.typesafe.config.ConfigFactory
import io.ktor.config.*

class Config {
    private val config = HoconApplicationConfig(ConfigFactory.load())

    val postgresUrl = config.propertyOrNull("savor.postgres.url")?.getString()
    val postgresDatabase = config.propertyOrNull("savor.postgres.database")?.getString()
    val postgresUser = config.propertyOrNull("savor.postgres.user")?.getString()
    val postgresPassword = config.propertyOrNull("savor.postgres.password")?.getString()
    val postgresPort = config.propertyOrNull("savor.postgres.port")?.getString()

    val neo4jUrl = config.propertyOrNull("savor.neo4j.url")?.getString()
    val neo4jDatabase = config.propertyOrNull("savor.neo4j.database")?.getString()
    val neo4jUser = config.propertyOrNull("savor.neo4j.user")?.getString()
    val neo4jPassword = config.propertyOrNull("savor.neo4j.password")?.getString()
}