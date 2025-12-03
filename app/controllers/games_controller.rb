class GamesController < ApplicationController
  def index
    @games = Game.recent.page(params[:page]).per(20)
    @total_games = Game.count
    @total_transactions = Transaction.count
    @reveal_count = Transaction.reveals.count
    @house_balance = EthBalanceService.get_house_balance
  end

  def show
    @game = Game.find(params[:id])
    @house_balance = EthBalanceService.get_house_balance
  end

  private

  def get_latest_games(client, count = 10)
    begin
      result2 = client.call(@contract, "getGames", 0, count, false)

      # The eth gem is working correctly! It returns an array of hashes
      if result2.is_a?(Array)
        # Convert each hash to array format for consistency with the view
        result2.map do |game_hash|
          [
            game_hash["gameState"],
            game_hash["playerAddress"],
            game_hash["playerCommit"],
            game_hash["commitTimestamp"],
            game_hash["houseRandomness"],
            game_hash["houseRandomnessTimestamp"],
            game_hash["playerSecret"],
            game_hash["playerCard"],
            game_hash["houseCard"],
            game_hash["winner"],
            game_hash["revealTimestamp"]
          ]
        end
      elsif result2.is_a?(Hash)
        # Fallback for single game
        game_array = [
          result2["gameState"],
          result2["playerAddress"],
          result2["playerCommit"],
          result2["commitTimestamp"],
          result2["houseRandomness"],
          result2["houseRandomnessTimestamp"],
          result2["playerSecret"],
          result2["playerCard"],
          result2["houseCard"],
          result2["winner"],
          result2["revealTimestamp"]
        ]
        [game_array]
      else
        []
      end
    rescue => e
      Rails.logger.error "Failed to fetch latest games: #{e.message}"
      []
    end
  end
end
