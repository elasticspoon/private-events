FactoryBot.define do
  factory :user, aliases: [:creator] do
    name { Faker::Name.name }
    username { Faker::Internet.username(specifier: 5) }
    password { Faker::Internet.password(min_length: 6) }
    email { Faker::Internet.email }
  end

  factory :event do
    creator
    name { Faker::Esport.event }
    desc { Faker::Lorem.sentence(word_count: 50, supplemental: true, random_words_to_add: 30) }
    date { DateTime.now }
    location { Faker::Fantasy::Tolkien.location }
    event_privacy { 'public' }
    display_privacy { 'public' }
  end

  factory :permission, class: 'UserEventPermission' do
    user
    event
    permission_type { 'attend' }
  end
end
