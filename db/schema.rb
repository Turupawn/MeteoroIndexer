# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_08_000000) do
  create_table "function_signatures", force: :cascade do |t|
    t.string "name"
    t.string "signature_str"
    t.string "signature_hex"
    t.string "contract_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "games", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "game_state", null: false
    t.string "player_address", null: false
    t.datetime "request_timestamp", null: false
    t.text "bet_amount"
    t.text "player_card"
    t.text "house_card"
    t.integer "result", default: 0
    t.integer "total_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "request_id"
    t.datetime "completed_timestamp"
    t.text "payout"
    t.boolean "player_won", default: false
    t.index ["bet_amount"], name: "index_games_on_bet_amount"
    t.index ["completed_timestamp"], name: "index_games_on_completed_timestamp"
    t.index ["game_id"], name: "index_games_on_game_id", unique: true
    t.index ["player_address"], name: "index_games_on_player_address"
    t.index ["request_id"], name: "index_games_on_request_id"
    t.index ["request_timestamp"], name: "index_games_on_request_timestamp"
    t.index ["result"], name: "index_games_on_result"
    t.index ["total_time"], name: "index_games_on_total_time"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "transaction_hash", null: false
    t.string "method", null: false
    t.integer "sequential_id"
    t.integer "function_signature_id", null: false
    t.string "from_address", null: false
    t.string "to_address", null: false
    t.text "value"
    t.text "fee"
    t.string "gas_used"
    t.string "gas_price"
    t.string "status"
    t.integer "confirmations"
    t.integer "block_number"
    t.datetime "timestamp", null: false
    t.text "raw_input"
    t.text "decoded_input"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["block_number"], name: "index_transactions_on_block_number"
    t.index ["from_address"], name: "index_transactions_on_from_address"
    t.index ["function_signature_id"], name: "index_transactions_on_function_signature_id"
    t.index ["method", "timestamp"], name: "index_transactions_on_method_and_timestamp"
    t.index ["method"], name: "index_transactions_on_method"
    t.index ["sequential_id"], name: "index_transactions_on_sequential_id", unique: true
    t.index ["timestamp"], name: "index_transactions_on_timestamp"
    t.index ["to_address"], name: "index_transactions_on_to_address"
    t.index ["transaction_hash"], name: "index_transactions_on_transaction_hash", unique: true
  end

  add_foreign_key "transactions", "function_signatures"
end
