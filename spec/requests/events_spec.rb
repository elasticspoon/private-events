require 'rails_helper'
RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request # to sign_in user by Devise
end

RSpec.describe 'Events', type: :request do
  let(:priv_set) { 'public' }
  let(:creator_id) { created_user.id }
  let(:user_params) { { email: 'a@gmail.com', username: 'asaada', password: '123456', name: 'asds' } }
  let(:event_params) do
    { date: DateTime.now, location: 'asdasd', event_privacy: priv_set, desc: 'asdasd', name: 'asdasd',
      display_privacy: priv_set, attendee_privacy: priv_set, creator_id: creator_id }
  end
  let(:created_user) { User.create(user_params) }
  let(:created_event) do
    Event.create(event_params)
  end
  describe '#index' do
    it do
      get root_path
      expect(response).to have_http_status(200)
    end
    it do
      get events_path
      expect(response).to have_http_status(200)
    end
  end
  describe '#show' do
    context 'when event view is public' do
      it do
        get event_path(created_event)
        expect(response).to have_http_status(200)
      end
    end
    context 'when event view is private' do
      let(:priv_set) { 'private' }
      it 'responds with 302 when not logged in' do
        get event_path(created_event)
        expect(response).to redirect_to(root_path)
      end
      it 'responds with 302 when logged in without perms' do
        user = created_user
        event = created_event
        user.user_event_permissions.destroy_all
        sign_in user
        get event_path(event)
        expect(response).to have_http_status(302)
      end
      it 'shows a flash alert when logged in without perms' do
        user = created_user
        event = created_event
        user.user_event_permissions.destroy_all
        sign_in user
        get event_path(event)
        expect(flash.alert).to_not be_nil
      end
      it 'responds with 200 when logged in with perms' do
        sign_in created_user
        get event_path(created_event)
        expect(response).to have_http_status(200)
      end
    end
    context 'when event view is protected' do
      let(:priv_set) { 'protected' }
      it 'responsd with 302 when not logged in' do
        get event_path(created_event)
        expect(response).to have_http_status(302)
      end
      it 'show flash alert when not logged in' do
        get event_path(created_event)
        expect(flash.alert).to_not be_nil
      end
      it 'responsd with 200 when logged in' do
        sign_in created_user
        get event_path(created_event)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe '#new' do
    it do
      get new_event_path
      expect(response).to redirect_to(new_user_session_path)
    end
    it do
      sign_in created_user
      get new_event_path
      expect(response).to have_http_status(200)
    end
  end

  describe '#create' do
    it 'redirects to new event when event created' do
      sign_in created_user
      post events_path, params: { 'event' => event_params }
      expect(response).to redirect_to(event_path(Event.last))
    end
    it 'shows notice when event created' do
      sign_in created_user
      post events_path, params: { 'event' => event_params }
      expect(flash.notice).to_not be_nil
    end
    context 'when event params are bad' do
      let(:priv_set) { 'bad' }
      it do
        sign_in created_user
        post events_path, params: { 'event' => event_params }
        expect(response).to have_http_status(422)
      end
    end
    it 'redirects to log in page when not logged in and attempt to create event' do
      created_user
      post events_path, params: { 'event' => event_params }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe '#edit' do
    it do
      created_user
      get edit_event_path(created_event)
      expect(response).to redirect_to(new_user_session_path)
    end
    context 'when logged in' do
      before(:each) do
        @user = created_user
        @event = created_event
        sign_in @user
      end
      it 'when no owner perm it redirects' do
        @user.user_event_permissions.destroy_all
        get edit_event_path(@event)
        expect(response).to have_http_status(302)
      end
      it 'when no owner perm it sends alert' do
        @user.user_event_permissions.destroy_all
        get edit_event_path(@event)
        expect(flash.alert).to_not be_nil
      end
      it 'when has owner perm is returns 200 response' do
        get edit_event_path(@event)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe '#update' do
    before(:each) do
      @user = created_user
      @event = created_event
      sign_in @user
    end
    it 'redirects to log in page when not logged in and attempt to update' do
      sign_out @user
      put event_path(@event), params: { 'event' => event_params }
      expect(response).to redirect_to(new_user_session_path)
    end
    context 'user has no owner perm' do
      before(:each) { @user.user_event_permissions.destroy_all }
      it 'redirects to root if user does not have edit perms' do
        put event_path(@event), params: { 'event' => event_params }
        expect(response).to redirect_to(root_path)
      end
      it 'flash alert if user does not have edit perms' do
        put event_path(@event), params: { 'event' => event_params }
        expect(flash.alert).to_not be_nil
      end
    end
    context 'user has owner perm' do
      it 'shows notice when event updated' do
        put event_path(@event), params: { 'event' => event_params }
        expect(flash.notice).to_not be_nil
      end
      it do
        event_hash = event_params
        event_hash[:display_privacy] = 'protected'
        expect do
          put event_path(@event), params: { 'event' => event_hash }
        end.to change { @event.reload.display_privacy }.from('public').to('protected')
      end
      context 'when event params are bad' do
        it do
          event_hash = event_params
          event_hash[:display_privacy] = 'bad value'
          put event_path(@event), params: { 'event' => event_hash }
          expect(response).to have_http_status(422)
        end
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      @user = created_user
      @event = created_event
      sign_in @user
    end
    context 'when not logged in' do
      before(:each) { sign_out @user }
      it 'redirects to log in page' do
        delete event_path(@event)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when logged in' do
      context 'when user has no owner perm' do
        before(:each) { @user.user_event_permissions.destroy_all }
        it 'redirects to root' do
          delete event_path(@event)
          expect(response).to redirect_to(root_path)
        end
        it 'flash alert' do
          delete event_path(@event)
          expect(flash.alert).to_not be_nil
        end
      end
      context 'when user has owner perm' do
        it 'redirects to event page' do
          delete event_path(@event)
          expect(response).to redirect_to(root_path)
        end
        it 'shows notice' do
          delete event_path(@event)
          expect(flash.notice).to_not be_nil
        end
        it 'deletes event' do
          expect do
            delete event_path(@event)
          end.to change { Event.count }.by(-1)
        end
      end
    end
  end
end
