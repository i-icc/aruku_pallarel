import json
import logging
import os
import urllib.error
import urllib.request

logger = logging.getLogger(__name__)


def post_json(url, payload, timeout_seconds):
    body = json.dumps(payload).encode("utf-8")
    request_obj = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request_obj, timeout=timeout_seconds) as response:
        return response.status


class TasksQueueClient:
    def __init__(self, tasks_stub_url=None, target_url=None, timeout_seconds=None):
        self._tasks_stub_url = tasks_stub_url or os.getenv("TASKS_STUB_URL")
        self._target_url = target_url or os.getenv(
            "TASKS_TARGET_URL", "http://suggestion-job:8080/jobs/suggestions"
        )
        self._timeout_seconds = int(
            timeout_seconds or os.getenv("TASKS_STUB_TIMEOUT_SECONDS", "10")
        )

    def enqueue_suggestion(self, payload):
        if not self._tasks_stub_url:
            logger.error("TASKS_STUB_URL is not set")
            return False

        tasks_url = f"{self._tasks_stub_url.rstrip('/')}/tasks"
        request_payload = {"target_url": self._target_url, "payload": payload}

        try:
            status = post_json(tasks_url, request_payload, self._timeout_seconds)
        except (urllib.error.URLError, ValueError) as exc:
            logger.error("dispatch_failed target=%s error=%s", tasks_url, exc)
            return False

        if not (200 <= status < 300):
            logger.error("dispatch_failed target=%s status=%s", tasks_url, status)
            return False

        return True
