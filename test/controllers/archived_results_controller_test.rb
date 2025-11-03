require "test_helper"

class ArchivedResultsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get archived_results_create_url
    assert_response :success
  end
end
