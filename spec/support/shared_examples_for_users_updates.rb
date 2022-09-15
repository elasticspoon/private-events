require 'rails_helper'

RSpec.shared_examples 'users updates' do
  before do
    driven_by(:selenium)
    sign_in user
    visit start_path
  end

  it 'has link to edit account' do
    click_button user.email
    click_link 'Account Settings'
    expect(page.has_current_path?(edit_user_registration_path)).to be true
  end

  it 'has a link to edit password' do
    click_button('Account', match: :first)
    click_link 'Password'
    expect(page.has_current_path?(users_edit_update_password_path)).to be true
  end

  it 'has a link to home' do
    click_link 'Home'
    expect(page.has_current_path?(root_path)).to be true
  end

  it 'has a link to logout' do
    click_button user.email
    click_link_or_button 'Log Out'
    expect(page.find('#header-nav').has_link?('Log In')).to be true
  end
end
