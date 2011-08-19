class SessionsController < ApplicationController
  def new
    @title = t(:sign_in)
  end

  def create
    user = User.authenticate(params[:session][:email], params[:session][:password])
    if user.nil?
      flash.now[:error] = t(:invalid_login_message)
      @title = t(:sign_in)
      render 'sessions/new'
    else
      sign_in user
      redirect_back_or user
    end
  end
  
  def destroy
    sign_out
    redirect_to root_path
  end
end
