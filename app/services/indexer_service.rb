class IndexerService
  # Fetch game requests (VRF: when player calls rollDice)
  def self.fetch_games(last_id: 0, limit: 50)
    fetch_endpoint("games", last_id, limit)
  end

  # Fetch game completions (VRF: when VRF callback completes the game)
  def self.fetch_completions(last_id: 0, limit: 50)
    fetch_endpoint("completions", last_id, limit)
  end

  # Fetch game ties (VRF: when game results in a tie)
  def self.fetch_ties(last_id: 0, limit: 50)
    fetch_endpoint("ties", last_id, limit)
  end

  private

  def self.fetch_endpoint(endpoint, last_id, limit)
    api_url = "#{BlockchainConfig.indexer_url}/api/#{endpoint}?lastId=#{last_id}&limit=#{limit}"

    puts "Fetching #{endpoint} from: #{api_url}"

    response = HTTParty.get(api_url, {
      headers: {
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      },
      timeout: 30
    })

    if response.success?
      data = JSON.parse(response.body)
      puts "API returned #{data.length} #{endpoint}"
      data
    else
      Rails.logger.error "Failed to fetch #{endpoint}: #{response.code} - #{response.message}"
      puts "API Error: #{response.code} - #{response.message}"
      []
    end
  rescue => e
    Rails.logger.error "Error fetching #{endpoint}: #{e.message}"
    puts "Error fetching #{endpoint}: #{e.message}"
    []
  end
end

