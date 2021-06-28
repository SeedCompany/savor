package org.seedcompany.savor.core

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.context.properties.ConstructorBinding

@ConstructorBinding
@ConfigurationProperties(prefix = "neo4j")
data class Neo4jConfig (
    var url: String = "",
    var database: String = "",
    var user: String = "",
    var password: String = "",
)

@ConstructorBinding
@ConfigurationProperties(prefix = "app")
data class AppConfig (
    var jwtSecret: String = "",
)