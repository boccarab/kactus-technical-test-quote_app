class Quote < ApplicationRecord
    enum :status, %i[draft published archived].index_by(&:itself), prefix: true, default: :draft

    has_many :quote_items, dependent: :destroy

    before_create :generate_identifier, if: -> { identifier.blank? }
    before_update :prevent_status_update, if: -> {
        will_save_change_to_status? && %w[published archived].include?(status_in_database)
    }

    def name
        self[:name].presence || "sans titre"
    end

    def total_excluding_vat
        quote_items.sum(&:total_excluding_vat)
    end

    def total_vat
        quote_items.sum(&:total_vat)
    end

    def total_including_vat
        total_excluding_vat + total_vat
    end

    private

    def generate_identifier
        year = Time.current.year
        next_id = Quote.count + 1

        self.identifier = loop do
            value = "d-#{year}-#{next_id}" # default format. We might allow user to have custom format l
            break value unless self.class.exists?(identifier: value)

            next_id += 1
        end
    end

    def prevent_status_update
        errors.add(:status, "cannot be changed after publication or archiving")
        throw :abort
    end
end
