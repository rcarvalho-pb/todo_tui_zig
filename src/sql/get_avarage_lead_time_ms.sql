SELECT AVG(finished_at - created_at) FROM tasks WHERE finished_at IS NOT NULL;
