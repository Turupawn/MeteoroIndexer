class Transaction < ApplicationRecord
  belongs_to :function_signature, optional: true

  validates :transaction_hash, presence: true, uniqueness: true
  validates :sequential_id, presence: true, uniqueness: true
  validates :method, presence: true
  validates :from_address, presence: true
  validates :to_address, presence: true
  validates :timestamp, presence: true

  # Scopes (VRF methods)
  scope :recent, -> { order(timestamp: :desc) }
  scope :by_method, ->(method) { where(method: method) }
  scope :roll_dice, -> { where(method: "rollDice") }
  scope :vrf_callbacks, -> { where(method: "vrfCallback") }

  # Player pays for rollDice, VRF callback is automatic
  def self.player_average_cost
    roll_dice.average(:fee)
  end

  def self.total_player_cost
    roll_dice.sum(:fee)
  end

  # VRF callbacks are paid by the system
  def self.vrf_average_cost
    vrf_callbacks.average(:fee)
  end

  def self.total_vrf_cost
    vrf_callbacks.sum(:fee)
  end

  def eth_value
    return "0 ETH" if value.nil? || value == "0"
    eth_value = value.to_f / 10**18
    formatted = sprintf("%.18f", eth_value).gsub(/\.?0+$/, "")
    "#{formatted} ETH"
  end

  def eth_fee
    return "0 ETH" if fee.nil? || fee == "0"
    eth_fee = fee.to_f / 10**18
    formatted = sprintf("%.18f", eth_fee).gsub(/\.?0+$/, "")
    "#{formatted} ETH"
  end

  def explorer_url
    "#{BlockchainConfig.block_explorer_url}/tx/#{transaction_hash}"
  end

  def from_explorer_url
    "#{BlockchainConfig.block_explorer_url}/address/#{from_address}"
  end

  def self.chart_data
    start_date = 30.days.ago.beginning_of_day
    end_date = Time.current.end_of_day

    data = where(timestamp: start_date..end_date)
           .group("DATE(timestamp)", :method)
           .average(:fee)
           .transform_values { |fee| fee.to_f }

    dates = (start_date.to_date..end_date.to_date).map(&:to_s)

    {
      labels: dates,
      datasets: [
        {
          label: "Roll Dice",
          data: dates.map { |date| data.dig([ date, "rollDice" ]) || 0 },
          borderColor: "rgb(59, 130, 246)",
          backgroundColor: "rgba(59, 130, 246, 0.1)",
          tension: 0.1,
          pointRadius: 3,
          pointHoverRadius: 6
        },
        {
          label: "VRF Callback",
          data: dates.map { |date| data.dig([ date, "vrfCallback" ]) || 0 },
          borderColor: "rgb(34, 197, 94)",
          backgroundColor: "rgba(34, 197, 94, 0.1)",
          tension: 0.1,
          pointRadius: 3,
          pointHoverRadius: 6
        }
      ]
    }
  end
end
