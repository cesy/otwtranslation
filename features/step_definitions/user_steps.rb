Given /^I am a user$/ do
  user = Factory.create(:user)
  visit "/"
  fill_in "User name", :with => user.login
  fill_in "Password", :with => user.password
  click_button "Log in"
  assert UserSession.find
end

