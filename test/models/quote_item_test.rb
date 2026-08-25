require "test_helper"

class QuoteItemTest < ActiveSupport::TestCase
  def setup
    @quote = Quote.create!(identifier: "DEV-QUOTE-ITEM-TEST")
  end

  def valid_attributes
    {
      quote: @quote,
      name: "Consulting",
      quantity: 2,
      unit_price: 1_000,
      vat: 20
    }
  end

  test "creates a quote item with valid attributes" do
    assert_difference("QuoteItem.count", 1) do
      QuoteItem.create!(valid_attributes)
    end
  end

  test "uses default quantity, unit price, and vat values" do
    quote_item = QuoteItem.create!(quote: @quote, name: "Consulting")

    assert_equal 1, quote_item.quantity
    assert_equal 0, quote_item.unit_price
    assert_equal 0, quote_item.vat
  end

  test "updates a quote item" do
    quote_item = QuoteItem.create!(valid_attributes)

    assert quote_item.update(name: "Development", quantity: 3)
    assert_equal "Development", quote_item.reload.name
    assert_equal 3, quote_item.quantity
  end

  test "destroys a quote item" do
    quote_item = QuoteItem.create!(valid_attributes)

    assert_difference("QuoteItem.count", -1) do
      quote_item.destroy!
    end
  end

  test "is invalid without a quote" do
    quote_item = QuoteItem.new(valid_attributes.except(:quote))

    assert_not quote_item.valid?
    assert_includes quote_item.errors[:quote], "must exist"
  end

  test "unit_price_vat returns the vat portion of the unit price" do
    quote_item = QuoteItem.new(valid_attributes.merge(unit_price: 1_234, vat: 20))

    assert_equal 246, quote_item.unit_price_vat
  end

  test "unit_price_including_vat returns the unit price including vat" do
    quote_item = QuoteItem.new(valid_attributes.merge(unit_price: 1_234, vat: 20))

    assert_equal 1_480, quote_item.unit_price_including_vat
  end

  test "calculates line totals using the quantity" do
    quote_item = QuoteItem.new(valid_attributes.merge(quantity: 3, unit_price: 1_000, vat: 20))

    assert_equal 3_000, quote_item.total_excluding_vat
    assert_equal 600, quote_item.total_vat
    assert_equal 3_600, quote_item.total_including_vat
  end
end
