# frozen_string_literal: true

require_relative '../base'
module Engine
  module Step
    class ExchangeAbility < Base
      def initialize(**opts)
        super(**opts)
      end

      def describe
        'Exchange Private for Stock'
      end

      def must_complete?
        false
      end

      def action(_action)
        puts "#{@entity} exchanges"
        done!
      end
    end
  end
end
