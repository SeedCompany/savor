package org.seedcompany.savor.components.authentication

import org.springframework.stereotype.Component
import java.sql.Connection

@Component
class Authentication ( val conn: Connection)