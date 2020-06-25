# frozen_string_literal: true

require_relative '../base'
require_relative '../buy_and_sell_stocks'
module Engine
  module Step
    class TurnSequence < Base
      def initialize(sequence:, description:, **opts)
        super(**opts)
        @sequence = sequence
        @description = description
      end

      def can_act?
        false
      end

      def describe
        @description
      end

      def run
        if @sequence.empty?
          done!
        else
          step = @sequence.shift
          @game.add_step(step.new(game: @game, entity: @entity))
        end
      end
    end
  end
end
