require 'test_helper'

class LegacyPasswordTest < ActiveSupport::TestCase
  test 'test valid pbkdf2 password' do
    assert LegacyPassword.valid_password?(
      'pbkdf2_sha256$15000$fTIiVisympRn$YpT1rs63KVjEvKqOmEtmVbiC5bCxYRUpIQjv3Sr/XYw=',
      'testpassword')
  end

  test 'test invalid pbkdf2 password' do
    assert !LegacyPassword.valid_password?(
      'pbkdf2_sha256$15000$fTIiVisympRn$YpT1rs63KVjEvKqOmEtmVbiC5bCxYRUpIQjv3SR/XYw=',
      'testpassword')
  end

  test 'test valid sha1 password' do
    assert LegacyPassword.valid_password?(
      'sha1$74dc91$f9ceeda56dcb38fe7a596ca3bc8a82a30869b319',
      'testpassword')
  end

  test 'test invalid sha1 password' do
    assert !LegacyPassword.valid_password?(
      'sha1$74dc91$f7ceeda56dcb38fe7a596ca3bc8a82a30869b319',
      'testpassword')
  end

  test 'test google auth password first format' do
    assert !LegacyPassword.valid_password?('!', 'testpassword')
  end

  test 'test google auth password second format' do
    assert !LegacyPassword.valid_password?('!jih02fqj23ichjf890adsh80u', 'testpassword')
  end

  test 'test unknown format' do
    assert !LegacyPassword.valid_password?(
      'bcrypt$74dc91$f7ceeda56dcb38fe7a596ca3bc8a82a30869b319',
      'testpassword')
  end
end

