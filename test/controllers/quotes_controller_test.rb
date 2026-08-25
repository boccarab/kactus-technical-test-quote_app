require "test_helper"

class QuotesControllerTest < ActionDispatch::IntegrationTest
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
