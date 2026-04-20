# Terminal Backends — Abstract Execution Across Environments

> Same agent, same commands — different execution environments. Local, Docker, SSH, or cloud.

## Core Pattern

The agent calls `execute(command, timeout, workdir)` and gets back `{output, exit_code}`. It never knows (or cares) whether the command ran locally, in a container, on a remote server, or in a serverless function.

```
Agent
  │
  ▼
TerminalBackend (interface)
  ├── LocalBackend      → subprocess on host machine
  ├── DockerBackend     → docker exec in container
  ├── SSHBackend        → ssh remote execution
  └── CloudBackend      → Modal/Lambda/serverless
```

## Interface

```python
from dataclasses import dataclass
from typing import Protocol

@dataclass
class ExecResult:
    output: str
    exit_code: int
    duration_ms: int

class TerminalBackend(Protocol):
    name: str
    
    async def execute(
        self,
        command: str,
        timeout: int = 180,
        workdir: str | None = None
    ) -> ExecResult:
        """Execute a command and return output + exit code."""
        ...
    
    async def write_file(self, path: str, content: str) -> None:
        """Write a file in the execution environment."""
        ...
    
    async def read_file(self, path: str) -> str:
        """Read a file from the execution environment."""
        ...
    
    async def is_healthy(self) -> bool:
        """Check if the backend is available."""
        ...
```

## Backend: Local

Direct subprocess execution on the host machine.

```python
class LocalBackend:
    name = "local"
    
    async def execute(self, command, timeout=180, workdir=None):
        start = time.monotonic()
        proc = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
            cwd=workdir
        )
        try:
            stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        except asyncio.TimeoutError:
            proc.kill()
            return ExecResult(output="Command timed out", exit_code=-1,
                            duration_ms=int((time.monotonic()-start)*1000))
        
        return ExecResult(
            output=stdout.decode(errors="replace"),
            exit_code=proc.returncode,
            duration_ms=int((time.monotonic() - start) * 1000)
        )
    
    async def is_healthy(self):
        return True  # always available
```

## Backend: Docker

Execute commands inside a running container. Ideal for untrusted code.

```python
class DockerBackend:
    name = "docker"
    
    def __init__(self, image="python:3.12-slim", container_name=None):
        self.image = image
        self.container_name = container_name or f"raos-sandbox-{uuid4().hex[:8]}"
        self._started = False
    
    async def ensure_container(self):
        if not self._started:
            await self.execute_host(
                f"docker run -d --name {self.container_name} "
                f"-v {self.workspace}:/workspace -w /workspace "
                f"{self.image} sleep infinity"
            )
            self._started = True
    
    async def execute(self, command, timeout=180, workdir=None):
        await self.ensure_container()
        wd = workdir or "/workspace"
        start = time.monotonic()
        result = await self.execute_host(
            f"docker exec -w {wd} {self.container_name} sh -c {shlex.quote(command)}",
            timeout=timeout
        )
        result.duration_ms = int((time.monotonic() - start) * 1000)
        return result
    
    async def cleanup(self):
        await self.execute_host(f"docker rm -f {self.container_name}")
```

## Backend: SSH

Remote execution over SSH. Good for GPU servers, staging environments.

```python
class SSHBackend:
    name = "ssh"
    
    def __init__(self, host, user="root", key_file=None, port=22):
        self.host = host
        self.user = user
        self.key_file = key_file
        self.port = port
    
    async def execute(self, command, timeout=180, workdir=None):
        cd = f"cd {workdir} && " if workdir else ""
        ssh_cmd = (
            f"ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "
            f"-p {self.port} "
            f"{f'-i {self.key_file} ' if self.key_file else ''}"
            f"{self.user}@{self.host} "
            f"{shlex.quote(cd + command)}"
        )
        start = time.monotonic()
        proc = await asyncio.create_subprocess_shell(
            ssh_cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT
        )
        stdout, _ = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        return ExecResult(
            output=stdout.decode(errors="replace"),
            exit_code=proc.returncode,
            duration_ms=int((time.monotonic() - start) * 1000)
        )
    
    async def is_healthy(self):
        result = await self.execute("echo ok", timeout=10)
        return result.exit_code == 0
```

