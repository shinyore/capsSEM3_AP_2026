#!/usr/bin/env python3
"""Benchmark the parameterized AP CP4 SQL workload with PostgreSQL EXPLAIN."""
from __future__ import annotations

import argparse
import csv
import re
import statistics
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QUERY_FILE = ROOT / "dbms" / "04_queries.sql"
PLAN_DIR = ROOT / "dbms" / "plans"

# Representative deterministic parameters refer to dbms/06_synthetic_data.sql.
PARAMS = {
    "R1": ("student1@example.test",),
    "R2": ("student1@example.test",),
    "R3": ("student-user-00001",),
    "R4": ("STUDENT", True, 25, 0),
    "R5": ("student-user-00001",),
    "R6": ("student-user-00001",),
    "R7": ("industry-user-001",),
    "R8": ("institution-user-001",),
    "R9": (),
    "R10": ("Engineering", "Skill"),
    "R11": ("student-user-00001",),
    "R12": (),
    "R13": ("assessment-001",),
    "R14": ("student-user-00001",),
    "R15": ("student-user-00001",),
    "R16": ("student-user-00001",),
    "R17": ("INTERNSHIP", "Remote", 25, 0),
    "R18": ("industry-user-001",),
    "R19": ("student-profile-00001", "opportunity-0001"),
    "R20": ("student-user-00001",),
    "R21": ("industry-user-001",),
    "R22": ("application-000001", "student-user-00001"),
    "R23": ("industry-user-001",),
    "R24": ("student-user-00001",),
    "R25": ("industry-user-004",),
    "R26": (None, None, None),
    "R27": (None, None),
    "R28": ("student-user-00001",),
    "R29": ("student-user-00001",),
    "R30": ("institution-user-001",),
    "R31": ("student-user-00001", "student-user-00001"),
    "R32": ("industry-user-001",),
    "R33": ("industry-user-001",),
    "R34": ("industry-user-001",),
    "R35": ("institution-user-001",),
    "R36": ("institution-user-001",),
    "R37": (),
    "R38": (),
    "R39": (),
    "R40": (),
    "W1": ("bench-created-user", "Benchmark User", "bench-created@example.test", "hash", "+15550000100", "STUDENT"),
    "W2": ("bench-created-student-profile", "bench-w2-user"),
    "W3": ("bench-created-institution", "bench-w3-user", "Benchmark Institute", "bench-inst@example.test"),
    "W4": ("bench-created-company", "bench-w4-user", "Benchmark Company", "bench-company@example.test"),
    "W5": ("student-user-00001", "Updated Student", "+15550000101", "STUDENT"),
    "W6": ("student-user-00001", False),
    "W7": ("bench-upsert-profile", "student-user-00001", "institution-001", "B.Tech", "Computing", 2027, 6, "Updated bio", None, "https://example.test/r", "https://example.test/in", "https://example.test/gh", "https://example.test"),
    "W8": ("industry-user-001", "Updated Company", "updated@example.test", "https://example.test", "Office", "Updated", "+15550000200"),
    "W9": ("institution-001", "institution-user-001", "Updated Institute", "updated-inst@example.test", "https://example.test", "Campus", "Updated", "+15550000300"),
    "W10": ("institution-001", True),
    "W11": ("company-001", True),
    "W12": ("bench-created-skill", "Benchmark Skill", "Engineering", "Synthetic benchmark skill"),
    "W13": ("bench-upsert-student-skill", "student-profile-00001", "skill-001", "ADVANCED", "MANUAL"),
    "W14": ("student-user-00001", "skill-001", "EXPERT"),
    "W15": ("student-user-00001", "skill-001"),
    "W16": ("bench-assessment-result", "student-profile-00001", "assessment-001", 4, 80.0, "ADVANCED"),
    "W17": ("bench-assessment-skill", "student-profile-00001", "skill-002", "ADVANCED"),
    "W18": ("bench-recommendation", "student-profile-00001", "skill-003", "Benchmark recommendation", "Synthetic recommendation", "BEGINNER", "https://example.test", 2),
    "W19": ("student-user-00001", "recommendation-000001", True),
    "W20": ("bench-created-opportunity", "industry-user-001", "Benchmark Opportunity", "INTERNSHIP", "Description", "Responsibilities", "Qualifications", "Remote", "REMOTE", "$70000", 2, "https://example.test/apply", "2027-12-01 00:00:00", "2028-01-01 00:00:00", "2028-06-01 00:00:00", "OPEN", "2026-11-23 00:00:00"),
    "W21": ("industry-user-001", "opportunity-0001", "Updated Opportunity", "Updated description", "Responsibilities", "Qualifications", "Remote", "REMOTE", "$80000", 3, "https://example.test/apply", "2027-12-01 00:00:00", "2028-01-01 00:00:00", "2028-06-01 00:00:00"),
    "W22": ("industry-user-001", "opportunity-0001", "CLOSED"),
    "W23": ("industry-user-100", "opportunity-1100"),
    "W24": ("bench-created-application", "student-profile-00001", "opportunity-1100", "Synthetic application"),
    "W25": ("bench-created-history", "application-000001", "student-user-00001"),
    "W26": ("bench-company-notification", "application-000001"),
    "W27": ("application-000001", "UNDER_REVIEW", "Synthetic review"),
    "W28": ("bench-created-history-2", "application-000001", "UNDER_REVIEW", "Synthetic update", "industry-user-001"),
    "W29": ("bench-applicant-notification", "application-000001", "Application updated", "/student/applications"),
    "W30": ("student-user-00001", "application-000001"),
    "W31": ("bench-created-interview", "application-000001", "2027-01-10 10:00:00", "Video call", "https://example.test/meeting", "Synthetic interview"),
    "W32": ("industry-user-004", "interview-00001", "2027-01-11 10:00:00", "Updated location", "https://example.test/meeting2", "Updated notes", "CANCELLED"),
    "W33": ("bench-created-internship", "application-000020", "Benchmark internship", "2027-01-01 00:00:00", "2027-04-01 00:00:00", "Synthetic notes"),
    "W34": ("internship-00001", "ACTIVE"),
    "W35": ("bench-created-placement", "student-profile-00001", "institution-001", "company-001", "Benchmark role", "$90000", "Synthetic placement"),
    "W36": ("placement-0001", "Updated role", "$95000", "Updated notes"),
    "W37": ("notification-000001", "student-user-00001"),
    "W38": ("student-user-00001",),
    "W39": ("notification-000001", "student-user-00001"),
}


