module ControllerMacros
  def login_user
    # Before each test, create and login the user
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in FactoryBot.create(:user)
    end
  end

  def login_admin
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:admin]
      sign_in FactoryBot.create(:user, :admin) # Using factory bot as an example
    end
  end
end
