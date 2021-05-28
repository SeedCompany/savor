package org.seedcompany.api.components.migration

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class MigrationController(
    @Autowired
    val migration: Migration
) {
    @GetMapping("/migrate")
    fun migrate (){
        println("asdf")
        migration.migrate()
    }
}