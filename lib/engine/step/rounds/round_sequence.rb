# frozen_string_literal: true

require_relative '../base'
require_relative '../buy_and_sell_stocks'
module Engine
  module Step
    class RoundSequence < Base
      def initialize(**opts)
        super(**opts)
        @turn_order = turn_order
      end

      def can_act?
        false
      end

      def run
        # TODO: This should dynamically recalculate at the end of each turn since priority order might change.
        if @turn_order.empty?
          done!
        else
          @game.add_step(turn_step(@turn_order.shift))
        end
      end
    end
  end
end
