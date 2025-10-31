defmodule Demos.BoomboxWithYOLO.Elixir do
  def demo() do
    hls_url =
      "https://hd-auth.skylinewebcams.com/live.m3u8?a=rud0i6qs0m1a4c11trrsbie6s4"

    {:ok, gen_server} = __MODULE__.GenServer.start_link()

    Task.start_link(fn ->
      Boombox.run(
        input: hls_url,
        output: {:stream, video: :image, audio: false}
      )
      |> Enum.each(fn %Boombox.Packet{} = packet ->
        __MODULE__.GenServer.process_image(gen_server, packet)
      end)
    end)

    Stream.repeatedly(fn ->
      receive do
        {:processed_packet, packet} -> packet
      end
    end)
    |> Boombox.play({:stream, video: :image, audio: false})
  end
end
