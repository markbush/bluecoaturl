require File.dirname(__FILE__) + '/../test_helper'
require 'url_controller'

# Re-raise errors caught by the controller.
class UrlController; def rescue_action(e) raise e end; end

class UrlControllerTest < Test::Unit::TestCase
  fixtures :webaddresses

  def setup
    @controller = UrlController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = webaddresses(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:webaddresses)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:webaddress)
    assert assigns(:webaddress).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:webaddress)
  end

  def test_create
    num_webaddresses = Webaddress.count

    post :create, :webaddress => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_webaddresses + 1, Webaddress.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:webaddress)
    assert assigns(:webaddress).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Webaddress.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Webaddress.find(@first_id)
    }
  end
end
