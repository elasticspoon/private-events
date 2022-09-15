require 'rails_helper'

RSpec.shared_examples 'new event page' do
  describe 'page contents' do
    before do
      driven_by(:selenium)
      sign_in user
      visit start_path
    end

    it 'has a link to home' do
      click_link 'Home'
      expect(page.has_current_path?(root_path)).to be true
    end

    it 'has a link to logout' do
      click_button user.name
      click_link_or_button 'Log out'
      expect(page.find('#header-nav').has_link?('Log In')).to be true
    end

    it 'has a link to edit account' do
      click_button user.name
      click_link 'Account Settings'
      expect(page.has_current_path?(edit_user_registration_path)).to be true
    end

    it 'has a button to save event' do
      expect(page.has_button?('Save & Continue')).to be true
    end

    it 'has a button do discard changes' do
      expect(page.has_button?('Discard')).to be true
    end
  end

  describe 'page functionality' do
    before do
      driven_by(:selenium)
      sign_in user
      visit start_path
    end

    context 'when given valid input' do
      let(:new_event) { build_stubbed(:event) }

      it 'discard resets the form' do
        inital_contents = page.find('#event_name').value
        fill_in 'event_name', with: 'Some random text', fill_options: { clear: :backspace }
        click_button 'Discard'
        expect(page.find('#event_name').value).to eq(inital_contents)
      end
    end

    context 'when given invalid input' do
      it 'display errors' do
        fill_in 'event_name', with: ''
        click_button 'Save & Continue'
        expect(page.has_css?('.field-error')).to be true
      end
    end
  end
end

RSpec.describe 'Events::NewOrEdits', type: :system do
  before { driven_by(:rack_test) }

  before(:each, browser: true) { driven_by(:selenium) }

  let!(:user) { create(:user) }
  let(:event) { create(:event, creator: user) }
  let(:new_event) { build_stubbed(:event) }

  describe 'Events New page' do
    describe 'page contents' do
      include_examples 'new event page' do
        let(:start_path) { new_event_path }
      end
    end

    describe 'page functionality' do
      before do
        sign_in user
        visit new_event_path
      end

      it 'save and continue saves the event' do
        input_event_vals(new_event)
        click_button 'Save & Continue'
        expect(page.has_current_path?(event_path(Event.last))).to be true
      end

      it 'event has correct attributes' do
        input_event_vals(new_event)
        click_button 'Save & Continue'
        expect(Event.last.name).to eq(new_event.name)
      end
    end
  end

  describe 'Events Edit page' do
    describe 'page contents' do
      include_examples 'new event page' do
        let(:start_path) { edit_event_path(event) }
      end

      it 'has a link to delete event' do
        sign_in user
        visit edit_event_path(event)
        expect(page.has_button?('Delete Event')).to be true
      end
    end

    describe 'page functionality' do
      before do
        sign_in user
        visit edit_event_path(event)
      end

      it 'save and continue updates the event' do
        fill_in 'event_name', with: 'Some random text', fill_options: { clear: :backspace }
        click_button 'Save & Continue'
        expect(Event.find(event.id).name).to eq('Some random text')
      end

      it 'deletes an event' do
        click_button 'Delete Event'
        expect(Event.find_by(id: event.id).nil?).to be true
      end
    end
  end

  def input_event_vals(event)
    fill_in 'event_name', with: event.name
    fill_in 'event_desc', with: event.desc
    fill_in 'event_location', with: event.location
    fill_in 'event_date', with: event.date
    find_by_id("event_event_privacy_#{event.event_privacy}").click
    find_by_id("event_display_privacy_#{event.display_privacy}").click
    find_by_id("event_attendee_privacy_#{event.attendee_privacy}").click
  end
end
