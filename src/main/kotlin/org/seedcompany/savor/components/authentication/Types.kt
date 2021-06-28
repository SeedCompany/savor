package org.seedcompany.savor.components.authentication

import kotlinx.serialization.Serializable
import org.seedcompany.savor.common.ErrorType
import org.seedcompany.savor.common.MessageType

// Session
@Serializable
data class StartSessionRequest(
    val token: String? = null,
    val sessionId: String = "",
    var type: MessageType = MessageType.StartSessionRequest,
)

@Serializable
data class StartSessionResponse(
    val success: Boolean,
    val sessionId: String = "",
    var type: MessageType = MessageType.StartSessionResponse,
)

// Login
@Serializable
data class UserLoginRequest (
    val email: String,
    val password: String,
    val sessionId: String = "",
    val type: MessageType = MessageType.UserLoginRequest,
)

@Serializable
data class UserLoginResponse (
    val error: ErrorType,
    val token: String? = null,
    val sessionId: String = "",
    val type: MessageType = MessageType.UserLoginResponse,
)

// Logout
@Serializable
data class UserLogoutRequest (
    val token: String? = null,
    val sessionId: String = "",
    val type: MessageType = MessageType.UserLogoutRequest,
)

@Serializable
data class UserLogoutResponse (
    val error: ErrorType,
    val sessionId: String = "",
    val type: MessageType = MessageType.UserLogoutResponse,
)

// Register
@Serializable
data class UserRegisterRequest (
    val email: String,
    val password: String,
    val sessionId: String = "",
    val type: MessageType = MessageType.UserRegisterRequest,
)

@Serializable
data class UserRegisterResponse (
    val error: ErrorType,
    val token: String? = null,
    val sessionId: String = "",
    val type: MessageType = MessageType.UserRegisterResponse,
)