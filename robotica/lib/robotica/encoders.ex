defimpl Jason.Encoder, for: Lifx.Protocol.HSBK do
  def encode(value, opts) do
    Jason.Encode.map(value, opts)
  end
end
