class PulseController < ApplicationController
  def index
    # Transaction costs (from Transactions table)
    @house_average_cost = Transaction.house_average_cost || 0
    @player_average_cost = Transaction.player_average_cost || 0
    
    # Wallet statistics (from Games table)
    @unique_wallets = Game.distinct.count(:player_address)
    @total_games = Game.count
    @average_plays_per_wallet = @unique_wallets > 0 ? (@total_games.to_f / @unique_wallets).round(2) : 0
    
    # Chart data for games per day
    @games_per_day_data = games_per_day_chart_data
    
    # Chart data for unique addresses per day
    @unique_addresses_per_day_data = unique_addresses_per_day_chart_data
    
    # Chart data for GACHA token inflation
    @gacha_inflation_data = gacha_inflation_chart_data
  end

  private

  def games_per_day_chart_data
    # Get data for the last 30 days
    start_date = 30.days.ago.beginning_of_day
    end_date = Time.current.end_of_day

    # Group games by day - SQLite returns date as string in 'YYYY-MM-DD' format
    data = Game.where(commit_timestamp: start_date..end_date)
               .group("date(commit_timestamp)")
               .count

    # Create structured data for Chart.js
    dates = (start_date.to_date..end_date.to_date).map(&:to_s)
    
    {
      labels: dates,
      datasets: [
        {
          label: 'Games per Day',
          data: dates.map { |date| data[date] || 0 },
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.1,
          pointRadius: 3,
          pointHoverRadius: 6,
          fill: true
        }
      ]
    }
  end

  def unique_addresses_per_day_chart_data
    # Get data for the last 30 days
    start_date = 30.days.ago.beginning_of_day
    end_date = Time.current.end_of_day

    # Get unique addresses per day using SQL
    # Group by date and count distinct player_address
    dates = (start_date.to_date..end_date.to_date).to_a
    
    unique_counts = dates.map do |date|
      Game.where("date(commit_timestamp) = ?", date.to_s)
          .distinct
          .count(:player_address)
    end
    
    {
      labels: dates.map(&:to_s),
      datasets: [
        {
          label: 'Unique Addresses per Day',
          data: unique_counts,
          borderColor: 'rgb(147, 51, 234)',
          backgroundColor: 'rgba(147, 51, 234, 0.1)',
          tension: 0.1,
          pointRadius: 3,
          pointHoverRadius: 6,
          fill: true
        }
      ]
    }
  end

  def gacha_inflation_chart_data
    # Get current GACHA token supply
    house_balance = EthBalanceService.get_house_balance
    current_supply = house_balance[:gacha_total_supply] || 0
    
    # For historical data, we'll estimate based on games
    # Since we don't have historical snapshots, we'll show cumulative games
    # as a proxy (assuming each game might contribute to token supply)
    # This is an approximation - actual token supply would need historical blockchain data
    
    start_date = 30.days.ago.beginning_of_day
    end_date = Time.current.end_of_day

    # Get cumulative games count per day
    dates = (start_date.to_date..end_date.to_date).to_a
    cumulative_games = []
    total_games_so_far = 0
    
    dates.each do |date|
      games_on_date = Game.where("date(commit_timestamp) <= ?", date.to_s).count
      total_games_so_far = games_on_date
      cumulative_games << total_games_so_far
    end
    
    # Normalize to current supply if we have games
    # This is a rough approximation - showing trend rather than exact supply
    max_games = cumulative_games.max
    normalized_supply = if max_games > 0 && current_supply > 0
      cumulative_games.map { |count| (current_supply * count / max_games.to_f).round(2) }
    else
      Array.new(dates.length, current_supply)
    end
    
    {
      labels: dates.map(&:to_s),
      datasets: [
        {
          label: 'GACHA Token Supply (Estimated)',
          data: normalized_supply,
          borderColor: 'rgb(34, 197, 94)',
          backgroundColor: 'rgba(34, 197, 94, 0.1)',
          tension: 0.1,
          pointRadius: 3,
          pointHoverRadius: 6,
          fill: true
        }
      ]
    }
  end
end

