package org.seedcompany.savor.core

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.seedcompany.savor.common.ErrorType
import org.seedcompany.savor.common.GenericError
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Component
import org.springframework.web.socket.CloseStatus
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketSession
import org.springframework.web.socket.handler.TextWebSocketHandler

@Component
class SavorWebSocketHandler(
    @Autowired
    val router: MessageRouter,
    @Autowired
    val sessionManager: SessionManager,
) : TextWebSocketHandler(
) {
    val mapper = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    public override fun handleTextMessage(session: WebSocketSession, message: TextMessage) {
        super.handleTextMessage(session, message)
        router.route(session, message)
    }

    override fun afterConnectionEstablished(session: WebSocketSession) {
        super.afterConnectionEstablished(session)
        sessionManager.put(session)
    }

    override fun afterConnectionClosed(session: WebSocketSession, status: CloseStatus) {
        super.afterConnectionClosed(session, status)
        sessionManager.remove(session.id)
    }

    override fun handleTransportError(session: WebSocketSession, exception: Throwable) {
        super.handleTransportError(session, exception)
        val response = mapper.encodeToString(GenericError(error = ErrorType.TransportError))
        session.sendMessage(TextMessage(response))
    }
}