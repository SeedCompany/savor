package org.seedcompany.savor.core

import org.seedcompany.savor.common.*
import com.fasterxml.jackson.core.JsonProcessingException
import com.fasterxml.jackson.databind.JsonMappingException
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.seedcompany.savor.components.authentication.*
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.ApplicationEventPublisher
import org.springframework.context.event.EventListener
import org.springframework.core.annotation.Order
import org.springframework.stereotype.Component
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketSession

@Component
class MessageRouter (
    @Autowired
    val publisher:ApplicationEventPublisher,
    @Autowired
    val sessionManager: SessionManager,
){

    val mapper = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    // called by the websocket handler to add messages to the server's buses
    public fun route(session: WebSocketSession, message: TextMessage){
        try {
            val genericMessage = mapper.decodeFromString<GenericMessage>(message.payload)
            when(genericMessage.type){
                // keep alphabetized
                MessageType.StartSessionRequest -> {
                    val specificMessage = mapper.decodeFromString<StartSessionRequest>(message.payload)
                    val messageWithId = specificMessage.copy(sessionId = session.id)
                    publisher.publishEvent(messageWithId)
                }
                MessageType.UserLoginRequest -> {
                    val specificMessage = mapper.decodeFromString<UserLoginRequest>(message.payload)
                    val messageWithId = specificMessage.copy(sessionId = session.id)
                    publisher.publishEvent(messageWithId)
                }
                MessageType.UserLogoutRequest -> {
                    val specificMessage = mapper.decodeFromString<UserLogoutRequest>(message.payload)
                    val messageWithId = specificMessage.copy(sessionId = session.id)
                    publisher.publishEvent(messageWithId)
                }
                MessageType.UserRegisterRequest -> {
                    val specificMessage = mapper.decodeFromString<UserRegisterRequest>(message.payload)
                    val messageWithId = specificMessage.copy(sessionId = session.id)
                    publisher.publishEvent(messageWithId)
                }
                else -> {
                    // unable to match to specific message, send error
                    val response = mapper.encodeToString(GenericError(error = ErrorType.UnknownMessage))
                    session.sendMessage(TextMessage(response))
                }
            }
        } catch (e: JsonMappingException){
            println(e.localizedMessage)
            val response = mapper.encodeToString(GenericError(error = ErrorType.BadMessage))
            session.sendMessage(TextMessage(response))
        } catch (e: JsonProcessingException){
            println(e.localizedMessage)
            val response = mapper.encodeToString(GenericError(error = ErrorType.BadMessage))
            session.sendMessage(TextMessage(response))
        } finally {

        }
    }

    // listeners that send messages over the wire
    // use @Order to ensure these are called first among their peer listeners

    @EventListener
    @Order(10)
    fun userLoginResponse(event: UserLoginResponse) {
        val session = sessionManager.get(event.sessionId!!) ?: return
        val response = mapper.encodeToString(event.copy(sessionId = ""))
        session.sendMessage(TextMessage(response))
    }

    @EventListener
    @Order(10)
    fun userLogoutResponse(event: UserLogoutResponse) {
        val session = sessionManager.get(event.sessionId!!) ?: return
        val response = mapper.encodeToString(event.copy(sessionId = ""))
        session.sendMessage(TextMessage(response))
    }

    @EventListener
    @Order(10)
    fun userRegisterResponse(event: UserRegisterResponse) {
        val session = sessionManager.get(event.sessionId!!) ?: return
        val response = mapper.encodeToString(event.copy(sessionId = ""))
        session.sendMessage(TextMessage(response))
    }

    @EventListener
    @Order(10)
    fun startSessionResponse(event: StartSessionResponse) {
        val session = sessionManager.get(event.sessionId!!) ?: return
        val response = mapper.encodeToString(event.copy(sessionId = ""))
        session.sendMessage(TextMessage(response))
    }

}
