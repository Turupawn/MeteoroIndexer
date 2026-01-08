class Game < ApplicationRecord
  validates :player_address, presence: true
  validates :game_state, presence: true
  validates :game_id, presence: true, uniqueness: true

  attribute :result, :integer
  enum :result, { error: 0, player_won: 1, house_won: 2, tie: 3 }

  # VRF states: 0=not_started, 1=pending, 2=completed
  attribute :game_state, :integer
  enum :game_state, { not_started: 0, pending: 1, completed: 2 }

  scope :recent, -> { order(request_timestamp: :desc) }

  # Create from Ponder API game request data
  def self.from_ponder_request(request_data)
    new(
      game_id: request_data["id"].to_i,
      game_state: :pending,
      player_address: request_data["player"],
      bet_amount: request_data["betAmount"],
      request_id: request_data["requestId"].to_i,
      request_timestamp: Time.at(request_data["requestTimestamp"].to_i)
    )
  end

  # Create from Ponder API with completion data merged
  def self.from_ponder_completed(request_data, completion_data)
    game = from_ponder_request(request_data)
    game.apply_completion(completion_data)
    game
  end

  # Create from contract struct (for direct RPC calls)
  def self.from_contract_data(game_data, game_id)
    game = new(
      game_id: game_id,
      game_state: game_data[0].to_i,
      player_address: game_data[1],
      bet_amount: game_data[2].to_s,
      request_timestamp: Time.at(game_data[3].to_i),
      player_card: game_data[4].to_s,
      house_card: game_data[5].to_s,
      completed_timestamp: game_data[6].to_i > 0 ? Time.at(game_data[6].to_i) : nil,
      player_won: game_data[7]
    )

    game.calculate_result_from_player_won
    game.calculate_total_time
    game
  end

  # Apply completion data from Ponder API
  def apply_completion(completion_data)
    self.game_state = :completed
    self.player_card = completion_data["playerCard"]
    self.house_card = completion_data["houseCard"]
    self.payout = completion_data["payout"]
    self.completed_timestamp = Time.at(completion_data["completedTimestamp"].to_i)

    # Determine winner from winner address
    winner_address = completion_data["winner"]&.downcase
    if winner_address == "0x0000000000000000000000000000000000000000"
      self.result = :tie
      self.player_won = false
    elsif winner_address == player_address&.downcase
      self.result = :player_won
      self.player_won = true
    else
      self.result = :house_won
      self.player_won = false
    end

    calculate_total_time
  end

  def calculate_result_from_player_won
    return unless game_state == "completed"

    if player_card.present? && house_card.present?
      player_card_value = player_card.to_i
      house_card_value = house_card.to_i

      if player_card_value == house_card_value
        self.result = :tie
      elsif player_won
        self.result = :player_won
      else
        self.result = :house_won
      end
    end
  end

  def calculate_total_time
    return unless request_timestamp.present? && completed_timestamp.present?

    self.total_time = (completed_timestamp - request_timestamp).to_i
  end
end
