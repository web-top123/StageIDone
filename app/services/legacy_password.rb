class LegacyPassword
  DEFAULT_ITER = 15000
  DEFAULT_ALGO = "pbkdf2_sha256"

  def self.valid_password?(hashed, plaintext)
    return false if hashed[0] == '!'
    case hashed.split('$').first
    when 'pbkdf2_sha256'
      (_, iters, salt, enc) = hashed.split('$')
      return enc == pbkdf2_hash(plaintext, salt, iters)
    when 'sha1'
      (_, salt, enc) = hashed.split('$')
      return enc == sha1_hash(plaintext, salt)
    end
    false
  end

  # This takes a plaintext password and hashes it according to standard django auth hashing scheme
  def self.pbkdf2_hash(plaintext, salt, iters)
    # Make a salt that looks like a Django salt
    digest = OpenSSL::Digest::SHA256.new
    pbkdf = OpenSSL::PKCS5::pbkdf2_hmac(
      plaintext,
      salt,
      iters.to_i,
      digest.digest_length,
      digest
    )
    Base64.strict_encode64(pbkdf)
  end

  def self.sha1_hash(plaintext, salt)
    Digest::SHA1.hexdigest(salt + plaintext)
  end
end
# If you wanted to produce a crypted password that looked like django in full, it would look like this
# taking hash from the function above
# salt = Base64.strict_encode64(OpenSSL::Random.random_bytes(8))
# "#{DEFAULT_ALGO}$#{DEFAULT_ITER}$#{salt}$#{hash}"
