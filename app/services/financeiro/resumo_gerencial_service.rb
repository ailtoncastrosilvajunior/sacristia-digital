# frozen_string_literal: true

module Financeiro
  class ResumoGerencialService
    MESES_HISTORICO = 7

    Coluna = Struct.new(:key, :ano, :mes, :label, :referencia, keyword_init: true)
    Linha = Struct.new(:tipo, :nome, :plano_conta, :nivel, :valores, :destaque, keyword_init: true)

    def initialize(ano:, mes:, meses_historico: MESES_HISTORICO)
      @ano = ano
      @mes = mes
      @meses_historico = meses_historico
    end

    def colunas
      @colunas ||= (0...@meses_historico).map do |i|
        data = Date.new(@ano, @mes, 1) - i.months
        Coluna.new(
          key: chave_mes(data.year, data.month),
          ano: data.year,
          mes: data.month,
          label: format("%d/%02d", data.year, data.month),
          referencia: i.zero?
        )
      end
    end

    def linhas
      @linhas ||= begin
        totais_analiticos
        filhos_por_pai
        contas_analiticas_ids_por_natureza
        saldos_anteriores_por_coluna

        rows = []
        rows << linha_saldo_anterior
        rows.concat(secao_receitas)
        rows.concat(secao_despesas)
        rows
      end
    end

    private

    def chave_mes(ano, mes)
      format("%04d-%02d", ano, mes)
    end

    def periodo_historico
      @periodo_historico ||= begin
        mais_antigo = colunas.last
        inicio = Date.new(mais_antigo.ano, mais_antigo.mes, 1)
        fim = Date.new(@ano, @mes, 1).end_of_month
        inicio..fim
      end
    end

    def chaves_colunas
      @chaves_colunas ||= colunas.map(&:key).to_set
    end

    def totais_analiticos
      @totais_analiticos ||= begin
        hash = Hash.new { |h, k| h[k] = Hash.new(0.to_d) }
        chaves = chaves_colunas
        ItemLancamento
          .joins(:lancamento_caixa, :plano_conta)
          .merge(LancamentoCaixa.confirmados.where(data: periodo_historico))
          .where(plano_contas: { sintetica: false })
          .pluck("plano_contas.id", "itens_lancamento.valor", "lancamentos_caixa.data")
          .each do |conta_id, valor, data|
            key = chave_mes(data.year, data.month)
            next unless chaves.include?(key)

            hash[conta_id][key] += valor.to_d
          end
        hash
      end
    end

    def contas_analiticas_ids_por_natureza
      @contas_analiticas_ids_por_natureza ||= PlanoConta.analiticas.group_by(&:natureza).transform_values { |cs| cs.map(&:id) }
    end

    def movimentos_conta_corrente
      @movimentos_conta_corrente ||= begin
        conta = ContaCorrente.padrao
        LancamentoCaixa.confirmados
          .where(conta_corrente_id: conta.id)
          .where(data: conta.data_saldo_inicial..periodo_historico.end)
          .order(:data, :id)
          .pluck(:data, :natureza, :valor_total)
      end
    end

    def saldos_anteriores_por_coluna
      @saldos_anteriores_por_coluna ||= begin
        conta = ContaCorrente.padrao
        base = conta.saldo_inicial.to_d
        min = conta.data_saldo_inicial
        movs = movimentos_conta_corrente

        pendentes = colunas.sort_by { |c| Date.new(c.ano, c.mes, 1) }
        result = {}
        saldo = base
        idx = 0

        pendentes.each do |col|
          limite = Date.new(col.ano, col.mes, 1) - 1.day
          if limite < min
            result[col.key] = base
            next
          end

          while idx < movs.size && movs[idx][0] <= limite
            _data, natureza, valor = movs[idx]
            saldo += natureza == "entrada" ? valor.to_d : -valor.to_d
            idx += 1
          end
          result[col.key] = saldo
        end

        colunas.to_h { |col| [col.key, result[col.key] || base] }
      end
    end

    def total_conta(conta, col_key)
      if conta.sintetica?
        filhos_de(conta).sum { |sub| total_conta(sub, col_key) }
      else
        totais_analiticos.dig(conta.id, col_key).to_d
      end
    end

    def valores_conta(conta)
      colunas.to_h { |col| [col.key, total_conta(conta, col.key)] }
    end

    def valores_natureza(natureza)
      ids = contas_analiticas_ids_por_natureza[natureza] || []
      colunas.to_h do |col|
        total = ids.sum { |id| totais_analiticos.dig(id, col.key).to_d }
        [col.key, total]
      end
    end

    def linha_saldo_anterior
      Linha.new(
        tipo: :saldo_anterior,
        nome: "Saldo Anterior",
        nivel: 0,
        valores: saldos_anteriores_por_coluna.dup,
        destaque: :saldo
      )
    end

    def filhos_de(conta)
      filhos_por_pai[conta.id] || []
    end

    def filhos_por_pai
      @filhos_por_pai ||= PlanoConta.ativas.ordenadas.group_by(&:conta_pai_id).transform_values do |contas|
        contas.sort_by(&:codigo)
      end
    end

    def contas_raiz
      @contas_raiz ||= PlanoConta.ativas.where(codigo: %w[1 2]).index_by(&:codigo)
    end

    def secao_receitas
      raiz = contas_raiz["1"]
      return [] unless raiz

      rows = []
      rows << Linha.new(
        tipo: :secao,
        nome: "Entradas",
        nivel: 0,
        valores: valores_natureza("receita"),
        destaque: :entrada
      )
      rows.concat(linhas_arvore(filhos_de(raiz), nivel: 0))
      rows
    end

    def secao_despesas
      raiz = contas_raiz["2"]
      return [] unless raiz

      rows = []
      rows << Linha.new(
        tipo: :secao,
        nome: "DESPESAS",
        nivel: 0,
        valores: valores_natureza("despesa"),
        destaque: :despesa
      )
      rows.concat(linhas_arvore(filhos_de(raiz), nivel: 0))
      rows
    end

    def linhas_arvore(contas, nivel:)
      contas.flat_map do |conta|
        row = Linha.new(
          tipo: :conta,
          nome: conta.nome,
          plano_conta: conta,
          nivel: nivel,
          valores: valores_conta(conta),
          destaque: conta.sintetica? ? :sintetica : nil
        )
        filhos = filhos_de(conta)
        if filhos.any?
          [row] + linhas_arvore(filhos, nivel: nivel + 1)
        else
          [row]
        end
      end
    end
  end
end
