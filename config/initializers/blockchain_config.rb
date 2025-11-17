# Load blockchain configuration from YAML file
blockchain_config = Rails.application.config_for(:blockchain)

# Override with environment variables if they exist
blockchain_config['rpc_url'] = ENV['RPC_URL'] if ENV['RPC_URL']
blockchain_config['contract_address'] = ENV['CONTRACT_ADDRESS'] if ENV['CONTRACT_ADDRESS']
blockchain_config['contract_abi_name'] = ENV['CONTRACT_ABI_NAME'] if ENV['CONTRACT_ABI_NAME']
blockchain_config['block_explorer_url'] = ENV['BLOCK_EXPLORER_URL'] if ENV['BLOCK_EXPLORER_URL']
blockchain_config['indexer_url'] = ENV['INDEXER_URL'] if ENV['INDEXER_URL']
blockchain_config['sync_schedule_ms'] = ENV['BLOCKCHAIN_SYNC_SCHEDULE_MS'].to_i if ENV['BLOCKCHAIN_SYNC_SCHEDULE_MS']
blockchain_config['max_games_to_process'] = ENV['BLOCKCHAIN_MAX_GAMES_TO_PROCESS'].to_i if ENV['BLOCKCHAIN_MAX_GAMES_TO_PROCESS']
blockchain_config['blockscout_api_limit'] = ENV['BLOCKSCOUT_API_LIMIT'].to_i if ENV['BLOCKSCOUT_API_LIMIT']
blockchain_config['poll_update_interval'] = ENV['POLL_UPDATE_INTERVAL'].to_i if ENV['POLL_UPDATE_INTERVAL']
blockchain_config['telegram_message_interval'] = ENV['TELEGRAM_MESSAGE_INTERVAL'].to_i if ENV['TELEGRAM_MESSAGE_INTERVAL']

# Make configuration available throughout the application
Rails.application.config.blockchain = blockchain_config

# Create a convenient accessor method
module BlockchainConfig
  def self.rpc_url
    Rails.application.config.blockchain['rpc_url']
  end

  def self.contract_address
    Rails.application.config.blockchain['contract_address']
  end

  def self.contract_abi_name
    Rails.application.config.blockchain['contract_abi_name']
  end

  def self.sync_schedule_ms
    Rails.application.config.blockchain['sync_schedule_ms']
  end

  def self.max_games_to_process
    Rails.application.config.blockchain['max_games_to_process']
  end

  def self.blockscout_api_limit
    Rails.application.config.blockchain['blockscout_api_limit']
  end

  def self.new_games_batch_size
    max_games_to_process
  end

  def self.pending_house_batch_size
    max_games_to_process
  end

  def self.pending_player_batch_size
    max_games_to_process
  end

  def self.max_pending_house_games
    max_games_to_process
  end

  def self.max_pending_player_games
    max_games_to_process
  end

  def self.block_explorer_url
    Rails.application.config.blockchain['block_explorer_url']
  end

  def self.indexer_url
    Rails.application.config.blockchain['indexer_url'] || 'http://localhost:42069'
  end

  def self.poll_update_interval
    Rails.application.config.blockchain['poll_update_interval']
  end

  def self.telegram_message_interval
    Rails.application.config.blockchain['telegram_message_interval']
  end
end
