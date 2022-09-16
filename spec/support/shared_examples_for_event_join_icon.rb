require 'rails_helper'

RSpec.shared_examples 'join event button' do
  describe 'join event button' do
    let!(:event) { create(:event, creator: user, date: 1.day.from_now) }

    before do
      driven_by(:selenium)
      event
      sign_in user
    end

    it 'lets user join event' do
      visit start_path
      click_button('Join Event', match: :first)
      expect(UserEventPermission.exists?(user:, event:, permission_type: 'attend')).to be true
    end

    it 'lets user leave event' do
      create(:permission, user:, event:, permission_type: 'attend')
      visit start_path
      click_button('Leave Event', match: :first)
      expect(UserEventPermission.exists?(user:, event:, permission_type: 'attend')).to be false
    end
  end
end
