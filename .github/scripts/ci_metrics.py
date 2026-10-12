#!/usr/bin/env python3
"""Summarize downloaded GitHub run/jobs JSON without accessing credentials."""
from datetime import datetime
import json
from pathlib import Path
import sys


def timestamp(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def summarize(run, pages):
    jobs = [job for page in pages for job in page["jobs"]]
    if not jobs or any(not job.get("completed_at") for job in jobs):
        raise ValueError("Run must contain completed jobs")
    attempts = {job.get("run_attempt", 1) for job in jobs}
    if attempts != {run.get("run_attempt", 1)}:
        raise ValueError("Do not mix run attempts")
    run_start = run.get("run_started_at")
    if not run_start:
        if run.get("run_attempt", 1) != 1:
            raise ValueError("Rerun requires its attempt start time")
        run_start = run["created_at"]
    terraform = [job for job in jobs if job["name"].startswith("terraform (")]
    if not terraform:
        raise ValueError("No Terraform jobs found")
    start = min(timestamp(job["started_at"]) for job in terraform)
    end = max(timestamp(job["completed_at"]) for job in terraform)
    return {
        "run_id": run["id"],
        "attempt": run.get("run_attempt", 1),
        "workflow_seconds": (max(timestamp(job["completed_at"]) for job in jobs)
                             - timestamp(run_start)).total_seconds(),
        "terraform_wall_seconds": (end - start).total_seconds(),
        "terraform_runner_seconds": sum(
            (timestamp(job["completed_at"]) - timestamp(job["started_at"])).total_seconds()
            for job in terraform),
        "terraform_jobs": len(terraform),
        "conclusions": sorted({job["conclusion"] for job in terraform}),
    }


if __name__ == "__main__":
    run_data = json.loads(Path(sys.argv[1]).read_text())
    job_pages = json.loads(Path(sys.argv[2]).read_text())
    print(json.dumps(summarize(run_data, job_pages), indent=2))
