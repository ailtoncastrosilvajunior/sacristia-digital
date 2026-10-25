# frozen_string_literal: true

module Financeiro
  class EsportulaLancamentoService
    def self.sync_from_registro!(registro)
      new(registro).sync!
    end

    def initialize(registro)
      @registro = registro
    end

    def sync!
      existing = LancamentoCaixa.find_by(registro_esportula_id: @registro.id)

      unless @registro.status == "pago"
        if existing && lancamento_vinculado_ao_evento?(existing)
          existing.destroy!
        end
        return nil
      end

      return existing if existing&.status == "confirmado"

      existing&.destroy! if existing&.estornado?

      criar_novo!
    end

    private

    def criar_novo!
      conta_esportula = PlanoConta.find_by!(codigo: "2.1")
      conta_corrente = ContaCorrente.padrao
      sacerdote_nome = @registro.sacerdote.nome

      LancamentoCaixa.create!(
        conta_corrente: conta_corrente,
        natureza: "saida",
        data: @registro.data,
        status: "confirmado",
        registro_esportula: @registro,
        evento_escala_id: @registro.evento_escala_id,
        fornecedor: sacerdote_nome,
        observacoes: observacoes_lancamento,
        itens_lancamento_attributes: [
          {
            plano_conta: conta_esportula,
            descricao: descricao_item,
            quantidade: 1,
            preco_unitario: @registro.valor,
            valor: @registro.valor,
            ordem: 0
          }
        ]
      )
    end

    def observacoes_lancamento
      parts = ["Pagamento espórtula — #{@registro.sacerdote.nome}"]
      ev = @registro.evento_escala
      if ev
        parts << "#{I18n.l(ev.data)} #{ev.horario.strftime('%H:%M')}"
        parts << ev.tipo_servico.nome if ev.tipo_servico
      end
      parts.join(" · ")
    end

    def descricao_item
      ev = @registro.evento_escala
      return "Espórtula" unless ev

      [ev.tipo_servico&.nome, ev.descricao.presence].compact.join(" — ").presence || "Espórtula"
    end

    def lancamento_vinculado_ao_evento?(lancamento)
      return false if @registro.evento_escala_id.blank?

      lancamento.registro_esportula_id == @registro.id &&
        lancamento.evento_escala_id == @registro.evento_escala_id
    end
  end
end
