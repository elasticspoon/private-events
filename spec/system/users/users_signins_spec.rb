require 'rails_helper'

RSpec.describe 'Users::Signins', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  let(:user) { build_stubbed(:user) }
  let(:existing_user) { create(:user) }

  describe 'sign in page contents' do
    before { visit new_user_session_path }

    it 'has a link to sign up', browser: true do
      click_link 'Sign up'
      expect(page.has_current_path?(new_user_registration_path)).to be true
    end

    it 'has a link to index' do
      click_link 'Home'
      expect(page.has_current_path?(root_path)).to be true
    end

    it 'does not let users sign in with invalid credentials' do
      fill_in 'user_email', with: 'invalid@email.com'
      fill_in 'user_password', with: 'invalidpassword'
      click_button 'Log in'
      expect(page.has_content?('Invalid')).to be true
    end
  end

  describe 'sign in action' do
    before { sign_in }

    it 'redirects to index' do
      expect(page.has_current_path?(root_path)).to be true
    end

    it 'shows a success alert' do
      expect(page.has_content?('Signed in successfully')).to be true
    end

    it 'shows the users email' do
      expect(page.has_content?(existing_user.email)).to be true
    end
  end

  describe 'page reachable' do
    it 'is reachable from the index page' do
      visit root_path
      within '#header-nav' do
        click_link 'Log In'
      end
      expect(page.has_current_path?(new_user_session_path)).to be true
    end

    it 'is reachable from the event page' do
      visit event_path(create(:event))
      within '#header-nav' do
        click_link 'Log In'
      end
      expect(page.has_current_path?(new_user_session_path)).to be true
    end
  end

  ###### Helper Methods ######
  def sign_in
    visit new_user_session_path
    fill_in 'user_email', with: existing_user.email
    fill_in 'user_password', with: existing_user.password
    click_button 'Log in'
  end
end
