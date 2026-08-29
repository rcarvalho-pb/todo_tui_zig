SELECT MAX(finished_at - started_at) FROM tasks WHERE finished_at IS NOT NULL AND started_at IS NOT NULL;
