# frozen_string_literal: true

require 'rails_helper'
RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request # to sign_in user by Devise
end

RSpec.describe 'Events', type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  describe 'Set Up Tests' do
    it 'starts with 0 events' do
      expect(Event.count).to eq(0)
    end

    it 'starts with 0 users' do
      expect(User.count).to eq(0)
    end
  end

  # events#index
  describe 'GET /events' do
    it 'root path should return valid status' do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it 'root path should render index' do
      get root_path
      expect(response).to render_template(:index)
    end

    it 'events index should return valid status' do
      get events_path
      expect(response).to have_http_status(:ok)
    end

    it 'events path should render index' do
      get events_path
      expect(response).to render_template(:index)
    end
  end

  # events#show
  describe 'GET /event/:id' do
    context 'when event view is public' do
      it 'responds with valid status' do
        get event_path(event)
        expect(response).to have_http_status(:ok)
      end

      it 'renders show action' do
        get event_path(event)
        expect(response).to render_template(:show)
      end
    end

    context 'when event display is private' do
      let(:event) { create(:event, display_privacy: 'private') }

      it 'sends a flash alert' do
        get event_path(event)
        expect(flash.alert).to eq('You do not have permission to view that page.')
      end

      it 'redirects to root path when not logged in' do
        get event_path(event)
        expect(response).to redirect_to(root_path)
      end

      it 'responds with 302 when logged in without perms' do
        sign_in user
        get event_path(event)
        expect(response).to redirect_to(root_path)
      end

      it 'shows a flash alert when logged in without perms' do
        sign_in user
        get event_path(event)
        expect(flash.alert).to eq('You do not have permission to view that page.')
      end

      it 'responds with 200 when logged in with perms' do
        sign_in user
        get event_path(create(:event, display_privacy: 'private', creator: user))
        expect(response).to have_http_status(:ok)
      end

      it 'renders show action when logged in with perms' do
        sign_in user
        get event_path(create(:event, display_privacy: 'private', creator: user))
        expect(response).to render_template(:show)
      end
    end

    context 'when event view is protected' do
      let(:event) { create(:event, display_privacy: 'protected') }

      it 'responsd with 302 when not logged in' do
        get event_path(event)
        expect(response).to have_http_status(:found)
      end

      it 'redirects to root path when not logged in' do
        get event_path(event)
        expect(response).to redirect_to(root_path)
      end

      it 'show flash alert when not logged in' do
        get event_path(event)
        expect(flash.alert).to eq('You do not have permission to view that page.')
      end

      it 'responds with 200 when logged in' do
        sign_in user
        get event_path(event)
        expect(response).to have_http_status(:ok)
      end

      it 'responds with show action when logged in' do
        sign_in user
        get event_path(event)
        expect(response).to render_template(:show)
      end
    end
  end

  # events#new
  describe 'GET /events/new' do
    it 'redirects to login path if not logged in' do
      get new_event_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'responds with 200 when logged in' do
      sign_in user
      get new_event_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders new action when logged in' do
      sign_in user
      get new_event_path
      expect(response).to render_template(:new)
    end
  end

  # events#create
  describe 'POST /events' do
    it 'redirects to login path if not logged in' do
      post events_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to new event when event created' do
      sign_in user
      post events_path, params: { 'event' => attributes_for(:event) }
      expect(response).to redirect_to(event_path(Event.last))
    end

    it 'creates an event when logged in' do
      sign_in user
      post events_path, params: { 'event' => attributes_for(:event) }
      expect(Event.count).to eq(1)
    end

    it 'shows notice when event created' do
      sign_in user
      post events_path, params: { 'event' => attributes_for(:event) }
      expect(flash.notice).to match(/Event.*created.*/)
    end

    it 'returns 422 status if given params are invalid' do
      sign_in user
      post events_path, params: { 'event' => { bad: :value } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'renders new if given params are invalid' do
      sign_in user
      post events_path, params: { 'event' => { bad: :value } }
      expect(response).to render_template(:new)
    end
  end

  # events#edit
  describe 'GET /events/:id/edit' do
    it 'redirects to log in page if attempting to edit an event and not logged in' do
      get edit_event_path(event)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'logged in user does not have ownership of event' do
      curr_user = create(:user)
      curr_event = event
      expect(curr_event.creator).not_to eq(curr_user)
    end

    it 'when logged in but no owner perm it redirects to root' do
      sign_in user
      get edit_event_path(event)
      expect(response).to redirect_to(root_path)
    end

    it 'when logged in but no owner perm shows an alert' do
      sign_in user
      get edit_event_path(event)
      expect(flash.alert).to match(/not have permission/)
    end

    # TODO: Fix, issues with radio_button event_privacy
    it 'when has owner perm it returns 200 response', skip: 'Skipping: has issues with radio buttons' do
      event = create(:event, creator: user)
      sign_in user
      get edit_event_path(event)
      expect(response).to have_http_status(:ok)
    end

    it 'when has owner perm it renders action :edit', skip: 'Skipping: has issues with radio buttons' do
      event = create(:event, creator: user)
      sign_in user
      get edit_event_path(event)
      expect(response).to render_template(:edit)
    end
  end

  # events#update
  describe 'PUT /events/:id' do
    let(:event) { create(:event, creator: user) }

    it 'redirects to log in page when not logged in and attempt to update' do
      put event_path(event)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to root if user does not have owner perm' do
      sign_in create(:user)
      put event_path(event)
      expect(response).to redirect_to(root_path)
    end

    it 'flash alert if user does not have edit perms' do
      sign_in create(:user)
      put event_path(event)
      expect(flash.alert).to match(/not have permission/)
    end

    it 'shows notice of update if params valid' do
      sign_in user
      put event_path(event), params: { 'event' => attributes_for(:event) }
      expect(flash.notice).to match(/Event.*updated.*/)
    end

    it 'redirects to event page if updated' do
      sign_in user
      put event_path(event), params: { 'event' => attributes_for(:event) }
      expect(response).to redirect_to(event_path(event))
    end

    it 'returns 422 if params are invalid',
       skip: 'Skipped becuase not sure how to test correctly' do
      sign_in user
      event
      put event_path(event), params: { 'event' => { bad: :value } }
      expect(response).to redirect_to(root_url)
    end

    it 'render edit action if params are invalid',
       skip: 'Skipped becuase not sure how to test correctly' do
      sign_in user
      get event_path(event)
      put event_path(event), params: { 'event' => { bad: :value } }
      expect(response).to render_template(:edit)
    end

    it 'updates the event' do
      sign_in user
      expect do
        put event_path(event), params: { 'event' => attributes_for(:event) }
      end.to change(Event, :last)
    end
  end

  # events#destroy
  describe 'DELETE /events/:id' do
    let(:event) { create(:event, creator: user) }

    it 'redirects to log in page if not logged in' do
      delete event_path(event)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to root if user has no owner perm' do
      sign_in create(:user)
      delete event_path(event)
      expect(response).to redirect_to(root_path)
    end

    it 'shows alert flash if users has no owner perm' do
      sign_in create(:user)
      delete event_path(event)
      expect(flash.alert).to match(/not have permission/)
    end

    it 'redirects to root path if user has owner perm' do
      sign_in user
      delete event_path(event)
      expect(response).to redirect_to(root_path)
    end

    it 'shows success notice if user has owner perm' do
      sign_in user
      delete event_path(event)
      expect(flash.notice).to match(/Event.*deleted.*/)
    end

    it 'deletes event if user has owner perm' do
      event
      sign_in user
      expect { delete event_path(event) }
        .to change(Event, :count).from(1).to(0)
    end
  end
end
