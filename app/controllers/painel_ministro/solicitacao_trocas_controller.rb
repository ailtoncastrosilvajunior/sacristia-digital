# frozen_string_literal: true

module PainelMinistro
  # Troca entre ministros: quem serve pede a outro ministro que o substitua; só o substituto precisa aceitar.
  class SolicitacaoTrocasController < PainelMinistro::BaseController
    def create
      em = EscalaMinistro.where(ministro_id: current_user.ministro_id).find(params[:escala_ministro_id])
      evento = em.evento_escala

      if evento.cancelado? || evento.data < Date.current || !evento.competencia_mensal.escala_liberada?
        return voltar(evento, alert: "Esta celebração não aceita pedido de troca.")
      end

      substituto = Ministro.ativos.find_by(id: params[:substituto_id])
      return voltar(evento, alert: "Escolha quem vai te substituir.") if substituto.nil?

      troca = em.solicitacao_trocas.new(substituto: substituto, motivo: params[:motivo].to_s.strip.presence)
      if troca.save
        voltar(evento, notice: "Pedido enviado a #{substituto.nome}. A troca acontece quando ele aceitar.")
      else
        voltar(evento, alert: troca.errors.full_messages.to_sentence)
      end
    end

    # Solicitante desiste do pedido.
    def destroy
      troca = SolicitacaoTroca.joins(:escala_ministro)
                              .where(escala_ministros: { ministro_id: current_user.ministro_id })
                              .find(params[:id])
      troca.cancelar!
      voltar(troca.evento_escala, notice: "Pedido de troca cancelado.")
    end

    def aceitar
      troca = recebida
      if troca.aceitar!
        voltar(troca.evento_escala, notice: "Troca aceita. Você assumiu a celebração.")
      else
        voltar(troca.evento_escala, alert: "Não foi possível aceitar: o pedido mudou ou a celebração já passou.")
      end
    end

    def recusar
      troca = recebida
      troca.recusar!
      voltar(troca.evento_escala, notice: "Pedido de troca recusado.")
    end

    private

    # Pedido em que o usuário logado é o substituto indicado.
    def recebida
      SolicitacaoTroca.where(substituto_id: current_user.ministro_id).find(params[:id])
    end

    def voltar(evento, **flash)
      redirect_to ministro_escala_mensal_path(competencia_mensal_id: evento.competencia_mensal_id, anchor: "dia-#{evento.data.day}"), **flash
    end
  end
end
