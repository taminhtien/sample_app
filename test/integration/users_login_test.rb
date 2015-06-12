require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  # This test is in order to control the emergence of the flash
  test "login with invalid information" do
  	# Visit login path
  	get login_path
  	# Verify that the new session renders properly
  	assert_template 'sessions/new'
	# Post to login path invalid params hash
  	post login_path, session: { email: "", password: "" }
  	# Verify that the new session gets re-render...
  	assert_template 'sessions/new'
  	# and the flash appears
  	assert_not flash.empty?
  	# Visit home page
  	get root_path
  	# Verify the flash doesn't appear
  	assert flash.empty?
  end
end