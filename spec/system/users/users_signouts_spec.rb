require 'rails_helper'

RSpec.describe 'Users::Signouts', type: :system do
  before { driven_by(:selenium_chrome_headless) }

  let(:user) { create(:user) }

  describe 'sign out action' do
    before do
      sign_in user
      visit root_path
      click_button user.email
      click_button 'Log Out'
    end

    it 'redirects to index' do
      expect(page.has_current_path?(root_path)).to be true
    end

    it 'shows a success alert' do
      expect(page.has_content?('Signed out successfully')).to be true
    end

    it 'shows sign in link' do
      expect(page.find('#header-nav').has_link?('Log In')).to be true
    end
  end

  describe 'sign out clickable' do
    before { sign_in user }

    it 'is reachable from the index page' do
      visit root_path
      click_button user.email
      click_button 'Log Out'
      expect(page.find('#header-nav').has_link?('Log In')).to be true
    end

    it 'is reachable from the event page' do
      visit event_path(create(:event))
      click_button user.email
      click_button 'Log Out'
      expect(page.find('#header-nav').has_link?('Log In')).to be true
    end
  end
end
