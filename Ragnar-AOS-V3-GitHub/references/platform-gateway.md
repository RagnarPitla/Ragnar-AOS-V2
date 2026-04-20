# Platform Gateway — Multi-Platform Agent Architecture

> One agent core, many platform adapters. Same logic serves CLI, Telegram, Discord, Slack, and more.

## Core Pattern

```
                    ┌─────────────────┐
  CLI ──────────────┤                 │
  Telegram ─────────┤  Platform       │      ┌──────────────┐
  Discord ──────────┤  Gateway        ├─────►│  Agent Core   │
  Slack ────────────┤  (normalize +   │      │  (unchanged)  │
  WhatsApp ─────────┤   route)        │      └──────────────┘
  Teams ────────────┤                 │
                    └─────────────────┘
```

The agent core never knows which platform a message came from. The gateway normalizes everything into a unified `Message` object.

## Unified Message Object

```python
@dataclass
class Message:
    id: str                          # unique message ID
    session_id: str                  # platform:chat_id:thread_id
    platform: str                    # "cli", "telegram", "discord", etc.
    sender: str                      # username or user ID
    text: str                        # normalized text content
    media: list[MediaAttachment]     # images, files, voice
    reply_to: str | None             # parent message ID
    timestamp: datetime
    raw: dict                        # original platform payload

@dataclass
class MediaAttachment:
    type: str        # "image", "file", "voice", "video"
    url: str         # download URL or local path
    filename: str
    mime_type: str
    size_bytes: int
```

## Adapter Interface

Every platform adapter implements this interface:

```python
class PlatformAdapter(Protocol):
    platform_name: str
    
    async def start(self) -> None:
        """Start listening for messages."""
    
    async def stop(self) -> None:
        """Gracefully disconnect."""
    
    async def send(self, session_id: str, response: AgentResponse) -> None:
        """Send agent response back to the platform."""
    
    async def on_message(self, callback: Callable[[Message], Awaitable]) -> None:
        """Register handler for incoming messages."""
    
    def format_response(self, response: AgentResponse) -> Any:
        """Convert agent response to platform-native format."""
```

## Session Routing

Sessions are addressed as `platform:chat_id:thread_id`:

```
cli:local:default              # CLI session
telegram:123456789:0           # Telegram DM
telegram:-100987654:42         # Telegram group, thread 42
discord:guild123:channel456    # Discord channel
slack:T01ABC:C02DEF:ts123      # Slack thread
whatsapp:+1234567890:0         # WhatsApp chat
teams:tenant:channel:thread    # Teams thread
```

```python
def parse_session(session_id: str) -> tuple[str, str, str]:
    parts = session_id.split(":", 2)
    platform = parts[0]
    chat_id = parts[1] if len(parts) > 1 else "default"
    thread_id = parts[2] if len(parts) > 2 else "0"
    return platform, chat_id, thread_id

def route_response(session_id: str, response: AgentResponse):
    platform, _, _ = parse_session(session_id)
    adapter = adapters[platform]
    adapter.send(session_id, response)
```

## Platform Adapters

### CLI Adapter

```python
class CLIAdapter:
    platform_name = "cli"
    
    async def start(self):
        # Read from stdin in a loop
        while True:
            line = await asyncio.get_event_loop().run_in_executor(None, input, "> ")
            msg = Message(
                id=str(uuid4()),
                session_id="cli:local:default",
                platform="cli",
                sender="user",
                text=line,
                media=[], reply_to=None,
                timestamp=datetime.now(), raw={}
            )
            await self._callback(msg)
    
    async def send(self, session_id, response):
        print(response.text)
        for media in response.media:
            print(f"[{media.type}: {media.filename}]")
```

### Telegram Adapter

