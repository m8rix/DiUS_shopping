
require 'test/unit'
load 'shopping.rb'

module ScenarioTesting
  # Testing for Example Scenarios found here https://github.com/DiUS/coding-tests/blob/master/dius_shopping.md#example-scenarios
  class ExampleScenarios < Test::Unit::TestCase
    def setup
      @mbp = Item.new(sku: :mbp, name: "MacBook Pro", price: 1399.99)
      @ipd = Item.new(sku: :ipd, name: "Super iPad",  price: 549.99)
      @atv = Item.new(sku: :atv, name: "Apple TV",    price: 109.50)
      @vga = Item.new(sku: :vga, name: "VGA adapter", price: 30.00)

      @rules = [
        Rule.new(
          batch:   { sku: :atv, qty: 3 },
          receive: { sku: :atv }
        ),
        Rule.new(
          batch:   { sku: :mbp },
          receive: { sku: :vga }
        ),
        Rule.new(
          period:  { start: '25/01/2020', end: '25/01/2021' },
          bulk:    { sku: :ipd, qty: 4 },
          receive: { sku: :ipd, fixed: 499.99 }
        )
      ]

      @checkout = Checkout.new(@rules)
    end

    def test_example_scenario_one
      scanned = [@atv, @atv, @atv, @vga]
      scanned.each { |item| @checkout.scan(item) }

      assert(
        @checkout.total == 249.00,
        "SKUs Scanned: atv, atv, atv, vga Total expected: $249.00"
      )
    end

    def test_example_scenario_two
      scanned = [@atv, @ipd, @ipd, @atv, @ipd, @ipd, @ipd]
      scanned.each { |item| @checkout.scan(item) }

      assert(
        @checkout.total == 2718.95,
        "SKUs Scanned: atv, ipd, ipd, atv, ipd, ipd, ipd Total expected: $2718.95"
      )
    end

    def test_example_scenario_three
      scanned = [@mbp, @vga, @ipd]
      scanned.each { |item| @checkout.scan(item) }

      assert(
        @checkout.total == 1949.98,
        "SKUs Scanned: mbp, vga, ipd Total expected: $1949.98"
      )
    end
  end
end

