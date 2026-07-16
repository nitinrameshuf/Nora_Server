"""Lightweight persistence for mission state.

Story 14 calls the bridge a "state persistence layer". We keep it deliberately
simple: a SQLite file under a mounted volume (survives container restarts). This
is intentionally NOT the web app's PostgreSQL — the ROS side stays decoupled from
the site DB. Bridging live robot state into PostgreSQL (so the website can show
it) is left to Story 16 (telemetry relay).
"""
import json
import os
import sqlite3
import time
from typing import Optional

DEFAULT_PATH = os.environ.get("NORA_STATE_DB", "/var/lib/nora/mission_state.db")


class StateStore:
    def __init__(self, path: str = DEFAULT_PATH):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self._conn = sqlite3.connect(path)
        self._conn.execute(
            """
            CREATE TABLE IF NOT EXISTS telemetry (
                ts        REAL NOT NULL,
                seq       INTEGER,
                battery   REAL,
                x         REAL,
                y         REAL,
                heading   REAL,
                unsafe    INTEGER,
                raw       TEXT
            )
            """
        )
        self._conn.execute(
            "CREATE TABLE IF NOT EXISTS latest (k TEXT PRIMARY KEY, v TEXT NOT NULL)"
        )
        self._conn.commit()

    def record_telemetry(self, data: dict) -> None:
        self._conn.execute(
            "INSERT INTO telemetry (ts, seq, battery, x, y, heading, unsafe, raw) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (
                time.time(),
                data.get("seq"),
                data.get("battery"),
                data.get("x"),
                data.get("y"),
                data.get("heading"),
                1 if data.get("unsafe") else 0,
                json.dumps(data),
            ),
        )
        self._conn.execute(
            "INSERT INTO latest (k, v) VALUES ('mission_state', ?) "
            "ON CONFLICT(k) DO UPDATE SET v = excluded.v",
            (json.dumps(data),),
        )
        self._conn.commit()

    def latest_state(self) -> Optional[dict]:
        row = self._conn.execute(
            "SELECT v FROM latest WHERE k = 'mission_state'"
        ).fetchone()
        return json.loads(row[0]) if row else None

    def prune(self, keep_seconds: float) -> int:
        """Drop telemetry rows older than keep_seconds. Returns rows removed."""
        cutoff = time.time() - keep_seconds
        cur = self._conn.execute("DELETE FROM telemetry WHERE ts < ?", (cutoff,))
        self._conn.commit()
        return cur.rowcount

    def close(self) -> None:
        self._conn.close()
