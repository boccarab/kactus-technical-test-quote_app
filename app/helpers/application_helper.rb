module ApplicationHelper
  VAT_RATES = [ 20, 10, 5.5 ].freeze

  def format_money(cents)
    number_to_currency(cents.to_f / 100, unit: "€", format: "%n %u", delimiter: " ", separator: ",")
  end
end
