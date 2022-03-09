class DocumentPolicy < ApplicationPolicy
  attr_reader :user, :document

  def initialize(user, document)
    @user = user
    @document = document
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
