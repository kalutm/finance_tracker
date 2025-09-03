from typing import Optional

class AuthError(Exception):
    """Base for auth errors."""

class UserAlreadyExists(AuthError):
    def __init__(self, email: str, message: Optional[str] = None):
        self.email = email
        super().__init__(message or f"User with email {email} already exists")

class UserNotFound(AuthError):
    pass

class InvalidCredentials(AuthError):
    pass

class GoogleTokenInvalid(AuthError):
    pass

class AccountExistsWithDifferentProvider(AuthError):
    pass

class AccountNotVerified(AuthError):
    pass

class AccountAlreadyVerified(AuthError):
    pass

class RateLimitExceeded(AuthError):
    pass

class InvalidVerificationToken(AuthError):
    pass

class InvalidAccessToken(AuthError):
    pass

class InvalidRefreshToken(AuthError):
    pass