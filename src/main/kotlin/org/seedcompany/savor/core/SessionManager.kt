package org.seedcompany.savor.core
import org.springframework.stereotype.Component
import org.springframework.web.socket.WebSocketSession

@Component
class SessionManager {
    val sessions = mutableMapOf<String, WebSocketSession>()

    fun put(session: WebSocketSession) {
        sessions.put(session.id, session)
    }

    fun get(sessionId: String): WebSocketSession?{
        return sessions[sessionId]
    }

    fun remove(sessionId: String) {
        sessions.remove(sessionId)
    }
}