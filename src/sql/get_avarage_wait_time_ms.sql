SELECT AVG(started_at - created_at) FROM tasks WHERE started_at IS NOT NULL;
