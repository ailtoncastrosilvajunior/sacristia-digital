# frozen_string_literal: true

require "digest"
require "roo"

module Financeiro
  class ImportPlanilhaService
    class ImportBlockedError < StandardError; end

    def self.call(path, force: false, apenas_intencoes: false)
      new(path, force: force, apenas_intencoes: apenas_intencoes).call
    end

    def initialize(path, force: false, apenas_intencoes: false)
      @path = resolve_path(path)
      @force = force
      @apenas_intencoes = apenas_intencoes
      @relatorio = { gerencial: {}, despesas: {}, entradas: {}, erros: [] }
      @conta_corrente = ContaCorrente.padrao
    end

    def call
      return call_apenas_intencoes if @apenas_intencoes

      raise ImportBlockedError, "Migração já realizada. Use FORCE=1 para repetir." if FinanceiroConfiguracao.migrado? && !@force
      raise ArgumentError, "Arquivo não encontrado: #{@path}" unless File.file?(@path)

      preparar_reimportacao! if @force

      checksum = Digest::SHA256.hexdigest(File.read(@path))
      @importacao = ImportacaoFinanceira.find_or_initialize_by(checksum: checksum)
      return @importacao if @importacao.concluida? && !@force

      @importacao.assign_attributes(arquivo_nome: File.basename(@path), status: "pendente", relatorio: {})
      @importacao.save!

      @contas_analiticas = PlanoConta.analiticas.ordenadas.to_a
      log "Abrindo planilha…"
      xlsx = Roo::Spreadsheet.open(@path)

      Financeiro::ImportContext.run do
        importar_gerencial(xlsx)
        log "Importando despesas…"
        importar_despesas(xlsx, @importacao)
        log "Importando entradas…"
        importar_entradas(xlsx, @importacao)
      end

      @importacao.update!(status: "concluida", concluida_em: Time.current, relatorio: @relatorio)
      FinanceiroConfiguracao.marcar_migrado!
      log "Concluído: #{LancamentoCaixa.count} lançamentos no banco."

      @importacao
    rescue StandardError => e
      if @importacao&.persisted?
        @importacao.update(status: "falha", relatorio: @relatorio.merge("erro" => e.message))
      end
      raise
    end

    private

    def call_apenas_intencoes
      raise ArgumentError, "Arquivo não encontrado: #{@path}" unless File.file?(@path)

      checksum = Digest::SHA256.hexdigest(File.read(@path))
      @importacao = ImportacaoFinanceira.find_or_initialize_by(checksum: checksum)
      @importacao.assign_attributes(arquivo_nome: File.basename(@path), status: "pendente") if @importacao.new_record?
      @importacao.save!

      log "Importação incremental — somente intenções (aba Entradas, colunas I–L)…"
      xlsx = Roo::Spreadsheet.open(@path)

      Financeiro::ImportContext.run do
        importar_entradas(xlsx, @importacao, somente_intencoes: true)
      end

      relatorio_anterior = (@importacao.relatorio || {}).deep_symbolize_keys
      entradas = @relatorio[:entradas].merge(modo: "apenas_intencoes")
      @importacao.update!(
        status: "concluida",
        concluida_em: Time.current,
        relatorio: relatorio_anterior.merge(entradas_intencoes: entradas, erros_intencoes: @relatorio[:erros])
      )

      log "Concluído: #{entradas[:intencoes]} intenções importadas (#{entradas[:intencoes_ignoradas]} já existiam)."
      @importacao
    rescue StandardError => e
      if @importacao&.persisted?
        @importacao.update(status: "falha", relatorio: (@importacao.relatorio || {}).merge("erro_intencoes" => e.message))
      end
      raise
    end

    def preparar_reimportacao!
      log "FORCE=1 — zerando dados financeiros antes de reimportar…"
      Financeiro::ResetDadosService.call
    end

    def log(msg)
      $stdout.puts "[financeiro:import] #{msg}"
      $stdout.flush
    end

    def resolve_path(path)
      p = path.to_s.strip
      p = p.gsub(/\.xlsx(\.xlsx)+\z/i, ".xlsx")
      p = p.sub("planilha-migracao", "planilhas-migracao")

      basename = File.basename(p)
      candidates = [
        p,
        Rails.root.join(p),
        Rails.root.join(p.delete_prefix("/")),
        Rails.root.join("public", p.delete_prefix("/")),
        Rails.root.join("public/planilhas-migracao", basename),
        Rails.root.join("public/planilhas-migracao/MESC-Financeiro.xlsx")
      ].uniq

      candidates.find { |c| File.file?(c) } || candidates.first.to_s
    end

    def importar_gerencial(_xlsx)
      Financeiro::PlanoContaSeedService.call unless PlanoConta.exists?
      @relatorio[:gerencial] = {
        contas: PlanoConta.count,
        nota: "Plano inicial via seed (espelha aba Gerencial)"
      }
    end

    def importar_despesas(xlsx, importacao)
      sheet = find_sheet(xlsx, /despesas/i)
      unless sheet
        @relatorio[:despesas] = { ignorado: "aba não encontrada" }
        return
      end

      grupos = {}
      importados = 0
      ignorados = 0
      open_grupo_key = nil
      open_valor_doc = nil

      total = sheet.last_row
      (1..total).each do |r|
        log("  despesas: linha #{r}/#{total}") if (r % 250).zero?
        row = sheet.row(r)
        next if linha_cabecalho_ou_total?(row)
        next if row[1].to_s.strip.casecmp("data").zero?

        data = parse_date(row[1]) # coluna B
        next if data.nil?

        descricao = cell_str_raw(row[2]) # coluna C — descrição do item (mapeia p/ plano de contas)
        qty = parse_decimal(row[3]) || 1
        preco = parse_decimal(row[4]) || 0
        bruto_item = (qty.to_d * preco.to_d).round(2)
        valor_item = parse_decimal(row[5]) || bruto_item
        valor_desconto = [(bruto_item - valor_item.to_d).round(2), 0.to_d].max
        next if descricao.blank? && valor_item.to_d.zero?
        flag_esportula = truthy?(row[7]) # coluna H
        fornecedor = cell_str_raw(row[8])
        tem_nfe = truthy?(row[10])
        tem_recibo = truthy?(row[11])

        valor_doc = parse_decimal(row[6]) # coluna G

        if valor_doc.present?
          open_grupo_key = "doc-#{r}-#{valor_doc}"
          open_valor_doc = valor_doc
        elsif open_grupo_key.nil?
          open_grupo_key = "doc-#{r}-#{valor_item}"
          open_valor_doc = valor_item
        end

        plano = resolver_conta_despesa(descricao, flag_esportula)
        unless plano
          @relatorio[:erros] << "Linha #{r}: conta não mapeada (#{descricao})"
          ignorados += 1
          next
        end

        grupos[open_grupo_key] ||= {
          data: data,
          fornecedor: fornecedor,
          tem_nfe: tem_nfe,
          tem_recibo: tem_recibo,
          valor_doc: open_valor_doc,
          linha: r,
          itens: []
        }

        grupos[open_grupo_key][:itens] << {
          plano_conta: plano,
          descricao: descricao,
          quantidade: qty,
          preco_unitario: preco,
          valor_desconto: valor_desconto,
          valor: valor_item
        }

        grupo = grupos[open_grupo_key]
        soma_grupo = grupo[:itens].sum { |i| i[:valor].to_d }
        doc_total = open_valor_doc.to_d
        if doc_total.positive? && (soma_grupo - doc_total).abs < 0.02
          open_grupo_key = nil
          open_valor_doc = nil
        end
      end

      log "  despesas: gravando #{grupos.size} documentos…"
      grupos.each_value.with_index do |g, idx|
        log("  despesas: documento #{idx + 1}/#{grupos.size}") if ((idx + 1) % 100).zero?
        next if g[:itens].empty?

        soma = g[:itens].sum { |i| i[:valor].to_d }
        if g[:valor_doc].present? && (soma - g[:valor_doc].to_d).abs > 0.01
          @relatorio[:erros] << "Linha #{g[:linha]}: soma itens #{soma} ≠ total doc #{g[:valor_doc]}"
        end

        begin
          LancamentoCaixa.create!(
            conta_corrente: @conta_corrente,
            natureza: "saida",
            data: g[:data],
            status: "confirmado",
            fornecedor: g[:fornecedor],
            tem_documento_fiscal: g[:tem_nfe],
            tem_recibo: g[:tem_recibo],
            importacao_financeira: importacao,
            planilha_aba: "Despesas",
            planilha_linha: g[:linha],
            itens_lancamento_attributes: g[:itens].each_with_index.map do |item, idx|
              item.merge(ordem: idx)
            end
          )
          importados += 1
        rescue ActiveRecord::RecordInvalid => e
          @relatorio[:erros] << "Documento linha #{g[:linha]}: #{e.record.errors.full_messages.to_sentence}"
        end
      end

      @relatorio[:despesas] = { importados: importados, ignorados: ignorados, grupos: grupos.size }
    end

    def importar_entradas(xlsx, importacao, somente_intencoes: false)
      sheet = find_sheet(xlsx, /entradas/i)
      unless sheet
        @relatorio[:entradas] = { ignorado: "aba não encontrada" }
        return
      end

      importados_coletas = 0
      importados_intencoes = 0
      intencoes_ignoradas = 0
      conta_coleta = PlanoConta.find_by(codigo: "1.1")
      conta_intencoes = PlanoConta.find_by(codigo: "1.2")
      ultima_data_coleta = nil
      ultima_data_intencoes = nil

      total = sheet.last_row
      (1..total).each do |r|
        log("  entradas: linha #{r}/#{total}") if (r % 250).zero?
        row = sheet.row(r)
        next if linha_cabecalho_ou_total?(row)

        unless somente_intencoes || linha_cabecalho_intencoes?(row)
          importados_coletas += importar_entrada_coleta_linha(
            row, r, importacao, conta_coleta, ultima_data_coleta
          ) { |d| ultima_data_coleta = d }
        end

        unless linha_cabecalho_coletas?(row)
          resultado = importar_entrada_intencoes_linha(
            row, r, importacao, conta_intencoes, ultima_data_intencoes,
            pular_se_existente: somente_intencoes
          ) { |d| ultima_data_intencoes = d }
          case resultado
          when :ignorada then intencoes_ignoradas += 1
          when 1 then importados_intencoes += 1
          end
        end
      end

      @relatorio[:entradas] = {
        importados: importados_coletas + importados_intencoes,
        coletas: importados_coletas,
        intencoes: importados_intencoes,
        intencoes_ignoradas: intencoes_ignoradas
      }
    end

    def linha_cabecalho_coletas?(row)
      row[0].to_s.strip.casecmp("data").zero? ||
        row[0].to_s.strip.casecmp("coletas").zero?
    end

    def linha_cabecalho_intencoes?(row)
      ref = row[8].to_s.strip
      ref.casecmp("data").zero? ||
        ref.casecmp("total").zero? ||
        ref.match?(/\Aintenç/i)
    end

    def importar_entrada_coleta_linha(row, linha, importacao, conta_receita, ultima_data, &atualizar_data)
      return 0 if linha_cabecalho_coletas?(row)

      data = parse_date(row[0]) || parse_date(row[1])
      atualizar_data.call(data) if data.present?

      data ||= ultima_data
      return 0 if data.nil?

      valor = parse_decimal(row[4]) # coluna E — Valor coleta
      return 0 if valor_entrada_invalido?(valor)

      contado_por = cell_str_raw(row[5])
      descricao = cell_str_raw(row[6])

      criar_entrada!(
        data: data,
        valor: valor,
        conta_receita: conta_receita,
        descricao_item: descricao.presence || "Coleta",
        contado_por: contado_por,
        observacoes: descricao,
        importacao: importacao,
        linha: linha,
        rotulo_erro: "Entrada (coleta) linha #{linha}"
      )
    end

    def importar_entrada_intencoes_linha(row, linha, importacao, conta_receita, ultima_data, pular_se_existente: false, &atualizar_data)
      return 0 if linha_cabecalho_intencoes?(row)
      return :ignorada if pular_se_existente && intencao_ja_importada?(linha, conta_receita)

      data = parse_date(row[8]) || parse_date(row[9]) # colunas I–J
      atualizar_data.call(data) if data.present?

      data ||= ultima_data
      return 0 if data.nil?

      valor = parse_decimal(row[10]) # coluna K — Valor intenções
      return 0 if valor_entrada_invalido?(valor)

      descricao = cell_str_raw(row[11]) # coluna L — Observação

      criar_entrada!(
        data: data,
        valor: valor,
        conta_receita: conta_receita,
        descricao_item: descricao.presence || "Intenções",
        contado_por: nil,
        observacoes: descricao,
        importacao: importacao,
        linha: linha,
        rotulo_erro: "Entrada (intenções) linha #{linha}"
      )
    end

    def valor_entrada_invalido?(valor)
      valor.nil? || valor.zero? || valor > 100_000
    end

    def intencao_ja_importada?(linha, conta_receita)
      return false if conta_receita.blank?

      LancamentoCaixa.joins(:itens_lancamento)
                     .where(natureza: "entrada", planilha_aba: "Entradas", planilha_linha: linha)
                     .exists?(itens_lancamento: { plano_conta_id: conta_receita.id })
    end

    def criar_entrada!(data:, valor:, conta_receita:, descricao_item:, contado_por:, observacoes:, importacao:, linha:, rotulo_erro:)
      return 0 if conta_receita.nil?

      LancamentoCaixa.create!(
        conta_corrente: @conta_corrente,
        natureza: "entrada",
        data: data,
        status: "confirmado",
        contado_por: contado_por,
        observacoes: observacoes,
        importacao_financeira: importacao,
        planilha_aba: "Entradas",
        planilha_linha: linha,
        itens_lancamento_attributes: [
          {
            plano_conta: conta_receita,
            descricao: descricao_item,
            quantidade: 1,
            preco_unitario: valor,
            valor: valor,
            ordem: 0
          }
        ]
      )
      1
    rescue ActiveRecord::RecordInvalid => e
      @relatorio[:erros] << "#{rotulo_erro}: #{e.record.errors.full_messages.to_sentence}"
      0
    end

    def find_sheet(xlsx, pattern)
      xlsx.sheets.find { |n| n.match?(pattern) }.then { |n| n ? xlsx.sheet(n) : nil }
    end

    def linha_cabecalho_ou_total?(row)
      texto = row.compact.map { |c| c.to_s.strip.downcase }.join(" ")
      return true if texto.blank?
      return true if row[0].to_s.strip.casecmp("total").zero?
      return true if texto.match?(/\b(subtotal)\b/)
      return true if texto.match?(/\A(janeiro|fevereiro|março|marco|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)/i)

      false
    end

    def resolver_conta_despesa(descricao, flag_esportula)
      return PlanoConta.find_by(codigo: "2.1") if flag_esportula || descricao.to_s.match?(/espórtula/i)

      buscar_conta(descricao, "despesa")
    end

    def buscar_conta(ref, natureza)
      return nil if ref.blank?

      ref = ref.to_s.strip
      ref = "Álcool" if ref.match?(/alc[oó]ol/i)
      pool = (@contas_analiticas || PlanoConta.analiticas.to_a).select { |c| c.natureza == natureza }
      stem = ref.split(/[\(\-]/).first.to_s.strip.downcase

      pool.find { |c| c.codigo == ref } ||
        pool.find { |c| c.nome.casecmp?(ref) == 0 } ||
        pool.find { |c| c.nome.downcase.include?(stem) && stem.length >= 3 }
    end

    def parse_date(val)
      return val.to_date if val.is_a?(Date) || val.is_a?(Time) || val.is_a?(DateTime)
      return nil if val.blank?

      Date.parse(val.to_s)
    rescue ArgumentError
      nil
    end

    def parse_decimal(val)
      return nil if val.blank?
      return val.to_d if val.is_a?(Numeric)

      s = val.to_s.strip.gsub(/[^\d,.-]/, "")
      s = s.tr(".", "").sub(",", ".") if s.include?(",")
      BigDecimal(s)
    rescue ArgumentError
      nil
    end

    def truthy?(val)
      val.to_s.strip.match?(/\A(1|true|sim|x|✓|pago)\z/i) || val == true
    end

    def cell_str_raw(val)
      val.to_s.strip.presence
    end
  end
end
