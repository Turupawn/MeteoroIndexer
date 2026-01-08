class TransactionService
  # Fetch transactions from Ponder API (VRF-based: rollDice + completions)
  def self.fetch_incremental_transactions(contract_address = nil)
    contract_address ||= BlockchainConfig.contract_address

    return [] unless contract_address.present? && contract_address != "0x1234567890123456789012345678901234567890"

    highest_sequential_id = Transaction.maximum(:sequential_id) || 0
    next_sequential_id = highest_sequential_id + 1

    puts "Highest sequential_id in DB: #{highest_sequential_id}"

    limit = 50
    all_transactions = []

    # Fetch game requests (rollDice transactions)
    highest_game_id = Transaction.where(method: "rollDice")
                                 .pluck(:transaction_hash)
                                 .map { |h| h.match(/game_(\d+)/)&.[](1)&.to_i }
                                 .compact
                                 .max || 0

    games = IndexerService.fetch_games(last_id: highest_game_id, limit: limit)

    games.each do |game|
      all_transactions << {
        hash: "game_#{game['id']}",
        method: "rollDice",
        from: game["player"],
        to: contract_address,
        value: game["betAmount"],
        fee: (game["gasUsed"].to_i * 1_000_000_000).to_s,
        gas_used: game["gasUsed"],
        gas_price: "1000000000",
        status: "success",
        timestamp: Time.at(game["requestTimestamp"].to_i).iso8601,
        block_number: "0",
        confirmations: "0",
        raw_input: "",
        decoded_input: nil,
        game_id: game["id"].to_i
      }
    end

    # Fetch game completions (VRF callback transactions)
    highest_completion_id = Transaction.where(method: "vrfCallback")
                                       .pluck(:transaction_hash)
                                       .map { |h| h.match(/completion_(\d+)/)&.[](1)&.to_i }
                                       .compact
                                       .max || 0

    completions = IndexerService.fetch_completions(last_id: highest_completion_id, limit: limit)

    completions.each do |completion|
      all_transactions << {
        hash: "completion_#{completion['id']}",
        method: "vrfCallback",
        from: contract_address, # VRF coordinator calls the contract
        to: contract_address,
        value: "0",
        fee: (completion["gasUsed"].to_i * 1_000_000_000).to_s,
        gas_used: completion["gasUsed"],
        gas_price: "1000000000",
        status: "success",
        timestamp: Time.at(completion["completedTimestamp"].to_i).iso8601,
        block_number: "0",
        confirmations: "0",
        raw_input: "",
        decoded_input: nil,
        completion_id: completion["id"].to_i
      }
    end

    # Sort by game ID and assign sequential_ids
    all_transactions.sort_by! { |tx| [ tx[:game_id] || tx[:completion_id] || 0, tx[:method] ] }

    all_transactions.each_with_index do |tx_data, index|
      tx_data[:sequential_id] = next_sequential_id + index
    end

    puts "Fetched #{all_transactions.length} transactions from indexer (games: #{games.length}, completions: #{completions.length})"
    all_transactions
  end

  def self.format_eth_value(wei_value)
    return "0 ETH" if wei_value.nil? || wei_value == "0"

    eth_value = wei_value.to_f / 10**18
    "#{eth_value.round(6)} ETH"
  end

  def self.format_eth_value_detailed(wei_value)
    return "0 ETH" if wei_value.nil? || wei_value == "0"

    eth_value = wei_value.to_f / 10**18
    formatted = sprintf("%.18f", eth_value).gsub(/\.?0+$/, "")
    "#{formatted} ETH"
  end
end
