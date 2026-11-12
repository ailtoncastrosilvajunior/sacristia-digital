# frozen_string_literal: true

class CreateLiturgiaCartazes < ActiveRecord::Migration[8.1]
  def up
    create_table :liturgia_cartazes do |t|
      t.references :instituicao, null: false, foreign_key: { to_table: :instituicoes }
      t.references :liturgia_dia, null: false, foreign_key: { to_table: :liturgia_dias }
      t.timestamps
    end

    add_index :liturgia_cartazes, %i[instituicao_id liturgia_dia_id],
              unique: true,
              name: "index_liturgia_cartazes_instituicao_liturgia_dia"

    inst = Instituicao.find_by(slug: "facedecristo")
    return unless inst

    say_with_time "Migrando PNGs de cartaz para liturgia_cartazes (Face de Cristo)" do
      ActiveStorage::Attachment.where(record_type: "LiturgiaDia", name: "cartaz_whatsapp").find_each do |attachment|
        ld_id = attachment.record_id
        registro = LiturgiaCartaz.find_or_create_by!(instituicao_id: inst.id, liturgia_dia_id: ld_id)
        attachment.update!(record_type: "LiturgiaCartaz", record_id: registro.id)
      end
    end
  end

  def down
    inst = Instituicao.find_by(slug: "facedecristo")

    if inst
      LiturgiaCartaz.where(instituicao_id: inst.id).find_each do |registro|
        attachment = ActiveStorage::Attachment.find_by(
          record_type: "LiturgiaCartaz",
          record_id: registro.id,
          name: "cartaz_whatsapp"
        )
        next unless attachment

        attachment.update!(record_type: "LiturgiaDia", record_id: registro.liturgia_dia_id)
      end
    end

    drop_table :liturgia_cartazes
  end
end
