defmodule Demo do
  @moduledoc """
  Documentation for `Demo`.
  """

  # @stream_krk_url "https://hoktastream2.webcamera.pl/krakow_cam_702b61/krakow_cam_702b61.stream/playlist.m3u8"
  # @stream_san_marco_url "https://hd-auth.skylinewebcams.com/live.m3u8?a=sinpe3sum702opihqi62bpsun2"
  @stream_rome_url "https://hd-auth.skylinewebcams.com/live.m3u8?a=sinpe3sum702opihqi62bpsun2"
  # @stream_de_la_playa "https://hd-auth.skylinewebcams.com/live.m3u8?a=sinpe3sum702opihqi62bpsun2"

  @doc """
  Hello world.

  ## Examples

      iex> TryingThings.hello()
      :world

  """
  def run do
    {:ok, model} = Model.start_link()

    Process.sleep(10_000)

    Boombox.run(input: @stream_rome_url, output: {:stream, video: :image, audio: false})
    |> Stream.map(fn %Boombox.Packet{} = packet ->
      # packet.kind |> IO.inspect(label: "Packet kind")

      payload = Model.process_image(model, packet.payload)
      %Boombox.Packet{packet | payload: payload}
    end)
    |> Boombox.play(input: {:stream, video: :image, audio: false})
  end

  #   process_image(packet.payload, model)
  # |> Vix.Vips.Image.write_to_file("output/#{:erlang.unique_integer([:positive])}.jpg")

  # defp process_image(image, model) do
  #   detected_objects =
  #     model
  #     # here we are passing the image and we need the YOLO.FrameScalers.ImageScaler
  #     # instead of the default `YOLO.FrameScalers.EvisionScaler`
  #     |> YOLO.detect(image, frame_scaler: YOLO.FrameScalers.ImageScaler)
  #     |> YOLO.to_detected_objects(model.classes)

  #   image
  #   |> KinoYOLO.Draw.draw_detected_objects(detected_objects)
  # end
end
