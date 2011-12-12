require "spec_helper"

describe UsersController do
  render_views
  
  describe "GET 'index'" do
    describe "for non-signed-in users" do
      it "should deny access" do
        get :index
        response.should redirect_to(signin_path)
        flash[:error].should =~ /you don't have access to this page/i
      end
    end
    
    describe "for signed-in users" do
      before(:each) do
        @user = test_sign_in(Factory(:user))
        @users = [@user]
        33.times do
          @users << Factory(:random_user)
        end
      end
      
      it "should be successful" do
        get :index
        response.should be_success
      end
      
      it "should have the right title" do
        get :index
        response.should have_selector("title", :content => "Users")
      end
      
      it "should have an element for each user" do
        get :index
        @users[0..33].each do |user|
          response.should have_selector("div.user_info")
        end
      end
      
      it "should paginate users" do
        get :index
        response.should have_selector("div.pagination")
        response.should have_selector("span.disabled", :content => "Previous")
        response.should have_selector("a", :href => "/users?page=2", :content => "2")
        response.should have_selector("a", :href => "/users?page=2", :content => "Next")
      end
      
      it "should show users on other pages" do
        get :index, :page => 2
        response.should have_selector("div.user_info")
      end
    end
  end
  
  describe "GET 'show'" do
    before(:each) do
      @user = Factory(:user)
    end
    
    it "should be successful" do
      get :show, :id => @user
      response.should be_success
    end
    
    it "should find the right user" do
      get :show, :id => @user
      assigns(:user).should == @user
    end
    
    it "should have the right title" do
      get :show, :id => @user
      response.should have_selector("title", :content => @user.name)
    end
    
    it "should include the user's name" do
      get :show, :id => @user
      response.should have_selector("span.user_name", :content => @user.name)
    end
     
    it "should have a profile image" do
      get :show, :id => @user
      response.should have_selector("div.user_info") do
        have_selector("img.gravatar")
      end
    end
    
    describe "should show post count properly" do
      it "should not pluralize 1 post" do
        Factory(:post, :user => @user, :content => "Foo bar")
        get :show, :id => @user
        response.should have_selector("div.user_info") do
          have_selector("span.post_count", :content => "1 post")
        end
      end
      
      it "should pluralize unless only 1 post" do
        Factory(:post, :user => @user, :content => "Foo bar")
        Factory(:post, :user => @user, :content => "Baz quux")
        get :show, :id => @user
        response.should have_selector("div.user_info") do
          have_selector("span.post_count", :content => "2 posts")
        end
      end
    end
    
    it "should show the user's posts" do
      post1 = Factory(:post, :user => @user, :content => "Foo bar")
      post2 = Factory(:post, :user => @user, :content => "Baz quux")
      get :show, :id => @user
      response.should have_selector("div.content", :content => post1.content)
      response.should have_selector("div.content", :content => post2.content)
    end
    
    describe "paging" do
      before(:each) do
        @posts = []
        50.times do
          @posts << Factory(:post, :user => @user, :content => "Foo bar")
        end
      end
      
      it "should create paging" do
        get :show, :id => @user
        response.should have_selector("script", :content => %($('#filtered_stream').pageless({"totalPages": 2, "url": "/users/foobar", "loader": "#filtered_stream"});))
      end
      
      it "should show the user's posts on other pages" do
        get :show, :id => @user, :page => 2
        response.should have_selector("div.content", :content => "Foo bar")
      end
    end
  end
  
  describe "GET 'new'" do
    before(:each) do
      get :new
    end
    
    it "should be successful" do
      response.should be_success
    end
    
    it "should have the right title" do
      response.should have_selector("title", :content => "Sign up")
    end
    
    it "should have a name field" do
      response.should have_selector("input[name='user[name]'][type='text']")
    end
    
    it "should have an email field" do
      response.should have_selector("input[name='user[email]'][type='text']")
    end
    
    it "should have a password field" do
      response.should have_selector("input[name='user[password]'][type='password']")
    end
    
    it "should have a password confirmation field" do
      response.should have_selector("input[name='user[password_confirmation]'][type='password']")
    end
  end
  
  describe "POST 'create'" do
    describe "failure" do
      before(:each) do
        @attr =
        {
          :name => "",
          :username => "",
          :email => "",
          :password => "",
          :password_confirmation => ""
        }
      end
    
      it "should not create a user" do
        lambda do
          post :create, :user => @attr
        end.should_not change(User, :count)
      end
      
      it "should have the right title" do
        post :create, :user => @attr
        response.should have_selector("title", :content => "Sign up")
      end
      
      it "should render the 'new' page" do
        post :create, :user => @attr
        response.should render_template('new')
      end
    end
    
    describe "success" do
      before(:each) do
        @attr =
        {
          :name => "Foo Bar",
          :username => "foobar",
          :email => "foo@bar.com",
          :password => "foobar",
          :password_confirmation => "foobar"
        }
      end
    
      it "should create a user" do
        lambda do
          post :create, :user => @attr
        end.should change(User, :count).by(1)
      end
      
      it "should redirect to the user show page" do
        post :create, :user => @attr
        response.should redirect_to(user_path(assigns(:user)))
      end
      
      it "should have a welcome message" do
        post :create, :user => @attr
        flash[:notice].should =~ /welcome/i
      end
    end
  end
  
  describe "GET 'edit'" do
    before(:each) do
      @user = Factory(:user)
      test_sign_in(@user)
      get :edit, :id => @user
    end
    
    it "should be successful" do
      response.should be_success
    end
    
    it "should have the right title" do
      response.should have_selector("title", :content => "Edit profile")
    end
    
    it "should have a link to change the Gravatar" do
      gravatar_url = "http://gravatar.com/emails"
      response.should have_selector("a", :href => gravatar_url)
    end
  end
  
  describe "PUT 'update'" do
    before(:each) do
      @user = Factory(:user)
      test_sign_in(@user)
    end
    
    describe "failure" do
      before(:each) do
        @attr =
        {
          :name => "",
          :username => "",
          :email => "",
          :password => "",
          :password_confirmation => ""
        }
      end
    
      it "should render the 'edit' page" do
        put :update, :id => @user, :user => @attr
        response.should render_template('edit')
      end
      
      it "should have the right title" do
        put :update, :id => @user, :user => @attr
        response.should have_selector("title", :content => "Edit profile")
      end
    end
    
    describe "success" do
      before(:each) do
        @attr =
        {
          :name => "Foo Bar",
          :username => "foobar",
          :email => "foo@bar.com",
          :password => "foobar",
          :password_confirmation => "foobar"
        }
      end
    
      it "should change the user's attributes" do
        put :update, :id => @user, :user => @attr
        @user.reload
        @user.name.should  == @attr[:name]
        @user.email.should == @attr[:email]
      end
      
      it "should redirect to the user show page" do
        put :update, :id => @user, :user => @attr
        response.should redirect_to(user_path(@user))
      end
      
      it "should have a flash message" do
        put :update, :id => @user, :user => @attr
        flash[:notice].should =~ /updated/i
      end
    end
  end
  
  describe "authentication of edit/update pages" do
    before(:each) do
      @user = Factory(:user)
    end
    
    describe "for non-signed-in users" do
      it "should deny access to 'edit'" do
        get :edit, :id => @user
        response.should redirect_to(signin_path)
      end
      
      it "should deny access to 'update'" do
        put :update, :id => @user, :user => {}
        response.should redirect_to(signin_path)
      end
    end
    
    describe "for signed-in users" do
      before(:each) do
        random_user = Factory(:random_user)
        test_sign_in(random_user)
      end
      
      it "should deny editing of other users' information" do
        get :edit, :id => @user
        response.should redirect_to(root_path)
      end
      
      it "should deny updating of other users' information" do
        put :update, :id => @user, :user => {}
        response.should redirect_to(root_path)
      end
    end
  end
  
  describe "DELETE 'destroy'" do
    before(:each) do
      @user = Factory(:user)
    end
    
    describe "as a non-signed-in user" do
      it "should deny access" do
        delete :destroy, :id => @user
        response.should redirect_to(signin_path)
      end
    end
    
    describe "as a non-admin user" do
      it "should protect the page" do
        test_sign_in(@user)
        delete :destroy, :id => @user
        response.should redirect_to(root_path)
      end
    end
    
    describe "as an admin user" do
      before(:each) do
        @admin = Factory(:admin)
        test_sign_in(@admin)
      end
      
      it "should destroy the user" do
        lambda do
          delete :destroy, :id => @user
        end.should change(User, :count).by(-1)
      end
      
      it "should not destroy their own user" do
        lambda do
          delete :destroy, :id => @admin
        end.should_not change(User, :count)
      end
      
      it "should redirect to the users page" do
        delete :destroy, :id => @user
        response.should redirect_to(users_path)
      end
    end
  end
  
  describe "follow pages" do
    describe "when not signed in" do
      it "should protect 'following'" do
        get :following, :id => 1
        response.should redirect_to(signin_path)
      end
      
      it "should protect 'followers'" do
        get :followers, :id => 1
        response.should redirect_to(signin_path)
      end
    end
    
    describe "when signed in" do
      before(:each) do
        @user = test_sign_in(Factory(:user))
        @other_user = Factory(:random_user)
        @user.follow!(@other_user)
      end
      
      it "should show user following" do
        get :following, :id => @user
        response.should have_selector("a", :href => user_path(@other_user), :content => @other_user.name)
      end
      
      it "should show user followers" do
        get :followers, :id => @other_user
        response.should have_selector("a", :href => user_path(@user), :content => @user.name)
      end
    end
  end
end
