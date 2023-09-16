# encoding: utf-8

class PortraitUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  process convert: 'jpg'

  version :standard
  version :thumbnail do
    cloudinary_transformation width: 256, height: 256, crop: :fill, gravity: :face
  end

#   def public_id
#     model.id
#   end
end
