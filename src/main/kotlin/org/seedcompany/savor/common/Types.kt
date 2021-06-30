package org.seedcompany.savor.common

import kotlinx.serialization.Serializable

enum class ErrorType {
    NoError,
    UnknownError,
    BadMessage,
    TransportError,
    DuplicateEmail,
    IdNotFound,
    UserIdNotFound,
    UnknownMessage,
    BadCredentials,
    UserNotFound,
    SessionNot,
    TokenNotFound,
}

@Serializable
data class GenericError(
    val error: ErrorType,
    val type: MessageType = MessageType.Error,
)

@Serializable
data class GenericMessage(
    val type: MessageType,
)

enum class MessageType {
    Error,
    StartSessionRequest,
    StartSessionResponse,
    UserLoginRequest,
    UserLoginResponse,
    UserLogoutRequest,
    UserLogoutResponse,
    UserRegisterRequest,
    UserRegisterResponse,
}