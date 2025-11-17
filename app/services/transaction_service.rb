class TransactionService
  def self.fetch_transactions_from_page(contract_address, page)
    begin
      # Construct the API URL for H testnet using old API format
      api_url = "#{BlockchainConfig.block_explorer_url}/api?module=account&action=txlist&address=#{contract_address}&sort=asc&filterby=to&page=#{page}&offset=#{BlockchainConfig.blockscout_api_limit}"
      
      puts "Fetching page #{page} from: #{api_url}"
      
      # Make the HTTP request
      response = HTTParty.get(api_url, {
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        },
        timeout: 30
      })
      
      if response.success?
        data = JSON.parse(response.body)
        
        # Check if API call was successful
        if data['status'] == '1' && data['result']
          transactions = data['result'] || []
          
          puts "API returned #{transactions.length} transactions on page #{page}"
          
          # Process and format the transactions for old API format
          page_transactions = transactions.map do |tx|
            # Extract method from input data using database lookup
            method = 'unknown'
            if tx['input'] && tx['input'].length > 10
              # Try to extract method signature from input
              method_signature = tx['input'][0, 10]
              
              # Look up method name from database
              function_signature = AbiSignatureService.find_method_by_signature(method_signature)
              if function_signature
                method = function_signature.name
              end
            end
            
            {
              hash: tx['hash'],
              method: method,
              from: tx['from'].present? ? tx['from'] : '0x0000000000000000000000000000000000000000',
              to: tx['to'].present? ? tx['to'] : '0x0000000000000000000000000000000000000000',
              value: tx['value'] || '0',
              fee: (tx['gasUsed'].to_i * tx['gasPrice'].to_i).to_s,
              gas_used: tx['gasUsed'] || '0',
              gas_price: tx['gasPrice'] || '0',
              status: tx['isError'] == '0' ? 'success' : 'failed',
              timestamp: Time.at(tx['timeStamp'].to_i).iso8601,
              block_number: tx['blockNumber'] || '0',
              confirmations: tx['confirmations'] || '0',
              raw_input: tx['input'] || '',
              decoded_input: nil # Old API doesn't provide decoded input
            }
          end
          
          page_transactions
        else
          puts "API returned error: #{data['message'] || 'Unknown error'}"
          []
        end
      else
        Rails.logger.error "Failed to fetch transactions: #{response.code} - #{response.message}"
        puts "API Error: #{response.code} - #{response.message}"
        []
      end
    rescue => e
      Rails.logger.error "Error fetching transactions from page #{page}: #{e.message}"
      []
    end
  end

  def self.fetch_incremental_transactions(contract_address = nil)
    contract_address ||= BlockchainConfig.contract_address
    
    return [] unless contract_address.present? && contract_address != "0x1234567890123456789012345678901234567890"
    
    # Get the highest sequential_id we have in the database
    highest_sequential_id = Transaction.maximum(:sequential_id) || 0
    next_sequential_id = highest_sequential_id + 1
    
    puts "Highest sequential_id in DB: #{highest_sequential_id}"
    puts "Next sequential_id to fetch: #{next_sequential_id}"
    
    # Get the latest transaction we have in the database
    latest_tx = Transaction.order(:timestamp).last
    
    if latest_tx
      puts "Latest transaction in DB: #{latest_tx.transaction_hash} at #{latest_tx.timestamp} (sequential_id: #{latest_tx.sequential_id})"
    end
    
    # Fetch from indexer API - fetch 50 games, 50 randomness posts, and 50 reveals
    limit = 50
    all_transactions = []
    
    # Fetch games (these represent commit transactions)
    # Get the highest game ID we've processed by checking existing commit transactions
    # Extract game ID from hash like "game_5" -> 5
    highest_game_id = Transaction.where(method: 'commit')
                                 .pluck(:transaction_hash)
                                 .map { |h| h.match(/game_(\d+)/)&.[](1)&.to_i }
                                 .compact
                                 .max || 0
    games = IndexerService.fetch_games(last_id: highest_game_id, limit: limit)
    
    games.each do |game|
      # Create a transaction record for each game (commit)
      all_transactions << {
        hash: "game_#{game['id']}", # Use a synthetic hash since indexer doesn't provide tx hash
        method: 'commit',
        from: game['player'],
        to: contract_address,
        value: game['betAmount'],
        fee: (game['gasUsed'].to_i * 1_000_000_000).to_s, # Estimate gas price (1 gwei)
        gas_used: game['gasUsed'],
        gas_price: '1000000000', # 1 gwei estimate
        status: 'success',
        timestamp: Time.current.iso8601, # Indexer doesn't provide timestamp for games
        block_number: '0',
        confirmations: '0',
        raw_input: '',
        decoded_input: nil,
        game_id: game['id'].to_i
      }
    end
    
    # Fetch randomness posts (these represent multiPostRandomness transactions)
    # Extract randomness ID from hash like "randomness_5" -> 5
    highest_randomness_id = Transaction.where(method: 'multiPostRandomness')
                                      .pluck(:transaction_hash)
                                      .map { |h| h.match(/randomness_(\d+)/)&.[](1)&.to_i }
                                      .compact
                                      .max || 0
    randomness_posts = IndexerService.fetch_randomness_posts(last_id: highest_randomness_id, limit: limit)
    
    randomness_posts.each do |post|
      all_transactions << {
        hash: "randomness_#{post['id']}",
        method: 'multiPostRandomness',
        from: contract_address, # House posts randomness
        to: contract_address,
        value: '0',
        fee: (post['gasUsed'].to_i * 1_000_000_000).to_s,
        gas_used: post['gasUsed'],
        gas_price: '1000000000',
        status: 'success',
        timestamp: Time.at(post['timestamp'].to_i).iso8601,
        block_number: '0',
        confirmations: '0',
        raw_input: '',
        decoded_input: nil,
        randomness_id: post['id'].to_i
      }
    end
    
    # Fetch reveals
    # Extract reveal ID from hash like "reveal_5" -> 5
    highest_reveal_id = Transaction.where(method: 'reveal')
                                   .pluck(:transaction_hash)
                                   .map { |h| h.match(/reveal_(\d+)/)&.[](1)&.to_i }
                                   .compact
                                   .max || 0
    reveals = IndexerService.fetch_reveals(last_id: highest_reveal_id, limit: limit)
    
    reveals.each do |reveal|
      all_transactions << {
        hash: "reveal_#{reveal['id']}",
        method: 'reveal',
        from: reveal['player'],
        to: contract_address,
        value: '0',
        fee: (reveal['gasUsed'].to_i * 1_000_000_000).to_s,
        gas_used: reveal['gasUsed'],
        gas_price: '1000000000',
        status: 'success',
        timestamp: Time.current.iso8601, # Indexer doesn't provide timestamp for reveals
        block_number: '0',
        confirmations: '0',
        raw_input: '',
        decoded_input: nil,
        reveal_id: reveal['id'].to_i
      }
    end
    
    # Sort by ID and assign sequential_ids
    all_transactions.sort_by! { |tx| [tx[:game_id] || tx[:randomness_id] || tx[:reveal_id] || 0, tx[:method]] }
    
    # Assign sequential_ids starting from next_sequential_id
    all_transactions.each_with_index do |tx_data, index|
      tx_data[:sequential_id] = next_sequential_id + index
    end
    
    puts "Fetched #{all_transactions.length} transactions from indexer (games: #{games.length}, randomness: #{randomness_posts.length}, reveals: #{reveals.length})"
    all_transactions
  end
  
  def self.format_eth_value(wei_value)
    return "0 ETH" if wei_value.nil? || wei_value == "0"
    
    # Convert wei to ETH (1 ETH = 10^18 wei)
    eth_value = wei_value.to_f / 10**18
    "#{eth_value.round(6)} ETH"
  end
  
  def self.format_eth_value_detailed(wei_value)
    return "0 ETH" if wei_value.nil? || wei_value == "0"
    
    # Convert wei to ETH (1 ETH = 10^18 wei)
    eth_value = wei_value.to_f / 10**18
    # Format with 18 decimals and remove trailing zeros
    formatted = sprintf("%.18f", eth_value).gsub(/\.?0+$/, '')
    "#{formatted} ETH"
  end
end
