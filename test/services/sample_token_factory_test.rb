require "test_helper"

class SampleTokenFactoryTest < ActiveSupport::TestCase
  %i[ml_dsa_44 ml_dsa_65 ml_dsa_87].each do |alg_sym|
    alg = alg_sym.to_s.upcase.tr("_", "-")

    test "builds a verifiable #{alg} sample" do
      sample = SampleTokenFactory.new(alg_sym.to_s).call
      assert_equal alg, sample[:algorithm]
      assert sample[:token].present?

      key = JWT::PQ::JWK.import(sample[:jwk])
      _payload, header = JWT.decode(sample[:token], key, true, algorithms: [ alg ])
      assert_equal alg, header["alg"]
    end
  end

  test "raises NotImplementedError for hybrid variants" do
    assert_raises(NotImplementedError) do
      SampleTokenFactory.new("hybrid_ml_dsa_65").call
    end
  end
end
