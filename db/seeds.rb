# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
require 'faker'
User.destroy_all
Event.destroy_all
UserEventPermission.destroy_all

VISIBILITY = %w[public public public public public public protected private].freeze
ACCESS = %w[public public public public public public public private].freeze

30.times do
  User.create!(name: Faker::Name.name,
               username: Faker::Internet.username(specifier: 5),
               password: Faker::Internet.password(min_length: 6),
               email: Faker::Internet.email)
end

User.all.each do |user|
  5.times do
    user.events_created
        .create!(name: Faker::Esport.event,
                 desc: Faker::Lorem.sentence(word_count: 50, supplemental: true,
                                             random_words_to_add: 30),
                 date: Faker::Date.forward(days: 360),
                 location: Faker::Fantasy::Tolkien.location,
                 event_privacy: ACCESS.sample,
                 display_privacy: VISIBILITY.sample,
                 attendee_privacy: VISIBILITY.sample)
  end
end
