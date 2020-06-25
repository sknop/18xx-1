# frozen_string_literal: true

require_relative '../base'
require_relative 'turn_sequence'
require_relative 'round_sequence'
module Engine
  module Step
    class OperatingRound < RoundSequence
      def initialize(**opts)
        super(**opts)
      end

      def turn_order
        @game.corporations
      end

      def turn_step(entity)
        TurnSequence.new(game: @game, entity: entity, sequence: @game.operating_sequence, description: 'Operating')
      end

      def describe
        'Operating Round'
      end
    end
  end
end
