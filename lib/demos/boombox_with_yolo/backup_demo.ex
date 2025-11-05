defmodule BackupDemo do
  def demo() do
    hls_url =
      "https://hoktastream1.webcamera.pl/krakow_cam_da9ab3/krakow_cam_da9ab3.stream/chunks.m3u8?nimblesessionid=352380500"

    {:ok, gen_server} = Demos.BoomboxWithYOLO.Elixir.GenServer.start_link()

    Task.start_link(fn ->
      Boombox.run(
        input: hls_url,
        output: {:stream, video: :image, audio: false}
      )
      |> Enum.reduce(0, fn %Boombox.Packet{} = packet, counter ->
        if rem(counter, 2),
          do: Demos.BoomboxWithYOLO.Elixir.GenServer.process_image(gen_server, packet)

        counter + 1
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
