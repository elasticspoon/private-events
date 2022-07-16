require 'rails_helper'

RSpec.describe UserEventPermission, type: :model do
  let(:mock_user) { instance_double(User, id: 1) }
  let(:mock_event) { instance_double(Event, id: 1) }
  let(:test_perm) { UserEventPermission.new }

  describe 'Validations' do
    subject { described_class.new }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:event_id) }
    it do
      is_expected.to validate_inclusion_of(:permission_type).in_array(UserEventPermission::PERMISSION_TYPES)
                                                            .with_message('is invalid.')
    end
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:event) }
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:event) }
  end

  # custom check to ensure uniqueness validation works
  describe 'Uniqueness Validations' do
    before(:each) do
      user = User.create(name: 'test', username: 'tester', password: 'tester', email: 'a@gmail.com')
      event = Event.create(name: 'test', desc: 'test', date: DateTime.now, location: 'test', creator_id: user.id,
                           event_privacy: 'public', display_privacy: 'public', attendee_privacy: 'public')
      @user_event_permission = UserEventPermission.create(user_id: user.id, event_id: event.id,
                                                          permission_type: 'attend')
      @second_user_event_permission = UserEventPermission.new(user_id: user.id, event_id: event.id)
    end
    context 'when creating the first user_event permission' do
      it { expect(@user_event_permission.errors).to be_empty }
      it { expect(@user_event_permission).not_to be_new_record }
    end

    context 'when creating a second user_event permission with the same user_id and event_id' do
      context 'when permission_type is different' do
        it do
          @second_user_event_permission.permission_type = 'moderate'
          expect(@second_user_event_permission.save).to be true
        end

        context 'when first permission is attend and second is accept_invite' do
          it do
            @second_user_event_permission.permission_type = 'accept_invite'
            expect(@second_user_event_permission.save).to be false
          end
        end

        context 'when first permission is accept_invite and second is attend' do
          it do
            @user_event_permission.update(permission_type: 'accept_invite')
            @second_user_event_permission.permission_type = 'attend'
            expect(@second_user_event_permission.save).to be false
          end
        end
      end

      context 'when permission_type is the same' do
        it do
          @second_user_event_permission.permission_type = 'attend'
          expect(@second_user_event_permission.save).to be false
        end
      end
    end
  end

  describe '#save_valid_permission' do
    before(:each) do
      @test_perm = test_perm
      allow(@test_perm).to receive(:user).and_return(mock_user)
      allow(@test_perm).to receive(:event).and_return(mock_event)
    end
    it 'should return :alert if errors not empty' do
      allow(@test_perm).to receive(:errors).and_return([1])
      expect(@test_perm.save_valid_permission).to eq(:alert)
    end
    it 'should return UserEventPermission if errors empty' do
      allow(@test_perm).to receive(:errors).and_return([])
      allow(@test_perm).to receive(:save).and_return(true)
      expect(@test_perm.save_valid_permission).to eq(@test_perm)
    end
    it 'should call save on the UserEventPermission' do
      allow(@test_perm).to receive(:errors).and_return([])
      expect(@test_perm).to receive(:save)
      @test_perm.save_valid_permission
    end
  end

  # test for destroy valid permission
  describe '#destroy_valid_permission' do
    before(:each) do
      @test_perm = test_perm
      allow(@test_perm).to receive(:user).and_return(mock_user)
      allow(@test_perm).to receive(:event).and_return(mock_event)
    end
    it 'should return :alert if errors not empty' do
      allow(@test_perm).to receive(:errors).and_return([1])
      expect(@test_perm.destroy_valid_permission).to eq(:alert)
    end
    it 'should return :notice if errors empty' do
      allow(@test_perm).to receive(:errors).and_return([])
      allow(@test_perm).to receive(:destroy).and_return(true)
      expect(@test_perm.destroy_valid_permission).to eq(:notice)
    end
    it 'should call destroy on the UserEventPermission' do
      allow(@test_perm).to receive(:errors).and_return([])
      expect(@test_perm).to receive(:destroy)
      @test_perm.destroy_valid_permission
    end
  end

  # test for validating identifier in a params object
  describe '#self.validate_identifier' do
    context 'when identifier is missing' do
      it do
        test_params = ActionController::Parameters.new(
          user_id: 1, event_id: 1
        )
        expect do
          UserEventPermission.validate_identifier(test_params)
        end.to raise_error ActionController::ParameterMissing
      end
    end
    context 'when identifier is present' do
      before(:each) do
        @test_params = ActionController::Parameters.new(
          user_id: 1, event_id: 1, identifier: test_identifier
        )
      end
      context 'when only 1 identifier is present' do
        context 'user_id' do
          let(:test_identifier) { { 'user_id' => 1 } }
          it { expect(UserEventPermission.validate_identifier(@test_params).to_h).to eq(test_identifier) }
        end
        context 'email' do
          let(:test_identifier) { { 'email' => 1 } }
          it { expect(UserEventPermission.validate_identifier(@test_params).to_h).to eq(test_identifier) }
        end
      end
      context 'when multiple identifiers are present' do
        let(:test_identifier) { { user_id: 1, email: 1 } }
        it do
          expect { UserEventPermission.validate_identifier(@test_params) }.to raise_error 'Invalid identifier'
        end
      end
    end
  end

  # test function for finding the identifier id
  # assumes that given params are a hash
  # returns user_id if only user_id is present
  # calls find_by on User if only email is present
  # raises error if both user_id and email are present or neither is present
  describe '#self.identifier_id' do
    context 'when only user_id is present' do
      it do
        test_params = ActionController::Parameters.new(user_id: 1)
        expect(UserEventPermission.identifier_id(test_params)).to eq(1)
      end
    end
    context 'when only email is present' do
      it do
        test_params = ActionController::Parameters.new(email: 1)
        allow(User).to receive(:find_by).and_return(instance_double(User, id: 1))
        expect(UserEventPermission.identifier_id(test_params)).to eq(1)
      end
    end
    context 'when both user_id and email are present' do
      it do
        test_params = ActionController::Parameters.new(user_id: 1, email: 1)
        expect do
          UserEventPermission.identifier_id(test_params)
        end.to raise_error RuntimeError
      end
    end
    context 'when neither user_id nor email is present' do
      it do
        test_params = ActionController::Parameters.new
        expect { UserEventPermission.identifier_id(test_params) }.to raise_error RuntimeError
      end
    end
  end

  # test invite target id
  describe '#self.invite_target_id' do
    context 'when identifier is not present' do
      it 'return current_user_id' do
        test_params = ActionController::Parameters.new
        current_user_id = 1
        expect(UserEventPermission.invite_target_id(test_params, current_user_id)).to eq(current_user_id)
      end
    end
    context 'when identifier is present' do
      before(:each) do
        @test_params = ActionController::Parameters.new(identifier: 1)
        allow(UserEventPermission).to receive(:validate_identifier).and_return(nil)
        allow(UserEventPermission).to receive(:identifier_id).and_return('hello')
      end
      it 'call validate_identifier and identifier_id' do
        expect(UserEventPermission).to receive(:identifier_id).with(nil)
        UserEventPermission.invite_target_id(@test_params, 1)
      end
      it 'call identifier_id' do
        expect(UserEventPermission).to receive(:validate_identifier).with(@test_params)
        UserEventPermission.invite_target_id(@test_params, 1)
      end

      it 'return identifier_id' do
        expect(UserEventPermission.invite_target_id(@test_params, 1)).to eq('hello')
      end
    end
  end

  # generate permission response
  # input:
  # - boolean value has_perms
  # - symbol action (:create, :destroy)
  # if instance of permission is valid and has perms, return sucess response
  # if doesnt have perms or invalid
  #   - if has errors then return errors
  #  - if doesnt have errors then return text
  # raise error if neither
  describe '#self.generate_permission_response' do
    before(:each) do
      @test_perm = test_perm
      allow(@test_perm).to receive(:errors).and_return(errors)
      allow(@test_perm).to receive(:valid?).and_return(valid)
    end
    context 'when has_perms is true' do
      context 'when valid? is true' do
        let(:valid) { true }
        let(:errors) { "doesn't matter" }
        it { expect(@test_perm.generate_permission_response(true, :create)).to include 'Success' }
      end
      context 'when valid? is false (making errors not empty)' do
        let(:valid) { false }
        let(:errors) { double('Errors', empty?: false, full_messages: ['bad']) }
        it { expect(@test_perm.generate_permission_response(true, :create)).to eq('bad') }
      end
    end
    context 'when has_perms is false' do
      context 'when valid? is true' do
        let(:valid) { true }
        let(:errors) { [] } # empty errors
        it do
          expect(@test_perm.generate_permission_response(false, :create))
            .to include('You do not have permission to perform this action')
        end
      end
      context 'when valid? is false (making errors not empty)' do
        let(:valid) { false }
        let(:errors) { double('Errors', empty?: false, full_messages: ['bad']) }
        it { expect(@test_perm.generate_permission_response(false, :create)).to eq('bad') }
      end
    end
  end
end
