from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
from ..core.settings import settings

conf = ConnectionConfig(
    MAIL_USERNAME=settings.MAIL_USERNAME,
    MAIL_PASSWORD=settings.MAIL_PASSWORD,
    MAIL_FROM="FinanceTracker@App.verification",
    MAIL_PORT=587,
    MAIL_SERVER="smtp.gmail.com",
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
    USE_CREDENTIALS=True
)

async def send_verification_email(email: str, token: str):
    link = f"{settings.API_BASE_URL_MOBILE}/auth/verify?token={token}"
    message = MessageSchema(
        subject="Verify your email",
        recipients=[email],
        body=f"Click the link to verify: {link}",
        subtype="plain"
    )
    fm = FastMail(conf)
    await fm.send_message(message)
