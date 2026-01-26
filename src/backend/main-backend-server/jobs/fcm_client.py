from firebase_admin import messaging


class FcmClient:
    def send(
        self,
        token: str,
        data: dict[str, str],
        title: str | None = None,
        body: str | None = None,
    ) -> str:
        notification = None
        if title or body:
            notification = messaging.Notification(title=title, body=body)
        message = messaging.Message(token=token, data=data, notification=notification)
        return messaging.send(message)
