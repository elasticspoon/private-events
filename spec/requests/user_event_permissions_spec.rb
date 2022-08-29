require 'rails_helper'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request # to sign_in user by Devise
end

RSpec.describe 'UserEventPermissions', type: :request do
  let(:priv_set) { 'public' }
  let(:creator_id) { created_user.id }
  let(:user_params) { { email: 'a@gmail.com', username: 'asaada', password: '123456', name: 'asds' } }
  let(:event_params) do
    { date: DateTime.now, location: 'asdasd', event_privacy: priv_set, desc: 'asdasd', name: 'asdasd',
      display_privacy: priv_set, attendee_privacy: priv_set, creator_id: }
  end
  let(:created_user) { User.create(user_params) }
  let(:created_event) { Event.create(event_params) }
  let(:permission_type) { 'attend' }
  let(:identifier) { { user_id: @user.id } }
  let(:permission_params) do
    { user_event_permissions:
       { event_id: @event.id,
         identifier:, permission_type: } }
  end

  describe '#create' do
    before(:each) do
      @user = created_user
      @event = created_event
      sign_in @user
    end
    context 'when user is not logged in' do
      it do
        sign_out @user
        post user_event_permissions_path, params: permission_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when user is logged in' do
      let(:identifier) { {} }
      context 'when user attempts to create attend permission' do
        let(:permission_type) { 'attend' }
        it do
          post user_event_permissions_path, params: permission_params
          expect(response).to redirect_to(event_path(@event))
        end
        it do
          post user_event_permissions_path, params: permission_params
          expect(flash.notice).to eq('Successfully created permission.')
        end
        it 'fails if user already has permission ' do
          @user.user_event_permissions.create(event_id: @event.id, permission_type: 'attend')
          post user_event_permissions_path, params: permission_params
          expect(flash.alert).to eq('User already has permission.')
        end
      end
      context 'when user attempts to create moderate permission' do
        let(:permission_type) { 'moderate' }
        it do
          post user_event_permissions_path, params: permission_params
          expect(response).to redirect_to(event_path(@event))
        end
        it do
          post user_event_permissions_path, params: permission_params
          expect(flash.notice).to eq('Successfully created permission.')
        end
        it 'fails without owner permission' do
          @user.user_event_permissions.destroy_all
          post user_event_permissions_path, params: permission_params
          expect(flash.alert).to eq('You do not have permission to perform this action.')
        end
      end
      context 'when identifier is email' do
        let(:identifier) { { email: user_params[:email] } }
        context 'when user attempts to create moderate permission' do
          let(:permission_type) { 'moderate' }
          it do
            post user_event_permissions_path, params: permission_params
            expect(response).to redirect_to(event_path(@event))
          end
          it do
            post user_event_permissions_path, params: permission_params
            expect(flash.notice).to eq('Successfully created permission.')
          end
          it 'fails without owner permission' do
            @user.user_event_permissions.destroy_all
            post user_event_permissions_path, params: permission_params
            expect(flash.alert).to eq('You do not have permission to perform this action.')
          end
        end
      end
      context 'when identifier is wrong' do
        let(:identifier) { { email: 'wrong' } }
        it do
          post user_event_permissions_path, params: permission_params
          expect(response).to redirect_to(root_path)
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
    context 'when user is not logged in' do
      it do
        sign_out @user
        delete user_event_permissions_path, params: permission_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when user is logged in' do
      context 'attend permission does not exist' do
        it do
          delete user_event_permissions_path, params: permission_params
          expect(response).to redirect_to(root_path)
        end
        it do
          delete user_event_permissions_path, params: permission_params
          expect(flash.alert).to eq('Permission does not exist.')
        end
      end
      context 'attend permission exists' do
        before(:each) do
          @user.user_event_permissions.create(event_id: @event.id, permission_type: 'attend')
        end
        it do
          delete user_event_permissions_path, params: permission_params
          expect(response).to have_http_status(302)
        end
        it do
          delete user_event_permissions_path, params: permission_params
          expect(flash.notice).to eq('Successfully destroyed permission.')
        end
      end
      context 'destroy moderator permission' do
        let(:permission_type) { 'moderate' }
        context 'user is not owner' do
          before(:each) do
            @user.user_event_permissions.destroy_all
            @user.user_event_permissions.create(event_id: @event.id, permission_type: 'moderate')
          end
          it do
            delete user_event_permissions_path, params: permission_params
            expect(response).to redirect_to(root_path)
          end
          it do
            delete user_event_permissions_path, params: permission_params
            expect(flash.alert).to eq('You do not have permission to perform this action.')
          end
        end
        context 'user is owner' do
          before(:each) do
            @user.user_event_permissions.create(event_id: @event.id, permission_type: 'moderate')
          end
          it do
            delete user_event_permissions_path, params: permission_params
            expect(response).to have_http_status(302)
          end
          it do
            delete user_event_permissions_path, params: permission_params
            expect(flash.notice).to eq('Successfully destroyed permission.')
          end
        end
      end
    end
  end
end
