require 'rails_helper'

RSpec.describe 'Events::Indices', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  let(:user) { create(:user) }

  describe 'Events Index page' do
    it 'has link to create event' do
      visit events_path
      expect(page.has_link?('Create an event')).to be true
    end

    it 'has link to events index' do
      visit events_path
      click_link 'Home'
      expect(page.has_current_path?(root_path)).to be true
    end

    context 'when user is not logged in' do
      before { visit events_path }

      it 'has link to log in' do
        click_link 'Log In'
        expect(page.has_current_path?(new_user_session_path)).to be true
      end

      it 'has link to sign up' do
        click_link 'Sign Up'
        expect(page.has_current_path?(new_user_registration_path)).to be true
      end
    end

    context 'when user is logged in', browser: true do
      before do
        sign_in user
        visit events_path
      end

      it 'has a link to edit user profile' do
        click_button user.email
        click_link 'Account Settings'
        expect(page.has_current_path?(edit_user_registration_path)).to be true
      end

      it 'is reachable from the index page' do
        click_button user.email
        click_button 'Log Out'
        expect(page.find('#header-nav').has_link?('Log In')).to be true
      end
    end
  end

  describe 'Events shown on index' do
    let(:user) { create(:user, name: 'TestUser', username: 'TestUserName') }
    let(:event) { create(:event, creator: user, date:, name: 'Test Event') }
    let(:date) { DateTime.tomorrow }

    before do
      event
      visit events_path
    end

    it 'has link to event' do
      click_link(event.name, match: :first)
      expect(page.has_current_path?(event_path(event))).to be true
    end

    it 'has link to creator', browser: true do
      click_link(event.creator.username.titleize, match: :first)
      expect(page.has_current_path?(user_path(event.creator))).to be true
    end

    it 'has the event shown' do
      expect(page.has_content?(event.name)).to be true
    end

    it 'has the creator shown', browser: true do
      expect(page.has_content?(event.creator.username.titleize)).to be true
    end

    context 'when event is in the past' do
      let(:date) { DateTime.yesterday }

      it 'is not shown' do
        expect(page.has_content?(event.name)).to be false
      end
    end
  end
end
