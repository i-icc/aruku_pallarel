from firebase_admin import messaging


class FcmClient:
    def send(self, token: str, data: dict[str, str]) -> str:
        message = messaging.Message(token=token, data=data)
        return messaging.send(message)
