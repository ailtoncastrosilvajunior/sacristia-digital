# frozen_string_literal: true

module PainelMinistro
  # O ministro edita apenas o PRÓPRIO cadastro e só dados pessoais.
  # E-mail (login do usuário), nome curto, ativo e observações ficam com a coordenação.
  class CadastroController < PainelMinistro::BaseController
    before_action :carregar_ministro

    def edit; end

    def update
      if @ministro.update(cadastro_params)
        redirect_to ministro_root_path, notice: "Cadastro atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    # Sempre o ministro do usuário logado: nenhum id vem da requisição.
    def carregar_ministro
      @ministro = current_user.ministro
    end

    def cadastro_params
      params.require(:ministro).permit(:nome_completo, :telefone, :sexo,
                                       :nascimento_dia, :nascimento_mes, :nascimento_ano, :exibir_ano_nascimento)
    end
  end
end
