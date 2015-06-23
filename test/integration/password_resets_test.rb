require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
	def setup
		ActionMailer::Base.deliveries.clear
		@user = users(:michael)
	end

	test "password resets" do
		get new_password_reset_path
		assert_template 'password_resets/new'
		# Invalid email
		post password_resets_path, password_reset: { email: "" }
		assert_not flash.empty?
		assert_template 'password_resets/new'
		# Valid email
		post password_resets_path, password_reset: { email: @user.email }
		assert_equal 1, ActionMailer::Base.deliveries.size
		assert_not flash.empty?
		assert_redirected_to root_url
		# Test password reset form
		user = assigns(:user)
		# Wrong email
		get edit_password_reset_path(user.reset_token, email: "") # Simulate the click password reset link
		assert_redirected_to root_url
		# Inactive user
		user.toggle!(:activated) # activated attribute on database, return opposite value of :activated -> false
		get edit_password_reset_path(user.reset_token, email: user.email)
		assert_redirected_to root_url
		user.toggle!(:activated) # return opposite value of :activated -> true
		# Right email, wrong token
		get edit_password_reset_path("wrong token", email: user.email)
		assert_redirected_to root_url
		# Right email, right token
		get edit_password_reset_path(user.reset_token, email: user.email)
		# Load template edit password resets, enter 2 password
		assert_template 'password_resets/edit'
		assert_select "input[name=email][type=hidden][value=?]", user.email
		# Invalid password and confirmation
		patch password_reset_path(user.reset_token),
					email: user.email,
					user: { password: "foobarz",
									password_confirmation: "barquuz" }
		assert_select 'div#error_explanation'
		# Empty password
		patch password_reset_path(user.reset_token),
					email: user.email,
					user: { password: "",
									password_confirmation: "" }
		assert_not flash.empty?
		assert_template 'password_resets/edit'
		# Valid password and confirmation
		patch password_reset_path(user.reset_token),
					email: user.email,
					user: { password: "foobar",
									password_confirmation: "foobar" }
		assert is_logged_in?
		assert_not flash.empty?
		assert_redirected_to user
	end

	test "expired token" do
		get new_password_reset_path
		assert_template 'password_resets/new'
		post password_resets_path, password_reset: { email: @user.email }
		@user = assigns(:user)
		@user.update_attribute(:reset_sent_at, 3.hours.ago)
		patch password_reset_path(@user.reset_token),
					email: @user.email,
					user: { password: "foobar",
									password_confirmation: "foobar" }
		assert_response :redirect
		follow_redirect!
		assert_match /expired/i, response.body
	end
end