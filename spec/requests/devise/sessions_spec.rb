require 'rails_helper'

RSpec.describe 'Devise::Sessions', type: :request do
  # devise/sessions#new
  describe 'GET /users/sign_in' do
    context 'when not logged in' do
      it 'returns a valid status' do
        get new_user_session_path
        expect(response.ok?).to be(true)
      end

      it 'renders the new template' do
        get new_user_session_path
        expect(response).to render_template(:new)
      end

      context 'when logged in' do
        it 'redirects to root' do
          sign_in create(:user)
          get new_user_session_path
          expect(response).to redirect_to(root_path)
        end
      end
    end

    # devise/sessions#create
    describe 'POST /users/sign_in' do
      context 'when not logged in' do
        it 'redirects to root if valid' do
          user = create(:user)
          post user_session_path, params: { user: { email: user.email, password: user.password } }
          expect(response).to redirect_to(root_path)
        end

        it 'renders new sessions template' do
          post user_session_path, params: { user: { email: 'invalid', password: 'invalid' } }
          expect(response).to render_template(:new)
        end

        it 'shows a flash alert if invalid' do
          post user_session_path, params: { user: { email: 'invalid', password: 'invalid' } }
          expect(flash.alert).to match(/Invalid Email or password/)
        end

        it 'shows a flash notice if valid' do
          user = create(:user)
          post user_session_path, params: { user: { email: user.email, password: user.password } }
          expect(flash.notice).to match(/Signed in successfully/)
        end
      end

      context 'when logged in' do
        it 'redirects to root' do
          sign_in create(:user)
          post user_session_path
          expect(response).to redirect_to(root_path)
        end
      end
    end

    # devise/sessions#destroy
    describe 'DELETE /users/sign_out' do
      context 'when not logged in' do
        it 'redirects to sign in' do
          delete destroy_user_session_path
          expect(response).to redirect_to(root_path)
        end
      end

      context 'when logged in' do
        before { sign_in create(:user) }

        it 'redirects to root' do
          delete destroy_user_session_path
          expect(response).to redirect_to(root_path)
        end

        it 'shows a flash notice' do
          delete destroy_user_session_path
          expect(flash[:notice]).to match(/Signed out successfully/)
        end
      end
    end
  end
end
