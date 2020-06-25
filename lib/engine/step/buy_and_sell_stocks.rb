# frozen_string_literal: true

require_relative 'home_token'
module Engine
  module Step
    class BuyAndSellStocks < Base
      def initialize(**opts)
        super(**opts)
        @parred = false
      end

      def describe
        'Buy and Sell Stocks'
      end

      def run
        if @parred
          puts "#{entity} passes"
          done!
        else
          puts "#{entity} pars and must choose home token"
          @game.add_step(HomeToken.new(game: @game, entity: :company1)) # if timing==:par
          @parred = true
        end
      end

      def can_buy_stock?
        true
      end

      def can_sell_stock?
        true
      end
    end
  end
end
