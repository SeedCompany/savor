package org.seedcompany.savor

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.ConfigurationPropertiesScan
import org.springframework.boot.runApplication

@SpringBootApplication
@ConfigurationPropertiesScan
class SavorApplication

fun main(args: Array<String>) {
	runApplication<SavorApplication>(*args)
}
