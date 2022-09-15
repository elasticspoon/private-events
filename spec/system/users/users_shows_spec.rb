require 'rails_helper'
require 'support/shared_examples_for_event_page_layout'

RSpec.describe 'Users::Shows', type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { create(:user) }

  describe 'page contents' do
    include_examples 'event_layout' do
      let(:start_path) { user_path(user) }
    end
  end
end
