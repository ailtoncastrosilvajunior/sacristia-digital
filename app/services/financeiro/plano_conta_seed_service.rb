# frozen_string_literal: true

module Financeiro
  class PlanoContaSeedService
    ESTRUTURA = [
      { codigo: "1", nome: "RECEITAS", natureza: "receita", sintetica: true, filhos: [
        { codigo: "1.1", nome: "Coletas", sintetica: false },
        { codigo: "1.2", nome: "Intenções", sintetica: false },
        { codigo: "1.3", nome: "Doações - Face", sintetica: false },
        { codigo: "1.4", nome: "Doações - Outras", sintetica: false }
      ] },
      { codigo: "2", nome: "DESPESAS", natureza: "despesa", sintetica: true, filhos: [
        { codigo: "2.1", nome: "Espórtulas", sintetica: false },
        { codigo: "2.2", nome: "Devolução de Empréstimos", sintetica: false },
        { codigo: "2.3", nome: "Repasse AFC", sintetica: false },
        { codigo: "2.4", nome: "Repasse Paróquia São Vicente", sintetica: false },
        { codigo: "2.5", nome: "Itens de Consumo", sintetica: true, filhos: [
          { codigo: "2.5.1", nome: "Decoração Capela", sintetica: false },
          { codigo: "2.5.2", nome: "Vinho", sintetica: false },
          { codigo: "2.5.3", nome: "Partículas", sintetica: false },
          { codigo: "2.5.4", nome: "Água", sintetica: false },
          { codigo: "2.5.5", nome: "Descartáveis (Copos, pratos)", sintetica: false },
          { codigo: "2.5.6", nome: "Papel toalha", sintetica: false },
          { codigo: "2.5.7", nome: "Cheirinho", sintetica: false },
          { codigo: "2.5.8", nome: "Incenso", sintetica: false },
          { codigo: "2.5.9", nome: "Carvão Tablete", sintetica: false },
          { codigo: "2.5.10", nome: "Velas", sintetica: false },
          { codigo: "2.5.11", nome: "Mangas vidro", sintetica: false },
          { codigo: "2.5.12", nome: "Lavanderia", sintetica: false },
          { codigo: "2.5.13", nome: "Alfaias litúrgicas", sintetica: false },
          { codigo: "2.5.14", nome: "Limpeza da sacristia", sintetica: false },
          { codigo: "2.5.15", nome: "Produtos de limpeza", sintetica: false },
          { codigo: "2.5.16", nome: "Acessórios sacristia", sintetica: false },
          { codigo: "2.5.17", nome: "Água Sanitária", sintetica: false },
          { codigo: "2.5.18", nome: "Álcool", sintetica: false },
          { codigo: "2.5.19", nome: "Outros", sintetica: false },
          { codigo: "2.5.20", nome: "Fraternidade | Aniversariantes", sintetica: false },
          { codigo: "2.5.21", nome: "Material administrativo", sintetica: false },
          { codigo: "2.5.22", nome: "Pilha", sintetica: false },
          { codigo: "2.5.23", nome: "Livro Diretório", sintetica: false }
        ] }
      ] }
    ].freeze

    def self.call
      new.call
    end

    def call
      ESTRUTURA.each_with_index do |node, idx|
        upsert_node(node, natureza: node[:natureza], ordem: idx, pai: nil)
      end
    end

    private

    def upsert_node(node, natureza:, ordem:, pai:)
      registro = PlanoConta.find_or_initialize_by(codigo: node[:codigo])
      registro.assign_attributes(
        nome: node[:nome],
        natureza: natureza,
        sintetica: node.fetch(:sintetica, false),
        conta_pai: pai,
        ordem: ordem,
        ativo: true
      )
      registro.save!
      (node[:filhos] || []).each_with_index do |filho, i|
        upsert_node(filho, natureza: natureza, ordem: i, pai: registro)
      end
    end
  end
end
