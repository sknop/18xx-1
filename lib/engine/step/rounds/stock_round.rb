# frozen_string_literal: true

require_relative '../base'
require_relative 'round_sequence'
require_relative '../buy_and_sell_stocks'
module Engine
  module Step
    class StockRound < RoundSequence
      def initialize(**opts)
        super(**opts)
      end

      def turn_order
        @game.players
      end

      def turn_step(entity)
        Step::BuyAndSellStocks.new(game: @game, entity: entity)
      end

      def describe
        'Stock Round'
      end
    end
  end
end
