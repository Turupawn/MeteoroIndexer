class TransactionsController < ApplicationController
  def index
    @transactions = Transaction.recent.page(params[:page]).per(20)
    @total_transactions = Transaction.count
    @roll_dice_count = Transaction.roll_dice.count
    @vrf_callback_count = Transaction.vrf_callbacks.count

    # Calculate average costs from database (VRF)
    @player_average_cost = Transaction.player_average_cost || 0
    @vrf_average_cost = Transaction.vrf_average_cost || 0
  end

  def show
    @transaction = Transaction.find(params[:id])
  end

  def chart
    @chart_data = Transaction.chart_data
  end
end
