# frozen_string_literal: true

module ApplicationHelper
  # Aparência da célula do calendário do ministro (ordinária vs extra).
  def ministro_calendario_celula(cell)
    ord = cell[:ordinaria].to_i
    ext = cell[:extra].to_i
    plantao = cell[:plantao] ? true : false
    extra_like = ext.positive? || plantao

    # Visual sóbrio: círculos chapados, sem sombra.
    if ord.zero? && !extra_like
      { bg: "bg-transparent", text: "text-stone-400", shadow: "", ativo: false }
    elsif ord.positive? && extra_like
      { bg: "bg-sky-800", text: "text-white", shadow: "ring-2 ring-amber-500 ring-offset-2 ring-offset-white", ativo: true }
    elsif ord.positive?
      { bg: "bg-sky-800", text: "text-white", shadow: "", ativo: true }
    elsif ext.positive?
      { bg: "bg-amber-600", text: "text-white", shadow: "", ativo: true }
    else
      # Somente plantão (sem serviço lançado ainda)
      { bg: "bg-white border-2 border-dashed border-amber-500", text: "text-amber-800", shadow: "", ativo: true }
    end
  end

  def ministro_calendario_celula_title(cell, data_formatada)
    ord = cell[:ordinaria].to_i
    ext = cell[:extra].to_i
    plantao = cell[:plantao]

    partes = []
    partes << "escala ordinária" if ord.positive?
    partes << "escala extra" if ext.positive?
    partes << "de plantão" if plantao && ext.zero?
    return "#{data_formatada}: sem escala" if partes.empty?

    "#{data_formatada}: #{partes.join(' · ')}"
  end

  # Select padrão para o drawer de filtros das listagens.
  # opcoes: [[rotulo, valor], ...]; a opção "todos" é adicionada automaticamente.
  def filtro_select(nome, rotulo, opcoes, todos: "Todos")
    content_tag(:div) do
      label_tag(nome, rotulo, class: "block text-sm font-medium text-stone-700 mb-1") +
        select_tag(nome,
                   options_for_select([[todos, ""]] + opcoes, params[nome]),
                   class: "w-full px-3 py-2 text-sm rounded-lg border border-stone-300 bg-white",
                   data: { search_target: "filter" })
    end
  end

  def esportula_modo_select_options
    [
      ["Imediato", "imediato"],
      ["Acumulado (fim do mês)", "acumulado"]
    ]
  end

  def esportula_modo_rotulo(modo)
    modo.to_s == "acumulado" ? "Acumulado" : "Imediato"
  end
end
