require "test_helper"

class QuotesControllerTest < ActionDispatch::IntegrationTest
  test "renders the same editor for new and edit routes" do
    quote = Quote.create!(identifier: "DEV-EDIT", name: "À modifier")
    quote.quote_items.create!(name: "Article", quantity: 1, unit_price: 1_000, vat: 20)

    get new_quote_path
    assert_response :success
    assert_select "form[data-controller='quote-editor']"
    assert_select "span", "En cours d’édition"
    assert_select "div.table[role='table']", count: 1
    assert_select "template[data-quote-editor-target='rowTemplate']", count: 1
    assert_select "div.table-row[data-quote-editor-target='editor']:not(.hidden)", count: 1
    assert_select "table", count: 0

    get edit_quote_path(quote)
    assert_response :success
    assert_select "input[name='quote[name]'][value='À modifier']"
    assert_select "button", text: /Enregistrer et quitter/
    assert_select "div[data-quote-editor-target='editor'].hidden", count: 1
  end

  test "creates a quote and its items in one request then returns to the listing" do
    assert_difference([ "Quote.count", "QuoteItem.count" ], 1) do
      post quotes_path, params: { quote: { name: "Nouveau devis", quote_items_attributes: { "0" => { name: "Conseil", quantity: 2, unit_price: 10_000, vat: 5.5 } } } }
    end

    assert_redirected_to quotes_path
    assert_equal "Conseil", Quote.last.quote_items.first.name
    assert_equal 5.5, Quote.last.quote_items.first.vat
  end

  test "updates and removes items only when the quote is submitted" do
    quote = Quote.create!(identifier: "DEV-UPDATE", name: "Avant")
    removed_item = quote.quote_items.create!(name: "Ancien", quantity: 1, unit_price: 1_000, vat: 20)

    patch quote_path(quote), params: { quote: { name: "Après", quote_items_attributes: { "0" => { id: removed_item.id, _destroy: "1" }, "1" => { name: "Nouveau", quantity: 3, unit_price: 2_000, vat: 10 } } } }

    assert_redirected_to quotes_path
    assert_equal "Après", quote.reload.name
    assert_equal [ "Nouveau" ], quote.quote_items.pluck(:name)
  end

  test "shows a published quote in read-only mode with its items and totals" do
    quote = Quote.create!(identifier: "DEV-SHOW", name: "Devis publié", status: :published)
    quote.quote_items.create!(name: "Conseil", quantity: 2, unit_price: 10_000, vat: 20)

    get quote_path(quote)

    assert_response :success
    assert_select "h1", "Devis publié"
    assert_select "span", "Validé"
    assert_select "a[href='#{quotes_path}']", text: /Quitter/
    assert_select "div.table-row-group div.table-row", count: 1
    assert_select "div.table-row-group", text: /Conseil/
    assert_select "table", count: 0
    assert_select "form", count: 0
    assert_select "dl", text: /240,00 €/
  end

  test "does not show a quote that is not published" do
    quote = Quote.create!(identifier: "DEV-DRAFT", name: "Brouillon", status: :draft)

    get quote_path(quote)

    assert_response :not_found
    assert_select "h1", "Devis introuvable"
    assert_select "a[href='#{quotes_path}']", text: /Retour à mes devis/
  end

  test "shows the quote not found page when the quote does not exist" do
    get quote_path("00000000-0000-0000-0000-000000000000")

    assert_response :not_found
    assert_select "h1", "Devis introuvable"
    assert_select "a[href='#{quotes_path}']", text: /Retour à mes devis/
  end

  test "lists draft and published quotes with the most recently edited first" do
    older_draft = Quote.create!(identifier: "DEV-001", name: "Ancien brouillon", status: :draft)
    published = Quote.create!(identifier: "DEV-002", name: "Devis publié", status: :published)
    archived = Quote.create!(identifier: "DEV-003", name: "Devis archivé", status: :archived)
    newer_draft = Quote.create!(identifier: "DEV-004", name: "Nouveau brouillon", status: :draft)

    older_draft.update_column(:updated_at, 3.days.ago)
    published.update_column(:updated_at, 2.days.ago)
    archived.update_column(:updated_at, 1.day.ago)
    newer_draft.update_column(:updated_at, Time.current)

    get quotes_path

    assert_response :success
    assert_select "h1", "Mes devis"
    assert_select "div.table-row-group div.table-row", count: 3
    assert_select "div.table-row-group div.table-row:nth-child(1)", text: /Nouveau brouillon/
    assert_select "div.table-row-group div.table-row:nth-child(2)", text: /Devis publié/
    assert_select "div.table-row-group div.table-row:nth-child(3)", text: /Ancien brouillon/
    assert_select "table", count: 0
    assert_select "body", text: /Devis archivé/, count: 0
    assert_select "a[href='#{edit_quote_path(older_draft)}']"
    assert_select "form[action='#{quote_path(older_draft)}'][data-controller='confirmation'][data-action='submit->confirmation#confirm']"
    assert_select "a[href='#{quote_path(published)}']"
    assert_select "a[href='#{new_quote_path}']", text: /Ajouter un devis/
  end

  test "destroys a draft quote and returns a turbo stream removing its row" do
    quote = Quote.create!(identifier: "DEV-DELETE", name: "À supprimer", status: :draft)

    assert_difference("Quote.count", -1) do
      delete quote_path(quote), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action='remove'][target='quote_#{quote.id}']"
  end

  test "does not destroy a quote that is not a draft" do
    %i[published archived].each do |status|
      quote = Quote.create!(identifier: "DEV-#{status}", name: "Non supprimable", status: status)

      assert_no_difference("Quote.count") do
        delete quote_path(quote), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      assert_response :unprocessable_entity
      assert_equal "Only draft quotes can be deleted.", response.body
      assert Quote.exists?(quote.id)
    end
  end
end
