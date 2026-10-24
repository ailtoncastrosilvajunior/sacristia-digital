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
    # Honeypot: campo invisível que só robôs preenchem (sem tela de sucesso).
    if params[:campo_armadilha].to_s.strip.present?
      return redirect_to(novo_pre_cadastro_path)
    end

    @solicitacao = SolicitacaoCadastro.new(solicitacao_params)
    if @solicitacao.save
      session[:pre_cadastro_confirmacao] = {
        "id" => @solicitacao.id,
        "email" => @solicitacao.email
      }
      redirect_to pre_cadastro_enviado_path, status: :see_other
    else
      n = @solicitacao.errors.count
      flash.now[:alert] = if n == 1
                            "Não foi possível enviar: 1 correção pendente (veja acima do botão Enviar)."
                          else
                            "Não foi possível enviar: #{n} correções pendentes (veja acima do botão Enviar)."
                          end
      render :new, status: :unprocessable_entity
    end
  end

  def enviado
    dados = session.delete(:pre_cadastro_confirmacao)
    unless dados.is_a?(Hash) && dados["id"].present?
      redirect_to novo_pre_cadastro_path,
                  alert: "Para ver a confirmação, envie o formulário de cadastro primeiro."
      return
    end

    @solicitacao = SolicitacaoCadastro.find_by(id: dados["id"], email: dados["email"], status: "pendente")
    unless @solicitacao
      redirect_to novo_pre_cadastro_path,
                  alert: "Não encontramos essa solicitação. Se ainda não enviou, preencha o formulário novamente."
    end
  end

  private

  def solicitacao_params
    params.require(:solicitacao_cadastro)
          .permit(:nome_completo, :nome, :email, :email_confirmation, :telefone, :sexo, :nascimento_dia, :nascimento_mes,
                  :nascimento_ano, :exibir_ano_nascimento, :password, :password_confirmation)
  end
end
