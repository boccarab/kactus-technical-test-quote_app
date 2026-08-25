raise "Seeds are only allowed in development" unless Rails.env.development?

require "active_support/testing/time_helpers"

include ActiveSupport::Testing::TimeHelpers

quotes = [
  {
    name: "Refonte du site vitrine",
    status: :draft,
    items: [ [ "Conception UX/UI", 2, 75_000, 20 ], [ "Développement Rails", 8, 85_000, 20 ], [ "Mise en production", 1, 50_000, 20 ] ]
  },
  {
    name: "Application de réservation",
    status: :draft,
    items: [ [ "Atelier de cadrage", 1, 90_000, 20 ], [ "Développement du MVP", 12, 80_000, 20 ], [ "Formation équipe", 2, 60_000, 20 ] ]
  },
  {
    name: "Identité visuelle",
    status: :draft,
    items: [ [ "Recherche créative", 3, 55_000, 20 ], [ "Création du logo", 1, 120_000, 20 ], [ "Charte graphique", 1, 95_000, 20 ] ]
  },
  {
    name: "Campagne de lancement",
    status: :draft,
    items: [ [ "Stratégie éditoriale", 2, 65_000, 20 ], [ "Création de contenus", 6, 40_000, 20 ], [ "Suivi de campagne", 3, 50_000, 20 ] ]
  },
  {
    name: "Audit de performance",
    status: :draft,
    items: [ [ "Audit technique", 2, 70_000, 20 ], [ "Rapport de recommandations", 1, 60_000, 20 ], [ "Restitution", 1, 45_000, 20 ] ]
  },
  {
    name: "Portail client",
    status: :published,
    items: [ [ "Architecture technique", 3, 90_000, 20 ], [ "Développement", 15, 82_000, 20 ], [ "Recette fonctionnelle", 4, 60_000, 20 ] ]
  },
  {
    name: "Maintenance annuelle",
    status: :published,
    items: [ [ "Maintenance préventive", 12, 25_000, 20 ], [ "Support utilisateur", 20, 12_000, 20 ], [ "Rapport trimestriel", 4, 20_000, 20 ] ]
  },
  {
    name: "Boutique en ligne",
    status: :published,
    items: [ [ "Catalogue produits", 5, 65_000, 20 ], [ "Tunnel de commande", 6, 78_000, 20 ], [ "Intégration du paiement", 2, 85_000, 20 ] ]
  },
  {
    name: "Migration des données",
    status: :published,
    items: [ [ "Analyse des données", 3, 72_000, 20 ], [ "Scripts de migration", 7, 80_000, 20 ], [ "Contrôle qualité", 3, 58_000, 20 ] ]
  },
  {
    name: "Tableau de bord commercial",
    status: :published,
    items: [ [ "Définition des indicateurs", 2, 68_000, 20 ], [ "Développement du tableau", 8, 84_000, 20 ], [ "Accompagnement au déploiement", 2, 55_000, 20 ] ]
  }
]

Quote.transaction do
  QuoteItem.delete_all
  Quote.delete_all

  travel_to 10.days.ago

  begin
    quotes.each do |attributes|
      quote = Quote.create!(name: attributes[:name], status: attributes[:status])

      attributes[:items].each do |name, quantity, unit_price, vat|
        quote.quote_items.create!(
          name: name,
          quantity: quantity,
          unit_price: unit_price,
          vat: vat
        )
      end

      travel 1.day
    end
  ensure
    travel_back
  end
end

puts "10 devis et 30 éléments créés."
