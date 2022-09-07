require 'rails_helper'

RSpec.describe 'Users', type: :system do
  before do
    driven_by(:selenium)
  end

  describe 'my first test :)' do
    it 'does a thing', js: true do
      visit '/'
      binding.irb
    end
  end
end
