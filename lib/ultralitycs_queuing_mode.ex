defmodule UltralyticsQueuingModel do
  use GenServer

  @stream_rome_url "https://hd-auth.skylinewebcams.com/live.m3u8?a=rud0i6qs0m1a4c11trrsbie6s4"
  # @stream_url "https://hd-auth.skylinewebcams.com/live.m3u8?a=sinpe3sum702opihqi62bpsun2"
  # @stream_usa "https://videos-3.earthcam.com/fecnetwork/30316.flv/playlist.m3u8"
  # @stream_usa "https://videos-3.earthcam.com/fecnetwork/30316.flv/playlist.m3u8?t=FIls8yQUTSX87Ze99E%2BkIl5pKNHChXU%2BpRnPMbD1uctLu2gJxxqwOFwJmkzeiYFP&td=202510140812"
  # @stream_krk "https://hoktastream1.webcamera.pl/krakow_cam_da9ab3/krakow_cam_da9ab3.stream/chunks.m3u8"
  @stream_krk "https://hoktastream1.webcamera.pl/krakow_cam_9a3b91/krakow_cam_9a3b91.stream/chunks.m3u8"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def process_image(pid, image) do
    GenServer.call(pid, {:process_image, image}, 500)
  end

  @impl true
  def init(test_process: test_process) do
    model =
      UltralyticsYolo.load(
        "models/yolo11m/yolo11m.onnx",
        "models/yolo11m/yolo11m_classes.json",
        eps: [:coreml]
      )

    state = %{
      test_process: test_process,
      model: model,
      detection_in_progress?: false,
      packets_qex: Qex.new()
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:process_image, packet}, state) do
    if not state.detection_in_progress? do
      my_pid = self()

      spawn(fn ->
        {microseconds, detected_objects} =
          :timer.tc(fn ->
            state.model
            |> UltralyticsYolo.detect(packet.payload)
            |> YOLO.to_detected_objects(state.model.classes)
          end)

        microseconds
        |> Membrane.Time.microseconds()
        |> Membrane.Time.as_milliseconds(:round)
        |> IO.inspect(label: "Detection time (ms)")

        send(my_pid, {:detection_complete, detected_objects})
      end)
    end

    # image = draw_boxes(image, state)
    state = state |> Map.update!(:packets_qex, &Qex.push(&1, packet))

    {:noreply, %{state | detection_in_progress?: true}}
  end

  @impl true
  def handle_info({:detection_complete, detected_objects}, state) do
    state.packets_qex
    |> Enum.to_list()
    |> length()
    |> IO.inspect(label: "Processing packets")

    state.packets_qex
    |> Enum.each(fn packet ->
      payload =
        packet.payload
        |> KinoYOLO.Draw.draw_detected_objects(detected_objects)

      send(state.test_process, {:processed_packet, %Boombox.Packet{packet | payload: payload}})
    end)

    state = %{state | detection_in_progress?: false, packets_qex: Qex.new()}

    {:noreply, state}
  end

  def demo() do
    {:ok, model} = start_link(test_process: self())

    spawn(fn ->
      Boombox.run(
        input: @stream_rome_url,
        output: {:stream, video: :image, audio: false}
      )
      |> Enum.each(fn %Boombox.Packet{} = packet ->
        GenServer.cast(model, {:process_image, packet})
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
