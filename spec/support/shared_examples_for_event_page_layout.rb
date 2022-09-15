require 'rails_helper'

RSpec.shared_examples 'event_layout' do
  it 'has link to create event' do
    visit start_path
    expect(page.has_link?('Create an event')).to be true
  end

  it 'has link to events index' do
    visit start_path
    click_link 'Home'
    expect(page.has_current_path?(root_path)).to be true
  end

  context 'when user is not logged in' do
    before do
      driven_by(:selenium)
      visit start_path
    end

    it 'has link to log in' do
      within '#header-nav' do
        click_link 'Log In'
      end
      expect(page.has_current_path?(new_user_session_path)).to be true
    end

    it 'has a link to sign up' do
      within '#header-nav' do
        click_link 'Sign Up'
      end
      expect(page.has_current_path?(new_user_registration_path)).to be true
    end
  end

  context 'when user is logged in' do
    before do
      driven_by(:selenium)
      sign_in user
      visit start_path
    end

    it 'has a link to edit user profile', browser: true do
      click_button user.email
      click_link 'Account Settings'
      expect(page.has_current_path?(edit_user_registration_path)).to be true
    end

    it 'has a link to log out', browser: true do
      click_button user.email
      click_button 'Log Out'
      expect(page.find('#header-nav').has_link?('Log In')).to be true
    end

    it 'has link to create event that works' do
      click_link 'Create an event'
      expect(page.has_current_path?(new_event_path)).to be true
    end
  end
end
