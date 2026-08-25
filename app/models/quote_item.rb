class QuoteItem < ApplicationRecord
  belongs_to :quote

  validates :name, presence: true, length: { maximum: 100 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :vat, inclusion: { in: ApplicationHelper::VAT_RATES + [ 0 ] }

  def unit_price_vat
    ratio =  vat.to_f / 100
    (unit_price * ratio).to_i
  end

  def unit_price_including_vat
    unit_price + unit_price_vat
  end

  def total_excluding_vat
    unit_price * quantity
  end

  def total_vat
    unit_price_vat * quantity
  end

  def total_including_vat
    unit_price_including_vat * quantity
  end
end
