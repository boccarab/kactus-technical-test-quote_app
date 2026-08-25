class QuoteItem < ApplicationRecord
  belongs_to :quote

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
