class Transaction < ApplicationRecord
  # Associations
  belongs_to :function_signature, optional: true

  # Validations
  validates :transaction_hash, presence: true, uniqueness: true
  validates :sequential_id, presence: true, uniqueness: true
  validates :method, presence: true
  validates :from_address, presence: true
  validates :to_address, presence: true
  validates :timestamp, presence: true

  # Scopes
  scope :recent, -> { order(timestamp: :desc) }
  scope :by_method, ->(method) { where(method: method) }
  scope :commits, -> { where(method: 'commit') }
  scope :reveals, -> { where(method: 'reveal') }
  scope :multi_post_randomness, -> { where(method: 'multiPostRandomness') }

  # Class methods for calculations
  def self.house_average_cost
    multi_post_randomness.average(:fee)
  end

  def self.player_average_cost
    player_transactions = where(method: ['commit', 'reveal'])
    player_transactions.average(:fee)
  end

  def self.total_house_cost
    multi_post_randomness.sum(:fee)
  end

  def self.total_player_cost
    where(method: ['commit', 'reveal']).sum(:fee)
  end

  # Instance methods
  def eth_value
    return "0 ETH" if value.nil? || value == "0"
    eth_value = value.to_f / 10**18
    formatted = sprintf("%.18f", eth_value).gsub(/\.?0+$/, '')
    "#{formatted} ETH"
  end

  def eth_fee
    return "0 ETH" if fee.nil? || fee == "0"
    eth_fee = fee.to_f / 10**18
    formatted = sprintf("%.18f", eth_fee).gsub(/\.?0+$/, '')
    "#{formatted} ETH"
  end

  def explorer_url
    "#{BlockchainConfig.block_explorer_url}/tx/#{transaction_hash}"
  end

  def from_explorer_url
    "#{BlockchainConfig.block_explorer_url}/address/#{from_address}"
  end

  # Chart data for time series visualization
  def self.chart_data
    # Get data for the last 30 days
    start_date = 30.days.ago.beginning_of_day
    end_date = Time.current.end_of_day

    # Group transactions by day and method
    data = where(timestamp: start_date..end_date)
           .group("DATE(timestamp)", :method)
           .average(:fee)
           .transform_values { |fee| fee.to_f } # Keep in wei

    # Create structured data for Chart.js - show all days in the month
    dates = (start_date.to_date..end_date.to_date).map(&:to_s)
    
    {
      labels: dates,
      datasets: [
        {
          label: 'Commits',
          data: dates.map { |date| data.dig([date, 'commit']) || 0 },
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.1,
          pointRadius: 3,
          pointHoverRadius: 6
        },
        {
          label: 'Reveals',
          data: dates.map { |date| data.dig([date, 'reveal']) || 0 },
          borderColor: 'rgb(147, 51, 234)',
          backgroundColor: 'rgba(147, 51, 234, 0.1)',
          tension: 0.1,
          pointRadius: 3,
          pointHoverRadius: 6
        },
        {
          label: 'MultiPostRandomness',
          data: dates.map { |date| data.dig([date, 'multiPostRandomness']) || 0 },
          borderColor: 'rgb(34, 197, 94)',
          backgroundColor: 'rgba(34, 197, 94, 0.1)',
          tension: 0.1,
          pointRadius: 3,
          pointHoverRadius: 6
        }
      ]
    }
  end
end
