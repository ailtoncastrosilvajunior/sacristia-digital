# frozen_string_literal: true

namespace :liturgia do
  namespace :cartaz do
    desc "Regenera moldura 1080 (JPG + PNG) a partir de app/assets/images/cartaz/liturgia-moldura.jpg"
    task prepare_moldura: :environment do
      base = Rails.root.join("app/assets/images/cartaz/liturgia-moldura.jpg")
      jpg_out = Rails.root.join("app/assets/images/cartaz/liturgia-moldura-1080.jpg")
      png_out = Rails.root.join("app/assets/images/cartaz/liturgia-moldura-1080.png")

      abort "Arquivo base ausente: #{base}" unless File.exist?(base)

      system("sips", "-z", "1920", "1080", base.to_s, "--out", jpg_out.to_s, out: $stdout, err: :err) ||
        abort("Falha ao gerar JPG 1080 (sips)")
      system("sips", "-s", "format", "png", jpg_out.to_s, "--out", png_out.to_s, out: $stdout, err: :err) ||
        abort("Falha ao gerar PNG 1080 (sips)")

      puts "OK: #{jpg_out.basename}, #{png_out.basename}"
    end
  end
end
