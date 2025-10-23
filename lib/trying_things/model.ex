defmodule Model do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def process_image(pid, image) do
    GenServer.call(pid, {:process_image, image}, 500)
  end

  @impl true
  def init(_opts) do
    state = %{
      model: nil,
      detected_objects: nil,
      detection_in_progress?: false
    }

    #   {:ok, state, {:continue, :load_model}}
    # end

    # @impl true
    # def handle_continue(:load_model, state) do
    model =
      YOLO.load(
        model_impl: YOLO.Models.YOLOX,
        # model_path: "models/yolox_x.onnx",
        model_path: "models/yolox_s.onnx",
        # model_path: "models/yolox_nano.onnx",
        classes_path: "models/only_person_class.json",
        eps: [:coreml]
        # eps: [:cpu]
      )

    # {:noreply, %{state | model: model}}
    {:ok, %{state | model: model}}
  end

  @impl true
  def handle_call({:process_image, image}, _from, state) do
    if not state.detection_in_progress? do
      my_pid = self()

      spawn(fn ->
        {microseconds, detected_objects} =
          :timer.tc(fn ->
            state.model
            |> YOLO.detect(image, frame_scaler: YOLO.FrameScalers.ImageScaler)
            |> YOLO.to_detected_objects(state.model.classes)
            # |> IO.inspect(label: "Detected objects")
            |> Enum.filter(&(&1.class == "person"))
          end)

        microseconds
        |> Membrane.Time.microseconds()
        |> Membrane.Time.as_milliseconds(:round)
        |> IO.inspect(label: "Detection time (ms)")

        send(my_pid, {:detection_complete, detected_objects})
      end)
    end

    image = draw_boxes(image, state)

    if not state.detection_in_progress? do
      Vix.Vips.Image.write_to_file(image, "output/#{:erlang.unique_integer([:positive])}.jpg")
    end

    {:reply, image, %{state | detection_in_progress?: true}}
  end

  @impl true
  def handle_info({:detection_complete, detected_objects}, state) do
    state = %{
      state
      | detected_objects: detected_objects,
        detection_in_progress?: false
    }

    {:noreply, state}
  end

  defp draw_boxes(image, %{detected_objects: nil} = _state), do: image

  defp draw_boxes(image, state) do
    image
    |> KinoYOLO.Draw.draw_detected_objects(state.detected_objects)
  end
end
