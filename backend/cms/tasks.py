from celery import shared_task


@shared_task
def ping():
    """Round-trip task used to verify the RabbitMQ broker (Story 8)."""
    return "pong"
