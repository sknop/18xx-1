# frozen_string_literal: true

require_relative '../stock'

module Engine
  module Round
    module G1846
      class Stock < Stock
        def sellable_bundles(player, corporation)
          return [] if corporation.owner == @game.bank

          super(player, corporation)
        end
      end
    end
  end
end
