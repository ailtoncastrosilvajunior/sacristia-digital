# frozen_string_literal: true

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
end
