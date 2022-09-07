# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Applications', type: :request do
  describe 'POST /not_implemented' do
    it 'flashes an alert' do
      post not_implemented_path
      expect(flash[:alert]).to eq('Not implemented.')
    end
  end

  describe 'GET /not_implemented' do
    it 'flashes an alert' do
      get not_implemented_path
      expect(flash[:alert]).to eq('Not implemented.')
    end

    it 'redirects' do
      get not_implemented_path
      expect(response).to have_http_status(:found)
    end
  end
end
