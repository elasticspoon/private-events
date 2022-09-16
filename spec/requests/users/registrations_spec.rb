# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let(:permission) { create(:permission, user:, event:) }

  # users/registrations#close_account
  describe 'GET users/edit/close_account' do
    it 'redirects to sign in if not logged in' do
      get users_edit_close_account_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'responds with valid status if logged in' do
      sign_in user
      get users_edit_close_account_path
      expect(response.ok?).to be(true)
    end

    it 'renders close_account if logged in' do
      sign_in user
      get users_edit_close_account_path
      expect(response).to render_template(:close_account)
    end
  end

  # users/registrations#close_account_action
  describe 'POST users/edit/close_account' do
    it 'redirects to sign in if not logged in' do
      post users_edit_close_account_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects if close incorrect' do
      sign_in user
      post users_edit_close_account_path, params: { close: 'BAD', password: user.password }
      expect(response).to redirect_to(users_edit_close_account_path)
    end

    it 'redirects if password incorrect' do
      sign_in user
      post users_edit_close_account_path, params: { close: 'CLOSE', password: 'BAD' }
      expect(response).to redirect_to(users_edit_close_account_path)
    end

    it 'redirects to root if close and password correct' do
      sign_in user
      post users_edit_close_account_path, params: { close: 'CLOSE', password: user.password }
      expect(response).to redirect_to(root_path)
    end

    it 'deletes account if close and password correct' do
      sign_in user
      post users_edit_close_account_path, params: { close: 'CLOSE', password: user.password }
      expect(User.find_by(id: user.id).nil?).to be(true)
    end
  end

  # users/registrations#update_password
  describe 'GET users/edit/update_password' do
    it 'redirects to sign in if not logged in' do
      get users_edit_update_password_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'responds with valid status if logged in' do
      sign_in user
      get users_edit_update_password_path
      expect(response.ok?).to be true
    end

    it 'renders update_password if logged in' do
      sign_in user
      get users_edit_update_password_path
      expect(response).to render_template(:update_password)
    end
  end

  # users/registrations#new
  describe 'GET users/sign_up' do
    it 'responds with valid status' do
      get new_user_registration_path
      expect(response.ok?).to be(true)
    end

    it 'renders sign_up' do
      get new_user_registration_path
      expect(response).to render_template(:new)
    end
  end

  # users/registrations#create
  describe 'POST /users/sign_up or POST /users' do
    ['/users', '/users/sign_up'].each do |post_path|
      context "POST #{post_path}" do
        it 'renders new action if given email that is already in use' do
          user
          post post_path, params: { user: { email: user.email } }
          expect(response).to render_template(:new)
        end

        it 'renders :valid_email if given email that is not in use' do
          post post_path, params: { user: { email: 'some@email.com' } }
          expect(response).to render_template(:valid_email)
        end

        it 'renders :new action if not given an email' do
          post post_path, params: { user: { email: '' } }
          expect(response).to render_template(:new)
        end

        it 'redirects to created user valid params' do
          post post_path, params: { user: attributes_for(:user) }
          expect(response).to redirect_to(root_path)
        end

        it 'creates user if valid params' do
          expect do
            post post_path, params: { user: attributes_for(:user) }
          end.to change(User, :count).by(1)
        end
      end
    end
  end

  # users/registrations#update
  # or PATCH
  describe 'PUT /users' do
    before { sign_in user }

    it 'redirects to sign in if not logged in' do
      sign_out user
      put user_registration_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects edit user path if invalid params' do
      put user_registration_path
      expect(response).to redirect_to(edit_user_registration_path)
    end

    it 'updates user if given valid params' do
      expected_params = attributes_for(:user)
      put user_registration_path, params: { user: expected_params }
      found_params = User.last.attributes.values_at('email', 'name', 'username')
      expect(found_params).to eq(expected_params.values_at(:email, :name, :username))
    end

    it 'updates only a single param if given valid params' do
      expected_params = { email: 'new@email.com' }
      put user_registration_path, params: { user: expected_params }
      expect(User.last.email).to eq('new@email.com')
    end

    it 'redirects to user page if valid params' do
      put user_registration_path, params: { user: attributes_for(:user) }
      expect(response).to redirect_to(edit_user_registration_path)
    end
  end

  # users/registrations#destroy
  describe 'DELETE /users' do
    it 'does nothing when logged in' do
      sign_in user
      delete user_registration_path
      expect(User.find_by(id: user.id).nil?).to be(false)
    end

    it 'does nothing when not logged in' do
      delete user_registration_path
      expect(response.no_content?).to be true
    end
  end

  # users/registrations#edit
  describe 'GET /users/edit' do
    context 'when not logged in' do
      it 'redirects to sign in' do
        get edit_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in' do
      before { sign_in user }

      it 'responds with valid status' do
        get edit_user_registration_path
        expect(response.ok?).to be(true)
      end

      it 'renders edit' do
        get edit_user_registration_path
        expect(response).to render_template(:edit)
      end
    end
  end
end
