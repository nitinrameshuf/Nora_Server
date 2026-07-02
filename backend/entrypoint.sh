#!/bin/sh
set -e

# Workers set RUN_MIGRATIONS=false so only the web pod migrates.
if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
    python manage.py migrate --noinput
    if [ -n "${DJANGO_SUPERUSER_USERNAME:-}" ]; then
        python manage.py createsuperuser --noinput 2>/dev/null || true
    fi
fi

exec "$@"
