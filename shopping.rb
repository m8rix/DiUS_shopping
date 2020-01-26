
require "date"
require "ostruct"

class Item < OpenStruct; end

class Rule < OpenStruct
  BulkQtyDefaultLimit = 999_999
  BatchQtyDefault = 1

  def applies?(indexed_items)
    return false unless in_date_range?
    return true unless bulk?

    [*indexed_items.dig(bulk[:sku])].count >= bulk[:qty]
  end

  def calc(indexed_items)
    discounted = discounted_items(indexed_items)

    return 0 if discounted.none?

    if receive.key?(:discount) # $ Off
      discounted.count * receive[:discount]

    elsif receive.key?(:fixed) # $ Fixed
      discounted.map(&:price).sum - discounted.count * receive[:fixed]

    elsif receive.key?(:percent) # % Off
      discounted.map(&:price).sum * (1 - receive[:percent])

    else # Free
      discounted.map(&:price).sum
    end
  end

  private

  def in_date_range?
    return true unless period?

    DateTime.now.between?(
      DateTime.parse(period[:start]),
      DateTime.parse(period[:end])
    )
  end

  def discounted_items(indexed_items)
    count = if bulk?
              receive[:qty] || BulkQtyDefaultLimit
            else
              batch_target = batch[:qty] || BatchQtyDefault
              receive_amount = receive[:qty] || BatchQtyDefault
              [*indexed_items.dig(batch[:sku])].count / batch_target * receive_amount
            end

    return [*indexed_items.dig(receive[:sku])].first(count)
  end

  def period?
    period.respond_to?(:key?)
  end

  def bulk?
    batch.nil? && bulk.respond_to?(:key?)
  end
end

class Checkout
  attr_reader :rules, :cart

  def initialize(pricing_rules)
    @rules = pricing_rules
    clear
  end

  def scan(item)
    @cart << item
  end

  def clear
    @cart = []
  end

  def total
    return 0 if @cart.none?
    @cart.map(&:price).sum - discount
  end

  def discount 
    discount_tally = 0

    @rules.each do |discount|
      next unless discount.applies?(indexed_items)
      discount_tally += discount.calc(indexed_items)
    end

    return discount_tally
  end

  def indexed_items
    @cart.group_by(&:sku)
  end
end
