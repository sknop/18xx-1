# frozen_string_literal: true

require_relative '../base'
require_relative 'turn_sequence'
require_relative '../abilities/exchange_ability'
module Engine
  module Step
    class EntireGame < Base
      def describe
        'Entire Game'
      end

      def run
        # Add private abilities at the top of the stack
        @game.add_step(ExchangeAbility.new(game: @game, entity: :private1))

        @game.add_step(TurnSequence.new(game: @game,
                                        entity: @game,
                                        sequence: @game.round_sequence,
                                        description: 'Main'))

        done!
      end
    end
  end
end
