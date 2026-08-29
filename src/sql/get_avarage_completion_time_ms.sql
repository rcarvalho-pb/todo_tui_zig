SELECT AVG(finished_at - started_at) FROM tasks WHERE finished_at IS NOT NULL AND started_at is NOT NULL;
