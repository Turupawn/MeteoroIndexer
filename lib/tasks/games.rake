namespace :games do
  desc "Sync games from Ponder indexer (VRF-based)"
  task sync: :environment do
    puts "Starting VRF games sync at #{Time.current}"

    begin
      # Get highest game ID we have
      highest_game_id = Game.maximum(:game_id) || 0
      puts "Highest game ID in DB: #{highest_game_id}"

      # Fetch new game requests from Ponder
      limit = BlockchainConfig.max_games_to_process
      new_games = IndexerService.fetch_games(last_id: highest_game_id, limit: limit)

      if new_games.empty?
        puts "No new games found"
      else
        puts "Found #{new_games.length} new game requests"

        # Create pending games from requests
        new_games.each do |game_data|
          create_or_update_game_from_request(game_data)
        end
      end

      # Update pending games with completion data
      sync_pending_games

      # Record sync statistics
      new_games_count = new_games.length
      TelegramNotificationService.record_sync_and_notify_if_needed(new_games_count)

    rescue => e
      puts "Error in VRF games sync: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      Rails.logger.error "VRF games sync failed: #{e.message}"
      TelegramNotificationService.send_sync_error_notification(e.message)
    end
  end

  private

  def create_or_update_game_from_request(request_data)
    game_id = request_data["id"].to_i
    existing_game = Game.find_by(game_id: game_id)

    if existing_game
      puts "Game #{game_id} already exists, skipping"
      return existing_game
    end

    game = Game.from_ponder_request(request_data)
    if game.save
      puts "Created pending game ID #{game_id}"
      game
    else
      puts "Failed to save game #{game_id}: #{game.errors.full_messages.join(', ')}"
      nil
    end
  end

  def sync_pending_games
    pending_games = Game.where(game_state: :pending).order(:game_id)

    if pending_games.empty?
      puts "No pending games to check"
      return
    end

    puts "Checking #{pending_games.count} pending games for completion"

    # Get the lowest pending game ID to use as last_id
    lowest_pending_id = pending_games.minimum(:game_id) - 1

    # Fetch completions from Ponder
    completions = IndexerService.fetch_completions(last_id: lowest_pending_id, limit: 100)

    # Index completions by game ID for fast lookup
    completions_by_id = completions.index_by { |c| c["id"].to_i }

    pending_games.each do |game|
      completion_data = completions_by_id[game.game_id]
      next unless completion_data

      game.apply_completion(completion_data)
      if game.save
        puts "Completed game ID #{game.game_id} (result: #{game.result})"
      else
        puts "Failed to update game #{game.game_id}: #{game.errors.full_messages.join(', ')}"
      end
    end
  end
end
