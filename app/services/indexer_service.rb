class IndexerService
  def self.fetch_games(last_id: 0, limit: 50)
    begin
      api_url = "#{BlockchainConfig.indexer_url}/api/games?lastId=#{last_id}&limit=#{limit}"
      
      puts "Fetching games from: #{api_url}"
      
      response = HTTParty.get(api_url, {
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        },
        timeout: 30
      })
      
      if response.success?
        games = JSON.parse(response.body)
        puts "API returned #{games.length} games"
        games
      else
        Rails.logger.error "Failed to fetch games: #{response.code} - #{response.message}"
        puts "API Error: #{response.code} - #{response.message}"
        []
      end
    rescue => e
      Rails.logger.error "Error fetching games: #{e.message}"
      puts "Error fetching games: #{e.message}"
      []
    end
  end

  def self.fetch_randomness_posts(last_id: 0, limit: 50)
    begin
      api_url = "#{BlockchainConfig.indexer_url}/api/randomness-posts?lastId=#{last_id}&limit=#{limit}"
      
      puts "Fetching randomness posts from: #{api_url}"
      
      response = HTTParty.get(api_url, {
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        },
        timeout: 30
      })
      
      if response.success?
        posts = JSON.parse(response.body)
        puts "API returned #{posts.length} randomness posts"
        posts
      else
        Rails.logger.error "Failed to fetch randomness posts: #{response.code} - #{response.message}"
        puts "API Error: #{response.code} - #{response.message}"
        []
      end
    rescue => e
      Rails.logger.error "Error fetching randomness posts: #{e.message}"
      puts "Error fetching randomness posts: #{e.message}"
      []
    end
  end

  def self.fetch_reveals(last_id: 0, limit: 50)
    begin
      api_url = "#{BlockchainConfig.indexer_url}/api/reveals?lastId=#{last_id}&limit=#{limit}"
      
      puts "Fetching reveals from: #{api_url}"
      
      response = HTTParty.get(api_url, {
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        },
        timeout: 30
      })
      
      if response.success?
        reveals = JSON.parse(response.body)
        puts "API returned #{reveals.length} reveals"
        reveals
      else
        Rails.logger.error "Failed to fetch reveals: #{response.code} - #{response.message}"
        puts "API Error: #{response.code} - #{response.message}"
        []
      end
    rescue => e
      Rails.logger.error "Error fetching reveals: #{e.message}"
      puts "Error fetching reveals: #{e.message}"
      []
    end
  end
end

