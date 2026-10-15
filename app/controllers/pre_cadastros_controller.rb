# frozen_string_literal: true

# Formulário público de pré-cadastro de ministro (exige aprovação do admin).
class PreCadastrosController < ApplicationController
  skip_before_action :authenticate_user!

  rate_limit to: 5, within: 10.minutes, only: :create,
             with: -> { redirect_to novo_pre_cadastro_path, alert: "Muitas tentativas. Aguarde alguns minutos." }

  def new
    @solicitacao = SolicitacaoCadastro.new
  end

  def create
    # Honeypot: campo invisível que só robôs preenchem.
    return redirect_to(pre_cadastro_enviado_path) if params[:campo_armadilha].present? || params[:website].present?

    @solicitacao = SolicitacaoCadastro.new(solicitacao_params)
    if @solicitacao.save
      redirect_to pre_cadastro_enviado_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def enviado
  end

  private

  def solicitacao_params
    params.require(:solicitacao_cadastro)
          .permit(:nome_completo, :nome, :email, :email_confirmation, :telefone, :sexo, :nascimento_dia, :nascimento_mes,
                  :nascimento_ano, :exibir_ano_nascimento, :password, :password_confirmation)
  end
end
