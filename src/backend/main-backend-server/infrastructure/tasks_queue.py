import json
import logging
import os
import urllib.error
import urllib.request

from google.cloud import tasks_v2
from google.protobuf import duration_pb2

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
    def __init__(
        self,
        tasks_stub_url=None,
        target_url=None,
        timeout_seconds=None,
        project_id=None,
        location=None,
        queue_name=None,
        invoker_service_account=None,
    ):
        self._tasks_stub_url = tasks_stub_url or os.getenv("TASKS_STUB_URL")
        self._target_url = target_url or os.getenv(
            "TASKS_TARGET_URL", "http://suggestion-job:8080/jobs/suggestions"
        )
        self._timeout_seconds = int(
            timeout_seconds or os.getenv("TASKS_STUB_TIMEOUT_SECONDS", "10")
        )
        self._project_id = (
            project_id
            or os.getenv("PROJECT_ID")
            or os.getenv("GOOGLE_CLOUD_PROJECT")
        )
        self._location = location or os.getenv("TASKS_LOCATION") or os.getenv("REGION")
        self._queue_name = queue_name or os.getenv("TASKS_QUEUE")
        self._invoker_service_account = invoker_service_account or os.getenv(
            "TASKS_INVOKER_SERVICE_ACCOUNT"
        )

    def enqueue_suggestion(self, payload):
        if self._tasks_stub_url:
            return self._enqueue_stub(payload)
        return self._enqueue_cloud_tasks(payload)

    def _enqueue_stub(self, payload):
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

    def _enqueue_cloud_tasks(self, payload):
        if not self._queue_name:
            logger.error("TASKS_QUEUE is not set")
            return False
        if not self._target_url:
            logger.error("TASKS_TARGET_URL is not set")
            return False
        if not self._project_id or not self._location:
            logger.error("PROJECT_ID or TASKS_LOCATION is not set")
            return False
        if not self._invoker_service_account:
            logger.error("TASKS_INVOKER_SERVICE_ACCOUNT is not set")
            return False

        client = tasks_v2.CloudTasksClient()
        queue_path = client.queue_path(
            self._project_id, self._location, self._queue_name
        )

        task = tasks_v2.Task(
            http_request=tasks_v2.HttpRequest(
                http_method=tasks_v2.HttpMethod.POST,
                url=self._target_url,
                headers={"Content-Type": "application/json"},
                body=json.dumps(payload).encode("utf-8"),
                oidc_token=tasks_v2.OidcToken(
                    service_account_email=self._invoker_service_account
                ),
            )
        )
        dispatch_deadline_seconds = max(self._timeout_seconds, 15)
        if dispatch_deadline_seconds != self._timeout_seconds:
            logger.info(
                "tasks_dispatch_deadline_adjusted requested=%s adjusted=%s",
                self._timeout_seconds,
                dispatch_deadline_seconds,
            )
        task.dispatch_deadline = duration_pb2.Duration(
            seconds=dispatch_deadline_seconds
        )

        try:
            client.create_task(parent=queue_path, task=task)
        except Exception as exc:
            logger.error("dispatch_failed target=%s error=%s", self._target_url, exc)
            return False

        return True
