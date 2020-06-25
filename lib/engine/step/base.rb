# frozen_string_literal: true

module Engine
  module Step
    class Base
      attr_reader :game, :entity

      def initialize(game:, entity:)
        @done = false
        @game = game
        @entity = entity
      end

      def done?
        @done
      end

      def done!
        @done = true
      end

      # Each step is run to see if automated actions are possible
      def run; end

      # Call as part of the user submitting an action that relates to this entity
      def action(action); end

      # Can currently act? Might be privates cannot act in the stock round
      def can_act?
        true
      end

      # Does this action block other actions in the list? i.e. is it an interrupt?
      def blocks?
        false
      end

      # Must complete before the game has ended
      def must_complete?
        true
      end

      def describe; end

      def can_buy_trains?
        false
      end

      def can_buy_or_sell_stock?
        false
      end

      def can_lay_token?
        false
      end
    end
  end
end