```python
class TelegramAdapter:
    platform_name = "telegram"
    
    def __init__(self, token: str):
        self.bot = TelegramBot(token)
    
    async def start(self):
        @self.bot.on_message()
        async def handle(update):
            msg = Message(
                id=str(update.message_id),
                session_id=f"telegram:{update.chat.id}:{update.message_thread_id or 0}",
                platform="telegram",
                sender=update.from_user.username,
                text=update.text or "",
                media=self._extract_media(update),
                reply_to=str(update.reply_to_message.message_id) if update.reply_to_message else None,
                timestamp=update.date,
                raw=update.to_dict()
            )
            await self._callback(msg)
        await self.bot.start_polling()
    
    async def send(self, session_id, response):
        _, chat_id, thread_id = parse_session(session_id)
        await self.bot.send_message(
            chat_id=int(chat_id),
            text=response.text,
            message_thread_id=int(thread_id) if thread_id != "0" else None
        )
```

## Message Format Normalization

Each platform has quirks. The gateway normalizes them:

| Platform  | Mentions        | Normalized to        |
|-----------|-----------------|----------------------|
| Telegram  | `@botname cmd`  | strip bot mention    |
| Discord   | `<@123> cmd`    | strip mention markup |
| Slack     | `<@U01> cmd`    | strip mention markup |
| CLI       | plain text      | as-is                |

```python
def normalize_text(platform: str, raw_text: str, bot_id: str) -> str:
    if platform == "telegram":
        return raw_text.replace(f"@{bot_id}", "").strip()
    if platform == "discord":
        return re.sub(r"<@!?\d+>\s*", "", raw_text).strip()
    if platform == "slack":
        return re.sub(r"<@\w+>\s*", "", raw_text).strip()
    return raw_text.strip()
```

## Media Handling

### Receiving Media

```python
async def download_media(attachment: MediaAttachment) -> Path:
    """Download media to local temp file."""
    local = TEMP_DIR / attachment.filename
    async with aiohttp.ClientSession() as session:
        async with session.get(attachment.url) as resp:
            local.write_bytes(await resp.read())
    return local
```

### Sending Media

```python
class AgentResponse:
    text: str
    media: list[MediaAttachment]
    
# Platform-specific rendering:
# - CLI: print file path
# - Telegram: send_photo / send_document
# - Discord: attach file to message
# - Slack: upload to channel
```

### Voice Messages

```python
async def handle_voice(attachment: MediaAttachment) -> str:
    """Convert voice to text for agent processing."""
    local = await download_media(attachment)
    transcript = await speech_to_text(local)
    return transcript  # Agent sees text, not audio
```

## Example: Same Agent, Two Platforms

```python
async def main():
    agent = AgentCore(config)
    gateway = PlatformGateway(agent)
    
    # Register adapters
    gateway.register(CLIAdapter())
    gateway.register(TelegramAdapter(token=os.environ["TG_TOKEN"]))
    
    # Both adapters route to the same agent
    # CLI user types: "check server status"
    # Telegram user sends: "check server status"
    # Same agent handles both, responds via correct platform
    
    await gateway.start_all()
```

## Platform-Specific Response Formatting

```python
def format_for_platform(platform: str, response: AgentResponse) -> Any:
    if platform == "cli":
        return response.text  # plain text, maybe with ANSI colors
    if platform == "telegram":
        return {"text": response.text, "parse_mode": "Markdown"}
    if platform == "discord":
        return {"content": response.text[:2000]}  # Discord char limit
    if platform == "slack":
        return {"blocks": [{"type": "section", "text": {"type": "mrkdwn", "text": response.text}}]}
```

## Configuration

```yaml
# platform-gateway.yaml
platforms:
  cli:
    enabled: true
  telegram:
    enabled: true
    token_env: TELEGRAM_BOT_TOKEN
  discord:
    enabled: false
    token_env: DISCORD_BOT_TOKEN
  slack:
    enabled: false
    token_env: SLACK_BOT_TOKEN
    signing_secret_env: SLACK_SIGNING_SECRET
```
