defmodule Demos.BoomboxWithYOLO.FromScratch do
  @live_stream_urls %{
    skyline_webcams: "https://hd-auth.skylinewebcams.com/live.m3u8?a=rud0i6qs0m1a4c11trrsbie6s4",
    krakow_main_square_1:
      "https://hoktastream1.webcamera.pl/krakow_cam_9a3b91/krakow_cam_9a3b91.stream/chunks.m3u8",
    krakow_main_square_2:
      "https://hoktastream2.webcamera.pl/krakow_cam_702b61/krakow_cam_702b61.stream/chunks.m3u8?nimblesessionid=638026395"
  }

  def demo() do
    {:ok, gen_server} = __MODULE__.GenServer.start_link()

    Task.start_link(fn ->
      Boombox.run(
        input: @live_stream_urls.skyline_webcams,
        output: {:stream, video: :image, audio: false}
      )
      |> Enum.each(fn %Boombox.Packet{} = packet ->
        __MODULE__.GenServer.process_image(gen_server, packet)
      end)
      |> Enum.reduce(0, fn packet, count ->
        if rem(count, 2) == 0 do
          __MODULE__.GenServer.process_image(gen_server, packet)
        end

        count + 1
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
