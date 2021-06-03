package org.seedcompany.savor

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class SavorApplication

fun main(args: Array<String>) {
	runApplication<SavorApplication>(*args)
}
