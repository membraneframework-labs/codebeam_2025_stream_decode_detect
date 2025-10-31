# defmodule Sth do
#   def run() do
#     with Boombox do
#       stream()
#       |> decode()
#       |> detect()
#     end
#   end

#   defp stream() do
#     Boombox.Source.file("path/to/video.mp4")
#   end

#   defp decode(stream) do
#     stream
#     |> Boombox.Decoder.decode()
#   end

#   defp detect(stream) do
#     stream
#     |> Boombox.Detector.yolo()
#   end
# end

# defmodule Demos.BoomboxWithYOLO.Elixir.GenServera do
#   use GenServer

#   def process_image(pid, image) do
#     GenServer.cast(pid, {:process_image, image})
#   end

#   @impl true
#   def handle_cast({:process_image, packet}, state) do
#     if not state.detection_in_progress? do
#       my_pid = self()

#       Task.start_link(fn ->
#         detected_objects =
#           state.model
#           |> YOLO.detect(packet.payload,
#             frame_scaler: YOLO.FrameScalers.ImageScaler
#           )
#           |> YOLO.to_detected_objects(state.model.classes)

#         GenServer.cast(my_pid, {:detection_complete, detected_objects})
#       end)
#     end

#     state = state |> Map.update!(:packets_qex, &Qex.push(&1, packet))

#     {:noreply, %{state | detection_in_progress?: true}}
#   end

#   @impl true
#   def handle_cast({:detection_complete, detected_objects}, state) do
#     state.packets_qex
#     |> Enum.each(fn packet ->
#       payload =
#         packet.payload
#         |> KinoYOLO.Draw.draw_detected_objects(detected_objects)

#       packet = %Boombox.Packet{packet | payload: payload}
#       send(state.parent_process, {:processed_packet, packet})
#     end)

#     state = %{state | detection_in_progress?: false, packets_qex: Qex.new()}

#     {:noreply, state}
#   end
# end
