require 'rails_helper'
RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request # to sign_in user by Devise
end

RSpec.describe 'Users', type: :request do
  let(:created_user) { User.create(email: 'a@gmail.com', username: 'asaada', password: '123456', name: 'asds') }
  let(:created_event) do
    Event.create(date: DateTime.now, location: 'asdasd', event_privacy: 'public', desc: 'asdasd', name: 'asdasd',
                 display_privacy: 'public', attendee_privacy: 'public', creator_id: created_user.id)
  end
  describe '#show' do
    it do
      get user_path(user.id)
      expect(response).to have_http_status(200)
    end
  end
end