def parse_queries() -> list[tuple[str, str, str]]:
    text = QUERY_FILE.read_text()
    parts = re.split(r"(?m)^-- (READ|WRITE)\s*$", text)
    out = []
    for i in range(1, len(parts), 2):
        kind, body = parts[i], parts[i + 1]
        statements = "\n".join(line for line in body.splitlines() if not line.lstrip().startswith("--"))
        statements = statements.strip()
        if not statements:
            continue
        match = re.search(r"\b([RW]\d+)\s*:", body)
        if not match:
            raise ValueError(f"Missing query ID in {kind} block")
        qid = match.group(1)
        sql_lines = []
        for line in body.splitlines():
            if line.lstrip().startswith("--"):
                continue
            sql_lines.append(line)
        sql = "\n".join(sql_lines).strip()
        if not sql.endswith(";"):
            raise ValueError(f"{qid} does not end in a semicolon")
        out.append((qid, kind, sql))
    return out


def literal(value: object) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def bind(sql: str, params: tuple[object, ...], qid: str) -> str:
    max_param = max((int(n) for n in re.findall(r"\$(\d+)\b", sql)), default=0)
    if max_param != len(params):
        raise ValueError(f"{qid}: expected {max_param} parameters, got {len(params)}")
    return re.sub(r"\$(\d+)\b", lambda m: literal(params[int(m.group(1)) - 1]), sql)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--database", default="skillbridge_ap_cp4")
    ap.add_argument("--host", default="/private/tmp/skillbridge-ap-cp4-socket")
    ap.add_argument("--port", default="55439")
    ap.add_argument("--user", default="shine")
    ap.add_argument("--runs", type=int, default=3)
    args = ap.parse_args()
    if args.runs < 1:
        raise SystemExit("--runs must be positive")

    queries = parse_queries()
    if len(queries) != 79:
        raise SystemExit(f"Expected 79 marked queries, found {len(queries)}")
    if set(PARAMS) != {q[0] for q in queries}:
        raise SystemExit("Parameter map does not cover exactly the workload IDs")
    PLAN_DIR.mkdir(parents=True, exist_ok=True)
    psql_base = ["psql", "-h", args.host, "-p", args.port, "-U", args.user,
                 "-d", args.database, "-X", "-A", "-t", "-q", "-v", "ON_ERROR_STOP=1"]

    version = subprocess.run(psql_base + ["-c", "SELECT version();"], check=True,
                             capture_output=True, text=True).stdout.strip()
    rows = []
    for qid, kind, original_sql in queries:
        sql = bind(original_sql, PARAMS[qid], qid)
        plan_file = PLAN_DIR / f"{qid[0]}{int(qid[1:]):02d}.txt"
        times = []
        with plan_file.open("w") as plan_out:
            plan_out.write(f"Query: {qid} ({kind})\nDatabase: {args.database}\n")
            plan_out.write(f"PostgreSQL: {version}\nRuns: {args.runs}\nParameters: {PARAMS[qid]!r}\n\n")
            plan_out.write("SQL:\n" + sql + "\n\n")
            for run in range(1, args.runs + 1):
                wrapped = f"BEGIN;\nEXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) {sql}\nROLLBACK;\n"
                proc = subprocess.run(psql_base, input=wrapped, capture_output=True, text=True)
                if proc.returncode != 0:
                    plan_out.write(f"RUN {run} FAILED\n{proc.stdout}\n{proc.stderr}\n")
                    raise RuntimeError(f"{qid} run {run} failed: {proc.stderr.strip()}")
                match = re.search(r"Execution Time: ([0-9.]+) ms", proc.stdout)
                if not match:
                    raise RuntimeError(f"{qid} run {run} had no Execution Time in EXPLAIN output")
                elapsed = float(match.group(1))
                times.append(elapsed)
                plan_out.write(f"{'=' * 20} RUN {run}: {elapsed:.3f} ms {'=' * 20}\n")
                plan_out.write(proc.stdout.rstrip() + "\n")
                if run < args.runs:
                    plan_out.write("\n")
                if proc.stderr.strip():
                    plan_out.write("STDERR:\n" + proc.stderr + "\n")
        avg = statistics.mean(times)
        rows.append({"query_id": qid, "type": kind, "runs": args.runs,
                     "avg_ms": f"{avg:.3f}", "median_ms": f"{statistics.median(times):.3f}",
                     "min_ms": f"{min(times):.3f}", "max_ms": f"{max(times):.3f}",
                     "plan_file": str(plan_file.relative_to(ROOT))})
        print(f"{qid:<4} {kind:<5} avg {avg:9.3f} ms  {plan_file.relative_to(ROOT)}", flush=True)

    summary_file = PLAN_DIR / "summary.csv"
    with summary_file.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["query_id", "type", "runs", "avg_ms", "median_ms", "min_ms", "max_ms", "plan_file"], lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"Completed {len(rows)} queries x {args.runs} runs. Summary: {summary_file.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
