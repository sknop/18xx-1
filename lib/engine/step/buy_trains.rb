# frozen_string_literal: true

require_relative 'check_discard_trains'

module Engine
  module Step
    class BuyTrains < Base
      def describe
        'Buy trains'
      end

      def action(action)
        raise 'Unexpected action' unless action == @entity

        game.buy_train
        # Fake a phase change, everyone might need to discard down
        @game.corporations.each do |corp|
          @game.add_step(CheckDiscardTrains.new(game: @game, entity: corp))
        end
        done!
      end

      def can_buy_trains?
        true
      end
    end
  end
end
