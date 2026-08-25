class ChangeQuoteItemsVatToDecimal < ActiveRecord::Migration[8.1]
  def change
    change_column :quote_items, :vat, :decimal, precision: 4, scale: 1, default: 0, null: false
  end
end
