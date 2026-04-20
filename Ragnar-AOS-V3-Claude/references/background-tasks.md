# Background Tasks

## Problem

Long-running tasks — test suites, builds, deployments, database migrations — block the agent. The agent sits idle waiting for output instead of doing useful work. A 3-minute test suite wastes 3 minutes of agent time.

## Core Pattern: Fire-and-Forget with Notification

```
Agent                          Process Registry
  │                                  │
  ├── start("npm test") ───────────→ │ spawn process, register PID
  │                                  │
  ├── (continue other work) ←─────── │ returns session_id immediately
  │                                  │
  │   ... agent works on other tasks ...
  │                                  │
  ├── poll(session_id) ────────────→ │ check status + new output
  │   ← {running, new_lines: [...]} │
  │                                  │
  │   ... more work ...              │
  │                                  │
  │   ← NOTIFICATION: process exited │ notify_on_complete fires
  │     {exit_code: 0, output: ...}  │
  │                                  │
  └── log(session_id) ────────────→ │ get full output
```

## Process Registry

Track all background processes in a registry:

```python
@dataclass
class BackgroundProcess:
    session_id: str
    pid: int
    command: str
    start_time: float
    exit_code: Optional[int]     # None while running
    stdout_buffer: list[str]     # Rolling buffer of output lines
    stderr_buffer: list[str]
    notify_on_complete: bool
    watch_patterns: list[str]    # Patterns to watch for in output
    workdir: str
    last_poll_line: int          # Track what's been read

processes: dict[str, BackgroundProcess] = {}
```

## Actions

### Start

```python
def start_background(
    command: str,
    workdir: str = ".",
    notify_on_complete: bool = False,
    watch_patterns: list[str] = None
) -> str:
    """Start a background process. Returns session_id immediately."""
    session_id = str(uuid4())[:8]
    proc = subprocess.Popen(
        command, shell=True, cwd=workdir,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    processes[session_id] = BackgroundProcess(
        session_id=session_id,
        pid=proc.pid,
        command=command,
        start_time=time.time(),
        exit_code=None,
        stdout_buffer=[],
        stderr_buffer=[],
        notify_on_complete=notify_on_complete,
        watch_patterns=watch_patterns or [],
        workdir=workdir,
        last_poll_line=0
    )
    # Start output reader thread
    threading.Thread(target=_read_output, args=(session_id, proc)).start()
    return session_id
```

### Poll

Check status and get new output since last poll:

```python
def poll(session_id: str) -> dict:
    """Check process status and get new output lines."""
    proc = processes[session_id]
    new_lines = proc.stdout_buffer[proc.last_poll_line:]
    proc.last_poll_line = len(proc.stdout_buffer)
    
    return {
        "status": "running" if proc.exit_code is None else "exited",
        "exit_code": proc.exit_code,
        "new_lines": new_lines,
        "elapsed_seconds": time.time() - proc.start_time
    }
```

### Wait

Block until process completes (with timeout):

```python
def wait(session_id: str, timeout: int = 300) -> dict:
    """Block until process exits or timeout."""
    proc = processes[session_id]
    deadline = time.time() + timeout
    while proc.exit_code is None and time.time() < deadline:
        time.sleep(0.5)
    return poll(session_id)
```

### Log

Get full output with pagination:

```python
def log(session_id: str, offset: int = 0, limit: int = 200) -> dict:
    """Get full output log with pagination."""
    proc = processes[session_id]
    lines = proc.stdout_buffer[offset:offset + limit]
    return {
        "lines": lines,
        "total_lines": len(proc.stdout_buffer),
        "offset": offset,
        "has_more": offset + limit < len(proc.stdout_buffer)
    }
```

### Kill

Terminate a runaway process:

```python
def kill(session_id: str) -> dict:
    """Terminate a background process."""
    proc = processes[session_id]
    os.kill(proc.pid, signal.SIGTERM)
    time.sleep(1)
    if proc.exit_code is None:
        os.kill(proc.pid, signal.SIGKILL)
    return {"status": "killed", "pid": proc.pid}
```

## Watch Patterns

Fire a notification when specific patterns appear in output — useful for catching errors early without waiting for the process to finish.

```python
watch_patterns = ["ERROR", "FAIL", "Traceback", "WARN"]

def _check_patterns(session_id: str, line: str):
    proc = processes[session_id]
    for pattern in proc.watch_patterns:
        if pattern in line:
            notify_agent(
                f"Watch pattern '{pattern}' matched in process {session_id}",
                line=line
            )
```

**Use watch patterns for mid-process signals**, not end-of-process markers. For "process finished," use `notify_on_complete`.

## Example: Test Suite While Working

```python
# Agent kicks off tests in background
test_session = terminal(
    command="npm test -- --coverage",
    background=True,
    notify_on_complete=True,
    watch_patterns=["FAIL", "ERROR"]
)
# Returns immediately with session_id

# Agent continues working on other files
patch("src/utils/validator.ts", old_string="...", new_string="...")
write_file("src/utils/formatter.ts", content="...")

# Mid-work check (optional)
status = process(action="poll", session_id=test_session)
if status["new_lines"]:
    # Glance at progress
    pass

# Eventually, notification arrives:
# "Process test_session exited with code 1"

# Agent reads the failure
result = process(action="log", session_id=test_session, limit=50)
# Last 50 lines show which tests failed
```

## Parallel Execution Pattern

Run multiple independent tasks simultaneously:

```python
# Start 3 parallel tasks
sessions = {
    "lint": terminal("npm run lint", background=True, notify_on_complete=True),
    "test": terminal("npm test", background=True, notify_on_complete=True),
    "build": terminal("npm run build", background=True, notify_on_complete=True),
}

# Wait for all to complete
results = {}
for name, sid in sessions.items():
    results[name] = process(action="wait", session_id=sid, timeout=300)

# Check results
for name, result in results.items():
    if result["exit_code"] != 0:
        print(f"{name} failed!")
        failure_log = process(action="log", session_id=sessions[name], limit=30)
```

## Rules for Agents

1. **Background anything over 10 seconds.** Builds, test suites, installs, deployments.
2. **Always set `notify_on_complete=True`.** Don't rely on polling loops.
3. **Use watch patterns for errors.** Catch `FAIL`, `ERROR`, `Traceback` early.
4. **Don't use shell backgrounding.** No `&`, `nohup`, or `disown`. Use the process manager.
5. **Kill stuck processes.** If a process runs 3x longer than expected, kill it.
6. **Read logs on failure, not success.** If exit_code=0, you rarely need the full log.
7. **Parallelize independent work.** Lint + test + build can run simultaneously.
