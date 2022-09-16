# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:user) { create(:user) }

  # users#show
  describe 'GET /user/:id' do
    it 'returns a valid status if user exists' do
      get user_path(user.id)
      expect(response.ok?).to be(true)
    end

    it 'renders the show template if user exists' do
      get user_path(user.id)
      expect(response).to render_template(:show)
    end
  end
end
