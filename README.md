## Run Locally

```bash
CONTRACT_ADDRESS=0x1234567890abcdef1234567890abcdef12345678 rails s
```

# Rake tasks

```bash
# Manual execution
rails games:sync

# Start the job queue (for recurring jobs)
rails solid_queue:start
```


## Reset DB

```bash
rails db:drop
rails db:migrate
rails games:fetch_new
```

## Environment Variables

```bash
# Web3 Configuration
RPC_URL=https://megaeth-testnet.blockscout.com/api/v2/rpc
CONTRACT_ADDRESS=0x1234567890abcdef1234567890abcdef12345678
CONTRACT_ABI_NAME=two_party_war_game
BLOCK_EXPLORER_URL=https://megaeth-testnet.blockscout.com

# Telegram Bot Configuration (optional)
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here
TELEGRAM_MESSAGE_INTERVAL=300
POLL_UPDATE_INTERVAL=60

# Rails Configuration
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_base_here
```