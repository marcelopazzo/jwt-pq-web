class SamplesController < ApplicationController
  def show
    alg = params[:id]
    cache_key = [ "sample", alg, JWT::PQ::VERSION ].join(":")

    sample = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      SampleTokenFactory.new(alg).call
    end

    render json: sample
  rescue NotImplementedError => e
    render json: { error: "not_implemented", detail: e.message }, status: :not_implemented
  end
end
