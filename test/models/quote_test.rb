require "test_helper"

class QuoteTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  def valid_attributes
    { identifier: "DEV-2026-001" }
  end

  test "creates a quote with valid attributes" do
    quote = Quote.new(valid_attributes)
    assert quote.save
  end

  test "defaults name to 'sans titre' when not provided" do
    quote = Quote.create!(valid_attributes)
    assert_equal "sans titre", quote.name
  end

  test "defaults status to 'draft' when not provided" do
    quote = Quote.create!(valid_attributes)
    assert_equal "draft", quote.status
  end

  test "generates a uuid automatically" do
    quote = Quote.create!(valid_attributes)
    assert quote.uuid.present?
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, quote.uuid)
  end

  test "sets created_at and updated_at on creation" do
    quote = Quote.create!(valid_attributes)
    assert quote.created_at.present?
    assert quote.updated_at.present?
  end

  test "accepts each valid enum status value" do
    %w[draft published archived].each do |status|
      quote = Quote.create!(valid_attributes.merge(identifier: "DEV-#{status}", status: status))
      assert_equal status, quote.status
    end
  end

  test "raises ArgumentError when assigning an invalid status value" do
    assert_raises(ArgumentError) do
      Quote.new(valid_attributes.merge(status: "not_a_real_status"))
    end
  end

  test "allows a custom name to override the default" do
    quote = Quote.create!(valid_attributes.merge(name: "Devis Client Dupont"))
    assert_equal "Devis Client Dupont", quote.name
  end

  # --- enum :status (prefix: true) ---

  test "exposes prefixed predicate methods for status" do
    quote = Quote.create!(valid_attributes.merge(status: :draft))
    assert quote.status_draft?
    assert_not quote.status_published?
    assert_not quote.status_archived?
  end

  test "exposes prefixed bang methods that update and persist status" do
    quote = Quote.create!(valid_attributes.merge(status: :draft))
    quote.status_published!
    assert_equal "published", quote.reload.status
  end

  test "allows a draft quote to be published or archived" do
    published_quote = Quote.create!(valid_attributes.merge(identifier: "DEV-published-transition"))
    published_quote.status_published!
    assert_equal "published", published_quote.reload.status

    archived_quote = Quote.create!(valid_attributes.merge(identifier: "DEV-archived-transition"))
    archived_quote.status_archived!
    assert_equal "archived", archived_quote.reload.status
  end

  test "does not allow a published quote to change status" do
    quote = Quote.create!(valid_attributes.merge(status: :published))
    quote.status = :archived

    assert_not quote.save
    assert_includes quote.errors[:status], "cannot be changed after publication or archiving"
    assert_equal "published", quote.reload.status
  end

  test "does not allow an archived quote to change status" do
    quote = Quote.create!(valid_attributes.merge(status: :archived))
    quote.status = :draft

    assert_not quote.save
    assert_includes quote.errors[:status], "cannot be changed after publication or archiving"
    assert_equal "archived", quote.reload.status
  end

  test "exposes prefixed scopes for each status" do
    draft = Quote.create!(identifier: "DEV-scope-draft", status: :draft)
    published = Quote.create!(identifier: "DEV-scope-published", status: :published)

    assert_includes Quote.status_draft, draft
    assert_not_includes Quote.status_draft, published
    assert_includes Quote.status_published, published
  end

  # --- generate_identifier callback ---

  test "auto-generates an identifier when none is provided" do
    travel_to Time.zone.local(2026, 1, 1) do
      quote = Quote.create!(name: "Sans identifiant")
      assert_match(/\Ad-2026-\d+\z/, quote.identifier)
    end
  end

  test "does not overwrite an explicitly provided identifier" do
    quote = Quote.create!(identifier: "CUSTOM-ID-42")
    assert_equal "CUSTOM-ID-42", quote.identifier
  end

  test "generates sequential identifiers across successive creations" do
    travel_to Time.zone.local(2026, 1, 1) do
      first = Quote.create!(name: "Premier devis")
      second = Quote.create!(name: "Deuxieme devis")

      assert_not_equal first.identifier, second.identifier
      assert_match(/\Ad-2026-\d+\z/, first.identifier)
      assert_match(/\Ad-2026-\d+\z/, second.identifier)
    end
  end

  test "skips a candidate identifier that already exists and picks the next one" do
    travel_to Time.zone.local(2026, 1, 1) do
      # One existing record ⇒ Quote.count == 1 when the next quote is created,
      # so the natural next candidate would be "d-2026-2". We pre-empt it here
      # to force the generator's collision-avoidance loop to increment further.
      Quote.create!(identifier: "d-2026-1")
      Quote.create!(identifier: "d-2026-2")

      quote = Quote.create!(name: "Devis suivant")

      assert_equal "d-2026-3", quote.identifier
    end
  end

  test "generated identifier is unique in the database" do
    travel_to Time.zone.local(2026, 1, 1) do
      quotes = Array.new(5) { Quote.create!(name: "Devis") }
      assert_equal quotes.size, quotes.map(&:identifier).uniq.size
    end
  end


  test "calculates totals across its items" do
    quote = Quote.create!(valid_attributes)
    quote.quote_items.create!(name: "Conseil", quantity: 2, unit_price: 10_000, vat: 20)
    quote.quote_items.create!(name: "Formation", quantity: 1, unit_price: 5_000, vat: 10)

    assert_equal 25_000, quote.total_excluding_vat
    assert_equal 4_500, quote.total_vat
    assert_equal 29_500, quote.total_including_vat
  end
end