## Backend: Cloud (Modal/Serverless)

Execute in serverless containers. Pay-per-use, auto-scaling.

```python
class ModalBackend:
    name = "cloud"
    
    def __init__(self, app_name="raos-sandbox", gpu=None):
        self.app_name = app_name
        self.gpu = gpu  # e.g. "T4", "A100"
    
    async def execute(self, command, timeout=180, workdir=None):
        import modal
        stub = modal.Stub(self.app_name)
        
        @stub.function(gpu=self.gpu, timeout=timeout)
        def run_command(cmd: str, wd: str) -> tuple[str, int]:
            import subprocess
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=wd)
            return result.stdout + result.stderr, result.returncode
        
        start = time.monotonic()
        output, code = await run_command.remote(command, workdir or "/tmp")
        return ExecResult(
            output=output, exit_code=code,
            duration_ms=int((time.monotonic() - start) * 1000)
        )
```

## Backend Selection

Configured per-project in the RAOS config:

```yaml
# .claude/config.yaml
terminal:
  default_backend: local
  backends:
    local:
      type: local
    docker:
      type: docker
      image: node:20-slim
      workspace: /tmp/raos-sandbox
    gpu:
      type: ssh
      host: gpu-server.internal
      user: ubuntu
      key_file: ~/.ssh/gpu_key
    cloud:
      type: modal
      gpu: T4
  
  # Route rules: pattern -> backend
  routing:
    - pattern: "npm|node|webpack"
      backend: docker
    - pattern: "python.*train|torch|cuda"
      backend: gpu
    - pattern: "*"
      backend: local
```

```python
def select_backend(command: str, config: dict) -> TerminalBackend:
    for rule in config.get("routing", []):
        if re.search(rule["pattern"], command):
            return backends[rule["backend"]]
    return backends[config.get("default_backend", "local")]
```

## File Sync for Non-Local Backends

When using Docker, SSH, or cloud backends, files need syncing:

```python
class FileSyncer:
    async def push(self, local_path: Path, remote_path: str, backend: TerminalBackend):
        """Upload local file to remote environment."""
        if isinstance(backend, DockerBackend):
            await execute_host(f"docker cp {local_path} {backend.container_name}:{remote_path}")
        elif isinstance(backend, SSHBackend):
            await execute_host(f"scp {local_path} {backend.user}@{backend.host}:{remote_path}")
    
    async def pull(self, remote_path: str, local_path: Path, backend: TerminalBackend):
        """Download remote file to local."""
        if isinstance(backend, DockerBackend):
            await execute_host(f"docker cp {backend.container_name}:{remote_path} {local_path}")
        elif isinstance(backend, SSHBackend):
            await execute_host(f"scp {backend.user}@{backend.host}:{remote_path} {local_path}")
```

## Isolation Benefits

| Concern             | Local | Docker | SSH   | Cloud  |
|---------------------|-------|--------|-------|--------|
| Untrusted code      | ❌    | ✅     | ✅    | ✅     |
| GPU access          | Maybe | ❌     | ✅    | ✅     |
| Network isolation   | ❌    | ✅     | ✅    | ✅     |
| No local deps       | ❌    | ✅     | ✅    | ✅     |
| Zero setup          | ✅    | ❌     | ❌    | ❌     |
| Speed               | ⚡    | Fast   | Slow  | Variable|

## Example: Agent Runs Locally, Executes in Docker

```python
# Agent config
backend = DockerBackend(image="python:3.12-slim")

# Agent thinks it's running normally:
result = await backend.execute("python -c 'print(1+1)'")
# output: "2", exit_code: 0
# But it actually ran inside a container

result = await backend.execute("rm -rf /")
# Destroys container filesystem, not host
# Container can be recreated instantly
```
