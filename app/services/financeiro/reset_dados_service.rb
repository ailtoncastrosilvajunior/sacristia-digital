# frozen_string_literal: true

module Financeiro
  class ResetDadosService
    TABELAS_TRUNCATE = %w[
      itens_lancamento
      lancamentos_caixa
      importacoes_financeiras
      auditorias_financeiras
    ].freeze

    def self.call(plano_contas: false)
      new(plano_contas: plano_contas).call
    end

    def initialize(plano_contas: false)
      @reset_plano = plano_contas
    end

    def call
      counts_before = snapshot_counts

      ActiveRecord::Base.transaction do
        if postgres?
          truncate_postgres!
        else
          delete_all_fallback!
        end

        reset_configuracao!
        reseed_plano_e_conta! if @reset_plano
      end

      snapshot_counts.merge(antes: counts_before)
    end

    private

    def postgres?
      ActiveRecord::Base.connection.adapter_name.match?(/postgres/i)
    end

    def truncate_postgres!
      tabelas = TABELAS_TRUNCATE.dup
      tabelas << "plano_contas" if @reset_plano
      lista = tabelas.map { |t| ActiveRecord::Base.connection.quote_table_name(t) }.join(", ")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{lista} RESTART IDENTITY CASCADE")
    end

    def delete_all_fallback!
      AuditoriaFinanceira.delete_all
      ItemLancamento.delete_all
      LancamentoCaixa.delete_all
      ImportacaoFinanceira.delete_all
      PlanoConta.delete_all if @reset_plano
      reset_sequences_sqlite_fallback!
    end

    def reset_sequences_sqlite_fallback!
      TABELAS_TRUNCATE.each { |t| reset_pk_sequence!(t) }
      reset_pk_sequence!("plano_contas") if @reset_plano
    end

    def reset_pk_sequence!(table_name)
      conn = ActiveRecord::Base.connection
      return unless conn.adapter_name.match?(/postgres/i)

      quoted = conn.quote_table_name(table_name)
      conn.execute(<<~SQL.squish)
        SELECT setval(pg_get_serial_sequence('#{table_name}', 'id'),
          COALESCE((SELECT MAX(id) FROM #{quoted}), 1),
          (SELECT MAX(id) FROM #{quoted}) IS NOT NULL)
      SQL
    end

    def reset_configuracao!
      FinanceiroConfiguracao.instancia.update!(migrado_em: nil)
    end

    def reseed_plano_e_conta!
      PlanoContaSeedService.call
      ContaCorrente.padrao
    end

    def snapshot_counts
      {
        lancamentos: LancamentoCaixa.count,
        itens: ItemLancamento.count,
        importacoes: ImportacaoFinanceira.count,
        auditorias: AuditoriaFinanceira.count,
        plano_contas: PlanoConta.count
      }
    end
  end
end
