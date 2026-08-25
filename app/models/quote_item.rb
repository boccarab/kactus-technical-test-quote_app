class QuoteItem < ApplicationRecord
  belongs_to :quote

  def price_vat_part
    ratio =  vat.to_f / 100
    (unit_price * ratio).to_i
  end

  def price_with_vat
    unit_price + price_vat_part
  end
end
