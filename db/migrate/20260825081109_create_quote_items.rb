class CreateQuoteItems < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_items do |t|
      t.references :quote, null: false, foreign_key: true, type: :uuid
      t.integer :quantity, default: 1, null: false
      t.integer :unit_price, default: 0, null: false
      t.integer :vat, default: 0, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
