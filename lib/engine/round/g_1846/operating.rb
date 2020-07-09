# frozen_string_literal: true

require_relative '../operating'
require_relative '../../token'
require_relative '../half_pay'
require_relative '../issue_shares'
require_relative '../minor_half_pay'

module Engine
  module Round
    module G1846
      class Operating < Operating
        include HalfPay
        include IssueShares
        include MinorHalfPay

        MINOR_STEPS = %i[
          token_or_track
          route
          dividend
        ].freeze

        STEPS = %i[
          issue
          token_or_track
          route
          dividend
          train
          company
        ].freeze

        STEP_DESCRIPTION = {
          issue: 'Issue or Redeem Shares',
          token_or_track: 'Place a Token or Lay Track',
          route: 'Run Routes',
          dividend: 'Pay or Withhold Dividends',
          train: 'Buy Trains',
          company: 'Purchase Companies',
        }.freeze

        SHORT_STEP_DESCRIPTION = {
          issue: 'Issue/Redeem',
          token_or_track: 'Token/Track',
          route: 'Routes',
          train: 'Train',
          company: 'Company',
        }.freeze

        DIVIDEND_TYPES = %i[payout withhold half].freeze

        def select(entities, game, round_num)
          minors, corporations = entities.partition(&:minor?)
          corporations.select!(&:floated?)
          if game.turn == 1 && round_num == 1
            corporations.sort_by! do |c|
              sp = c.share_price
              [sp.price, sp.corporations.find_index(c)]
            end
          else
            corporations.sort!
          end
          minors + corporations
        end

        def steps
          @current_entity.minor? ? self.class::MINOR_STEPS : self.class::STEPS
        end

        def can_lay_track?
          @step == :token_or_track && !skip_track
        end

        def can_place_token?
          @step == :token_or_track && !skip_token
        end

        def finished?
          @end_game || @game.finished || @entities.all?(&:passed?)
        end

        private

        def ignore_action?(action)
          return false if action.is_a?(Action::SellShares) && action.entity.corporation?

          case action
          when Action::PlaceToken, Action::LayTile
            return true if !skip_token || !skip_track
          end

          super
        end

        def count_actions(type)
          @current_actions.count { |action| action.is_a?(type) }
        end

        def skip_token
          return true if no_president?
          return true if count_actions(Action::PlaceToken).positive?

          super
        end

        def skip_track
          return true if no_president?
          free = false

          @current_entity.abilities(:tile_lay) do |ability|
            ability.hexes.each do |hex_id|
              free = true if ability.free && @game.hex_by_id(hex_id).tile.preprinted
            end
          end

          (!free && @current_entity.cash < @game.class::TILE_COST) || count_actions(Action::LayTile) > 1
        end

        def skip_issue
          return true if no_president?
          issuable_shares.empty? && redeemable_shares.empty?
        end

        def skip_dividend
          if no_president?
            revenue = @current_routes.sum(&:revenue)
            process_dividend(Action::Dividend.new(
              @current_entity,
              kind: 'withhold',
            ))
            if @current_entity.trains.empty?
              @log << "#{current_entity.name} has no president and no train"
              change_share_price(0)
            end
            return true
          end

          return super if @current_entity.corporation?

          revenue = @current_routes.sum(&:revenue)
          process_dividend(Action::Dividend.new(
            @current_entity,
            kind: revenue.positive? ? 'payout' : 'withhold',
          ))
          true
        end

        def skip_train
          if no_president?
            buy_train_no_president
            return true
          end

          super
        end

        def skip_company
          return true if no_president?

          super
        end

        def skip_token_or_track
          return true if no_president?
          skip_track && skip_token
        end

        def can_buy_train?
          if no_president? && @current_entity.trains.any?
            return false
          end

          super
        end

        def process_buy_company(action)
          super

          company = action.company
          return unless (minor = @game.minor_by_id(company.id))
          raise GameError, 'Cannot buy minor because train tight' unless corp_has_room?

          cash = minor.cash
          minor.spend(cash, @current_entity) if cash.positive?
          train = minor.trains[0]
          train.buyable = true
          @current_entity.buy_train(train, :free)
          minor.tokens[0].swap!(Token.new(@current_entity))
          @log << "#{@current_entity.name} receives #{@game.format_currency(cash)}"\
            ", a 2 train, and a token on #{minor.coordinates}"
          @game.minors.delete(minor)
          @graph.clear
        end

        def process_bankrupt(action)
          corp = action.entity
          player = corp.owner

          @log << "#{player.name} goes bankrupt and sells remaining shares"

          # first, sell all normally allowed shares
          player.shares_by_corporation.each do |corporation, _|
            next unless corporation.share_price # if a corporation has not parred
            next unless (bundle = sellable_bundles(player, corporation).max_by(&:price))

            sell_shares(bundle)
          end

          # sell shares regardless of 50% and presidency restrictions
          player.shares_by_corporation.each do |corporation, shares|
            next unless corporation.share_price # if a corporation has not parred
            next if shares.empty?

            bundle = ShareBundle.new(shares)

            sell_shares(bundle)

            if corporation.owner == player
              corporation.owner = @bank
            end
          end

          @log << "#{@game.format_currency(player.cash)} is transferred from "\
                  "#{player.name} to #{corp.name}"
          player.spend(player.cash, corp) if player.cash.positive?

          @game.bankruptcies += 1
          @bankrupt = true

          if no_president?
            buy_train_no_president
            # TODO: test this next_step! deal works correctly when bank-owned
            # corp does not buy a train
            next_step!
          end
        end

        def no_president?
          @current_entity.owner == @game.bank
        end

        def buy_train_no_president
          return unless no_president?
          return unless @current_entity.trains.empty?

          train = @depot.min_depot_train
          name, variant = train.variants.min_by { |_, v| v[:price] }
          price = variant[:price]

          if @current_entity.cash >= price
            process_buy_train(Action::BuyTrain.new(
              @current_entity,
              train: train,
              price: price,
              variant: name,
            ))
          end
        end

        def process_lay_tile(action)
          if action.tile.color != :yellow
            raise GameError, 'Cannot upgrade twice' if @current_actions
              .select { |a| a.is_a?(Action::LayTile) }
              .any? { |a| a.tile.color != :yellow }
          end

          super
        end

        def tile_cost(tile, entity)
          [@game.class::TILE_COST, super(tile, entity)].max
        end

        def change_share_price(revenue = 0)
          return if @current_entity.minor?

          price = @current_entity.share_price.price
          @stock_market.move_left(@current_entity) if revenue < price / 2
          @stock_market.move_right(@current_entity) if revenue >= price
          @stock_market.move_right(@current_entity) if revenue >= price * 2
          @stock_market.move_right(@current_entity) if revenue >= price * 3 && price >= 165
          log_share_price(@current_entity, price)
        end
      end
    end
  end
end
