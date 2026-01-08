class GamesController < ApplicationController
  def index
    @games = Game.recent.page(params[:page]).per(20)
    @total_games = Game.count
    @pending_games = Game.pending.count
    @completed_games = Game.completed.count
    @total_transactions = Transaction.count
    @house_balance = EthBalanceService.get_house_balance
  end

  def show
    @game = Game.find(params[:id])
    @house_balance = EthBalanceService.get_house_balance
  end
end
