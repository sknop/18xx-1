# frozen_string_literal: true

module Engine
  module Step
    class CheckDiscardTrains < Base
      def describe
        'Discard trains for new train limit'
      end

      def run
        # corp1 only has 1 train... doesn't need to discard
        done! if @entity == :corp1
      end

      def action(_action)
        game.discard_train
        done!
      end

      def can_discard_trains?
        true
      end
    end
  end
end
