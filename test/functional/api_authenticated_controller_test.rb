require 'test_helper'

class DummyController < ApiAuthenticatedController
  def index
    user = current_user.try(&:id)
    account = @account.try(&:id)
    application = @application.try(&:id)
    render text: "#{user}/#{account}/#{application}"
  end

  def guisso_request
    Guisso.enabled? && "guisso_request"
  end
end

class DummyControllerTest < ActionController::TestCase
  def setup
    Rails.application.routes.draw do
      match '/' => "dummy#index"
    end
    @account = Account.make :password => 'secret'
    @application = Application.make :account => @account, :password => 'secret'
    Guisso.stubs(:enabled?).returns(false)
  end

  def teardown
    Guisso.unstub(:enabled?)
    Rails.application.reload_routes!
  end

  test "forbid access without authentication" do
    get :index
    assert_response :unauthorized
  end

  test "ignore session" do
    user = User.make
    sign_in user
    get :index
    assert_response :unauthorized
  end

  test "login with basic credentials" do
    @request.env['HTTP_AUTHORIZATION'] = http_auth("#{@account.name}/#{@application.name}", 'secret')
    get :index
    assert_response :ok
    assert_equal "/#{@account.id}/#{@application.id}", @response.body
  end

  test "login with OAuth" do
    Guisso.stubs(:enabled?).returns(true)
    user = User.make
    account = Account.make_unsaved(name: user.email)
    user.create_account account
    application = Application.make account: account, password: 'secret'
    token = {
      "user" => user.email,
      "expires_at" => "3016-08-23T15:11:21.000Z",
      "token_type" => "bearer",
      "client" => {
        "name" => application.name,
        "client_id" => "CBl1h6joPyisXkYCvgHz7g"
      }
    }
    AltoGuissoRails.stubs(:validate_oauth2_request).returns(token)

    get :index
    assert_response :ok
    assert_equal "#{user.id}//", @response.body
  end

  test "login with OAuth and account creates the application" do
    Guisso.stubs(:enabled?).returns(true)
    user = User.make
    account = Account.make_unsaved(name: "foo")
    user.create_account account
    token = {
      "user" => user.email,
      "expires_at" => "3016-08-23T15:11:21.000Z",
      "token_type" => "bearer",
      "client" => {
        "name" => "Client App",
        "client_id" => "CBl1h6joPyisXkYCvgHz7g"
      }
    }
    AltoGuissoRails.stubs(:validate_oauth2_request).returns(token)

    get :index, account: "foo"
    assert_response :ok
    application = account.applications.first
    assert_equal "Client App", application.name
    assert_equal "#{user.id}/#{account.id}/#{application.id}", @response.body
  end

  test "login with OAuth and invalid accounts forbid access" do
    Guisso.stubs(:enabled?).returns(true)
    user = User.make
    token = {
      "user" => user.email,
      "expires_at" => "3016-08-23T15:11:21.000Z",
      "token_type" => "bearer",
      "client" => {
        "name" => "Client App",
        "client_id" => "CBl1h6joPyisXkYCvgHz7g"
      }
    }
    AltoGuissoRails.stubs(:validate_oauth2_request).returns(token)

    get :index, account: "foo"
    assert_response :unauthorized
  end
end
