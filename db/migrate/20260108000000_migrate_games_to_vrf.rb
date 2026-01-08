class MigrateGamesToVrf < ActiveRecord::Migration[8.0]
  def change
    # Remove old commit-reveal columns
    remove_column :games, :player_commit, :string
    remove_column :games, :house_randomness, :string
    remove_column :games, :house_randomness_timestamp, :datetime
    remove_column :games, :player_secret, :string
    remove_column :games, :reveal_timestamp, :datetime

    # Rename commit_timestamp to request_timestamp (VRF terminology)
    rename_column :games, :commit_timestamp, :request_timestamp

    # Add new VRF-specific columns
    add_column :games, :request_id, :bigint
    add_column :games, :completed_timestamp, :datetime
    add_column :games, :payout, :text
    add_column :games, :player_won, :boolean, default: false

    # Add index for request_id
    add_index :games, :request_id
    add_index :games, :completed_timestamp
  end
end
