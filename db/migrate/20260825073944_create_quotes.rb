class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes, id: :uuid do |t|
      create_enum :quote_status, [ "draft", "published", "archived" ]

      t.enum :status, enum_type: :quote_status, default: "draft", null: false
      t.uuid :uuid, default: "gen_random_uuid()", null: false
      t.string :identifier
      t.string :name

      t.index [ "status" ], name: "index_quotes_on_status"

      t.timestamps
    end
  end
end
