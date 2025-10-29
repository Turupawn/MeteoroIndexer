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
    
    # Calculate which page to fetch based on sequential_id
    # Each page has #{BlockchainConfig.blockscout_api_limit} transactions, so page = (sequential_id - 1) / #{BlockchainConfig.blockscout_api_limit} + 1
    next_page = ((next_sequential_id - 1) / BlockchainConfig.blockscout_api_limit) + 1
    
    puts "Highest sequential_id in DB: #{highest_sequential_id}"
    puts "Next sequential_id to fetch: #{next_sequential_id}"
    puts "Calculated page to fetch: #{next_page}"
    
    # Get the latest transaction we have in the database
    latest_tx = Transaction.order(:timestamp).last
    
    if latest_tx
      puts "Latest transaction in DB: #{latest_tx.transaction_hash} at #{latest_tx.timestamp} (sequential_id: #{latest_tx.sequential_id})"
    end
    
    # Fetch transactions starting from the calculated page
    transactions_data = fetch_transactions_from_page(contract_address, next_page)
    
    # Add sequential_id to each transaction based on page position
    if transactions_data && !transactions_data.empty?
      transactions_data.each_with_index do |tx_data, index|
        # Calculate sequential_id: (page - 1) * #{BlockchainConfig.blockscout_api_limit} + index + 1
        tx_data[:sequential_id] = (next_page - 1) * BlockchainConfig.blockscout_api_limit + index + 1
      end
      puts "Added sequential_ids to #{transactions_data.length} transactions"
    end
    
    transactions_data
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
