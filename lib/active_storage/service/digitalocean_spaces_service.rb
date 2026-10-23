# frozen_string_literal: true

require "active_storage/service/s3_service"

module ActiveStorage
  # Spaces (S3-compatible): repassa ao aws-sdk-s3 só opções suportadas.
  # Chaves extras no storage.yml (ex.: prefix, removido no Rails 8.1) quebram o boot.
  class Service::DigitaloceanSpacesService < Service::S3Service
    AWS_RESOURCE_OPTIONS = %i[
      access_key_id
      secret_access_key
      region
      endpoint
      force_path_style
      request_checksum_calculation
      response_checksum_validation
    ].freeze

    def initialize(bucket:, upload: {}, public: false, **options)
      super(bucket: bucket, upload: upload, public: public, **options.slice(*AWS_RESOURCE_OPTIONS))
    end
  end
end
