defmodule Demos.BoomboxWithYOLO.Elixir.GenServer do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, parent_process: self())
  end

  def process_image(pid, image) do
    GenServer.cast(pid, {:process_image, image})
  end

  @impl true
  def init(parent_process: parent_process) do
    model =
      YOLO.load(
        model_impl: YOLO.Models.YOLOX,
        model_path: "models/yolox_x.onnx",
        classes_path: "models/only_person_class.json",
        eps: [:coreml]
      )

    state = %{
      parent_process: parent_process,
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

      Task.start_link(fn ->
        {microseconds, detected_objects} =
          :timer.tc(fn ->
            state.model
            |> YOLO.detect(packet.payload, frame_scaler: YOLO.FrameScalers.ImageScaler)
            |> YOLO.to_detected_objects(state.model.classes)
          end)

        microseconds
        |> Membrane.Time.microseconds()
        |> Membrane.Time.as_milliseconds(:round)
        |> IO.inspect(label: "Detection time (ms)")

        GenServer.cast(my_pid, {:detection_complete, detected_objects})
      end)
    end

    state = state |> Map.update!(:packets_qex, &Qex.push(&1, packet))

    {:noreply, %{state | detection_in_progress?: true}}
  end

  @impl true
  def handle_cast({:detection_complete, detected_objects}, state) do
    state.packets_qex
    |> Enum.each(fn packet ->
      payload =
        packet.payload
        |> KinoYOLO.Draw.draw_detected_objects(detected_objects)

      send(state.parent_process, {:processed_packet, %Boombox.Packet{packet | payload: payload}})
    end)

    state = %{state | detection_in_progress?: false, packets_qex: Qex.new()}

    {:noreply, state}
  end
end
