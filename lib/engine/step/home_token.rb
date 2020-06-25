# frozen_string_literal: true

module Engine
  module Step
    class HomeToken < Base
      def blocks?
        true
      end

      def describe
        'HomeToken'
      end

      def action(_action)
        puts 'User chooses home token'
        @game.place_token
        done!
      end

      def can_lay_token?
        true
      end
    end
  end
end