module UnitTesting
  class ItemTest < Test::Unit::TestCase
    def test_attributes_are_accessible
    	mbp = Item.new(sku: :mbp, name: "MacBook Pro", price: 1399.99)

      assert(
        mbp.sku == :mbp,
        "Stock Keeping Unit accessible"
      )

      assert(
        mbp.name == "MacBook Pro",
        "Name accessible"
      )

      assert(
        mbp.price == 1399.99,
        "Price accessible"
      )
    end
  end

  class RuleTest < Test::Unit::TestCase
    def setup
      @mbp = Item.new(sku: :mbp, name: "MacBook Pro", price: 1399.99)
      @ipd = Item.new(sku: :ipd, name: "Super iPad",  price: 549.99)
      @atv = Item.new(sku: :atv, name: "Apple TV",    price: 109.50)
      @vga = Item.new(sku: :vga, name: "VGA adapter", price: 30.00)
    end

    def test_date_range_applies
      rule = Rule.new(period:  { start: '25/01/2000', end: '25/01/3000' })

      assert(
        rule.applies?([]) == true,
        "Todays date is within range"
      )
    end

    def test_date_range_does_not_apply
      rule = Rule.new(period:  { start: '25/01/1900', end: '25/01/2000' })

      assert(
        rule.applies?({}) == false,
        "Todays date is not within range"
      )
    end

    def test_bulk_threshold_reached
      rule = Rule.new(bulk: { sku: :ipd, qty: 4 })
      items = { ipd: [@ipd, @ipd, @ipd, @ipd] }

      assert(
        rule.applies?(items) == true,
        "Bulk threshold reached"
      )
    end

    def test_bulk_threshold_not_reached
      rule = Rule.new(bulk: { sku: :ipd, qty: 4 })
      items = { ipd: [@ipd, @ipd, @ipd] }

      assert(
        rule.applies?(items) == false,
        "Bulk threshold not reached"
      )
    end

    def test_bulk_discount_price_discount
      rule = Rule.new(bulk: { sku: :ipd }, receive: { sku: :ipd, discount: 50 })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == 100,
        "$100 discount applied to order"
      )
    end

    def test_bulk_discount_price_fixed
      rule = Rule.new(bulk: { sku: :ipd }, receive: { sku: :ipd, fixed: 499.99 })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == 100,
        "$100 discount applied to order"
      )
    end

    def test_bulk_discount_price_percent
      rule = Rule.new(bulk: { sku: :ipd }, receive: { sku: :ipd, percent: 0.5 })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == @ipd.price,
        "50\% discount applied to order"
      )
    end

    def test_bulk_discount_price_free
      rule = Rule.new(bulk: { sku: :ipd }, receive: { sku: :ipd })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == @ipd.price * 2,
        "Discount is the total sum of item prices"
      )
    end

    def test_bulk_discount_paired_item_scanned
      rule = Rule.new(bulk: { sku: :ipd }, receive: { sku: :vga })
      items = { ipd: [@ipd, @ipd], vga: [@vga] }

      assert(
        rule.calc(items) == 30,
        "Paired items scanned"
      )
    end

    def test_bulk_discount_paired_item_not_scanned
      rule = Rule.new(bulk: { sku: :ipd }, receive: { sku: :vga })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == 0,
        "Paired items not scanned"
      )
    end

    def test_batch_buy_one_get_one_free_with_evenly_divisible_batches
      rule = Rule.new(batch: { sku: :ipd, qty: 2 }, receive: { sku: :ipd })
      items = { ipd: [@ipd, @ipd, @ipd, @ipd] }

      assert(
        rule.calc(items) == @ipd.price * 2,
        "Discount applied to two iPads"
      )
    end

    def test_batch_buy_one_get_one_free_with_unevenly_divisible_batches
      rule = Rule.new(batch: { sku: :ipd, qty: 2 }, receive: { sku: :ipd })
      items = { ipd: [@ipd, @ipd, @ipd] }

      assert(
        rule.calc(items) == @ipd.price,
        "Discount applied to one iPad"
      )
    end

    def test_batch_discount_price_discount
      rule = Rule.new(batch: { sku: :ipd }, receive: { sku: :ipd, discount: 50 })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == 100,
        "$100 discount applied to order"
      )
    end

    def test_batch_discount_price_fixed
      rule = Rule.new(batch: { sku: :ipd }, receive: { sku: :ipd, fixed: 499.99 })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == 100,
        "$100 discount applied to order"
      )
    end

    def test_batch_discount_price_percent
      rule = Rule.new(batch: { sku: :ipd }, receive: { sku: :ipd, percent: 0.5 })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == @ipd.price,
        "50\% discount applied to order"
      )
    end

    def test_batch_discount_price_free
      rule = Rule.new(batch: { sku: :ipd }, receive: { sku: :ipd })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == @ipd.price * 2,
        "Discount is the total sum of item prices"
      )
    end

    def test_batch_discount_paired_item_scanned
      rule = Rule.new(batch: { sku: :ipd }, receive: { sku: :vga })
      items = { ipd: [@ipd, @ipd], vga: [@vga] }

      assert(
        rule.calc(items) == 30,
        "Paired items scanned"
      )
    end

    def test_batch_discount_paired_item_not_scanned
      rule = Rule.new(batch: { sku: :ipd }, receive: { sku: :vga })
      items = { ipd: [@ipd, @ipd] }

      assert(
        rule.calc(items) == 0,
        "Paired items not scanned"
      )
    end
  end

  class CheckoutTest < Test::Unit::TestCase
    def setup
      @mbp = Item.new(sku: :mbp, name: "MacBook Pro", price: 1399.99)
      @ipd = Item.new(sku: :ipd, name: "Super iPad",  price: 549.99)
      @atv = Item.new(sku: :atv, name: "Apple TV",    price: 109.50)
      @vga = Item.new(sku: :vga, name: "VGA adapter", price: 30.00)

      @empty_checkout = Checkout.new([])

      @full_checkout = Checkout.new([])
      @full_checkout.scan(@mbp)
      @full_checkout.scan(@ipd)
      @full_checkout.scan(@atv)
      @full_checkout.scan(@vga)
    end

    def test_empty_cart_total
      assert(
        @empty_checkout.total == 0,
        "Total is zero when nothing has been scanned"
      )
    end

    def test_full_cart_total
      assert(
        @full_checkout.total > 0,
        "Item prices are tallied up"
      )
    end

    def test_full_cart_clear
      @full_checkout.clear

      assert(
        @full_checkout.total == 0,
        "All Items are removed from cart"
      )
    end

    def test_discount_is_zero_with_no_price_rules
      assert(
        @full_checkout.discount == 0,
        "No pricing rules to apply"
      )
    end

    def test_discount_will_recalculate_between_scans
      @new_checkout = Checkout.new([Rule.new(batch: { sku: :ipd, qty: 2 }, receive: { sku: :ipd })])
      @new_checkout.scan(@mbp)
      @new_checkout.scan(@ipd)

      assert(
        @new_checkout.discount == 0,
        "No discounts to apply"
      )

      @new_checkout.scan(@ipd)

      assert(
        @new_checkout.discount == @ipd.price,
        "One iPad is free"
      )

      @new_checkout.scan(@ipd)

      assert(
        @new_checkout.discount == @ipd.price,
        "Still one iPad is free"
      )

      @new_checkout.scan(@ipd)

      assert(
        @new_checkout.discount == @ipd.price * 2,
        "Now two iPada are free"
      )
    end
  end
end
