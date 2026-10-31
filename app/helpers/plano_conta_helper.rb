# frozen_string_literal: true

require "set"

module PlanoContaHelper
  def badge_natureza_plano(conta)
    if conta.receita?
      tag.span "Receita", class: "inline-flex px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide rounded-md bg-emerald-100 text-emerald-800"
    else
      tag.span "Despesa", class: "inline-flex px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide rounded-md bg-amber-100 text-amber-900"
    end
  end

  def badge_tipo_plano(conta)
    if conta.sintetica?
      tag.span "Sintética", class: "inline-flex px-2 py-0.5 text-[10px] font-medium rounded-md bg-stone-200 text-stone-700"
    else
      tag.span "Analítica", class: "inline-flex px-2 py-0.5 text-[10px] font-medium rounded-md bg-sky-100 text-sky-800"
    end
  end

  def plano_conta_excluivel?(conta)
    !conta.subcontas.exists? && !conta.itens_lancamento.exists?
  end

  def plano_conta_pai_opcoes(excluir: nil)
    contas = PlanoConta.ordenadas.to_a
    if excluir
      por_pai = contas.group_by(&:conta_pai_id)
      proibidos = Set.new
      stack = [excluir.id]
      until stack.empty?
        id = stack.pop
        proibidos.add(id)
        (por_pai[id] || []).each { |c| stack.push(c.id) }
      end
      contas = contas.reject { |c| proibidos.include?(c.id) }
    end
    contas.map { |c| [c.label_completo, c.id] }
  end
end
