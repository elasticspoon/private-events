require 'rails_helper'

RSpec.describe "Users::Registrations", type: :request do
  describe "GET /users/registrations" do
    it "works! (now write some real specs)" do
      get users_registrations_path
      expect(response).to have_http_status(200)
    end
  end
end
