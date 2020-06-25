# frozen_string_literal: true

require_relative 'rounds/entire_game'
require_relative 'buy_trains'
require_relative 'buy_and_sell_stocks'
require_relative 'rounds/stock_round'
require_relative 'rounds/operating_round'

module Engine
  module Step
    class DummyGame
      def corporations
        %i[corp1 corp2]
      end

      def players
        %i[player1 player2]
      end

      def round_sequence
        [Step::StockRound, Step::OperatingRound, Step::OperatingRound]
      end

      def operating_sequence
        [Step::BuyTrains]
      end

      def stock_sequence
        [Step::BuyAndSellStocks]
      end

      def initialize
        @steps = [Step::EntireGame.new(game: self, entity: self)]
      end

      def to_s
        'Dummy Game'
      end

      def add_step(step)
        @steps << step
      end

      def dummy_run
        while @steps.any?(&:must_complete?)
          run
          next unless @steps.any?(&:must_complete?)

          available = available_steps
          puts "Available #{available.size}"
          available.each { |x| puts " #{x.class}" }
          puts
          # In this faked example entity is the action.
          action(available.last.entity)
        end
      end

      def available_steps
        available = []
        @steps.reverse_each do |step|
          available << step if step.can_act?
          break if step.blocks?
        end
        available
      end

      def action(action)
        puts "User submits #{action}"
        step = available_steps.find { |step2| step2.entity == action }
        step.action(action)
        @steps.delete(step) if step.done?
      end

      def run
        while @steps.any?(&:must_complete?)
          active = @steps.last

          if active.done?
            @steps.delete(active)
            next
          end

          puts "Running '#{active.describe}' for #{active.entity}"
          active.run
          if active.done?
            @steps.delete(active)
          elsif @steps.last == active
            puts "Need user action #{active.describe}"
            break
          end
        end
      end

      def place_token
        puts 'Placed token'
      end

      def buy_train
        puts 'Buy train'
      end

      def discard_train
        puts 'Discard'
      end
    end
  end
end
