# defmodule Demo.ModelFilter do
#   use Membrane.Filter

#   def_input_pad :input, accepted_format: _any
#   def_output_pad :output, accepted_format: _any

#   def_options model: [spec: struct() | nil, default: nil]

#   @impl true
#   def handle_init(opts) do
#     {:ok, opts}
#   end

#   @impl true
#   def handle_pad_added(:output, _ctx, state) do
#     {:ok, state}
#   end
# end

defmodule Demo.Pipeline do
  use Membrane.Pipeline
  @stream_url "https://hd-auth.skylinewebcams.com/live.m3u8?a=sinpe3sum702opihqi62bpsun2"

  @impl true
  def handle_init(_ctx, _opts) do
    spec =
      child(:ingress_boombox, %Boombox.Bin{input: @stream_url})
      |> via_out(:output, options: [kind: :video])
      |> child(%Membrane.Transcoder{output_stream_format: RawAudio})
      |> child(:model, Demo.ModelFilter)
      |> via_in(:input, options: [kind: :video])
      |> child(:egress_boombox, %Boombox.Bin{output: :player})

    {[spec: spec], %{}}
  end
end
