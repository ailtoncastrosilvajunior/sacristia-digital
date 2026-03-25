# frozen_string_literal: true

module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy]

    def index
      @users = User.order(:email).page(params[:page])
    end

    def show
    end

    def new
      @user = User.new(perfis: [])
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_user_path(@user), notice: "Usuário cadastrado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "Usuário atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "Você não pode excluir a si mesmo."
        return
      end
      @user.destroy
      redirect_to admin_users_path, notice: "Usuário removido."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      p = params.require(:user).permit(:email, :nome, :password, :password_confirmation, :ministro_id, :sacerdote_id, perfis: [])
      p[:perfis] = Array(p[:perfis]).compact_blank
      p.delete(:password) if p[:password].blank?
      p.delete(:password_confirmation) if p[:password_confirmation].blank?
      p
    end
  end
end
