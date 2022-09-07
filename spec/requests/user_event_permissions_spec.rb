# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'UserEventPermissions', type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event, creator: user) }
  let(:permission) { create(:permission, user:, event:) }
  let(:params) do
    { user_event_permissions: { event_id: event.id,
                                permission_type: 'attend',
                                identifier: { user_id: user.id } } }
  end

  # user_event_permissions#create
  describe 'POST /user_event_permissions' do
    it 'redirects to log in path if attempt to create permission without being signed in' do
      post user_event_permissions_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects if invalid params' do
      sign_in user
      post user_event_permissions_path, params: { user_event_permissions: { bad: :val } }
      expect(response).to have_http_status(:found)
    end

    it 'alerts if invalid params' do
      sign_in user
      post user_event_permissions_path, params: { user_event_permissions: { bad: :val } }
      expect(flash.alert).to match(/invalid/)
    end

    it 'accepts user_id as identifier' do
      sign_in user
      post user_event_permissions_path, params: params
      expect(response).to have_http_status(:found)
    end

    it 'accepts email as identifier' do
      sign_in user
      params[:user_event_permissions][:identifier] = { email: user.email }
      post user_event_permissions_path, params: params
      expect(response).to have_http_status(:found)
    end

    it 'redirects to event path if valid params' do
      sign_in user
      post user_event_permissions_path, params: params
      expect(response).to redirect_to(event_path(event))
    end

    it 'sends notice if valid params' do
      sign_in user
      post user_event_permissions_path, params: params
      expect(flash.notice).to match(/Success/)
    end

    it 'creates permission if valid params' do
      event
      sign_in user
      expect do
        post user_event_permissions_path, params:
      end.to change(UserEventPermission, :count).from(1).to(2)
    end
  end

  # user_event_permissions#destroy
  describe 'DELETE /user_event_permissions' do
    it 'redirects to log in path if not logged in' do
      delete user_event_permissions_path, params: params
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'sends alert if not logged in' do
      delete user_event_permissions_path, params: params
      expect(flash.alert).to match(/sign in/)
    end

    it 'redirects if invalid params' do
      sign_in user
      delete user_event_permissions_path, params: { user_event_permissions: { bad: :val } }
      expect(response).to have_http_status(:found)
    end

    it 'sends alert if invalid params' do
      sign_in user
      delete user_event_permissions_path, params: { user_event_permissions: { bad: :val } }
      expect(flash.alert).to match(/Permission/)
    end

    it 'redirects to root path if valid params' do
      sign_in user
      permission
      delete user_event_permissions_path, params: params
      expect(response).to redirect_to(root_path)
    end

    it 'sends notice if valid params' do
      sign_in user
      permission
      delete user_event_permissions_path, params: params
      expect(flash.notice).to match(/Success/)
    end

    it 'destroys permission if valid params' do
      sign_in user
      permission
      expect do
        delete user_event_permissions_path, params:
      end.to change(UserEventPermission, :count).from(2).to(1)
    end
  end
end
