defmodule UltralyticsYolo do
  import Nx.Defn

  @enforce_keys [:model, :classes, :shapes]
  defstruct @enforce_keys

  def load(model_path, classes_path, opts \\ []) do
    eps = Keyword.get(opts, :eps, [:coreml])
    model = Ortex.load(model_path, eps)

    classes =
      classes_path
      |> File.read!()
      |> :json.decode()
      |> Enum.with_index(fn class, idx -> {idx, class} end)
      |> Enum.into(%{})

    {[{_, _, input_shape}], [{_, _, output_shape}]} =
      Ortex.Native.show_session(model.reference)

    # shapes = %{input: List.to_tuple(input_shape), output: List.to_tuple(output_shape)}
    shapes = %{input: List.to_tuple(input_shape)}

    %__MODULE__{
      model: model,
      classes: classes,
      shapes: shapes
    }
  end

  def detect(model, image) do
    {input_nx, scaling_config} = preprocess(model, image)
    output_nx = run(model, input_nx)
    postprocess(model, output_nx, scaling_config)
  end

  def preprocess(model, image) do
    {_, _channels, height, width} = model.shapes.input
    {image_nx, image_scaling} = fit(image, {height, width})
    input_nx = do_preprocess(image_nx)

    {input_nx, image_scaling}
  end

  def fit(image, target_shape) do
    image_scaling =
      %{padding: {width_padding, height_padding}} =
      calculate_resized_shape_and_padding(image, target_shape)

    image_nx =
      image
      |> image_resize(image_scaling)
      |> image_to_nx()
      # {height, width, 3=_channels}
      |> Nx.pad(114, [
        {floor(height_padding), ceil(height_padding), 0},
        {floor(width_padding), ceil(width_padding), 0},
        {0, 0, 0}
      ])

    {image_nx, image_scaling}
  end

  defp image_resize(image, scale_config) do
    {scale_w, _scale_h} = scale_config.scale
    Image.resize!(image, scale_w)
  end

  defp image_to_nx(image) do
    {backend, _} = Nx.default_backend()
    Image.to_nx!(image, backend: backend)
  end

  defp calculate_resized_shape_and_padding(image, {model_input_height, model_input_width}) do
    {image_width, image_height, _channels} = Image.shape(image)

    width_ratio = model_input_width / image_width
    height_ratio = model_input_height / image_height
    ratio = min(width_ratio, height_ratio)

    {scaled_width, scaled_height} =
      if width_ratio < height_ratio do
        # landscape, width = model input size
        {model_input_width, ceil(image_height * ratio)}
      else
        # portrait or squared, height = model input size
        {ceil(image_width * ratio), model_input_height}
      end

    # we are going to add padding to match the model input shape
    width_padding = (model_input_width - scaled_width) / 2
    height_padding = (model_input_height - scaled_height) / 2

    %{
      scale: {ratio, ratio},
      padding: {width_padding, height_padding}
    }
  end

  defnp do_preprocess(image_nx) do
    image_nx
    # RGB to BGR
    |> Nx.reverse(axes: [2])
    |> Nx.as_type({:f, 32})
    # normalizing (values between 0 and 1)
    |> Nx.divide(255)
    # transpose to a `{3, 640, 640}`
    |> Nx.transpose(axes: [2, 0, 1])
    # add another axis {3, 640, 640} -> {1, 3, 640, 640}
    |> Nx.new_axis(0)
  end

  def run(model, input_nx) do
    {output} = Ortex.run(model.model, input_nx)
    Nx.backend_transfer(output)
  end

  def postprocess(model, output_nx, scaling_config) do
    prob_threshold = 0.25
    iou_threshold = 0.45

    output_nx
    |> YOLO.NMS.run(prob_threshold: prob_threshold, iou_threshold: iou_threshold, transpose: true)
    |> scale_bboxes_to_original(scaling_config)
  end

  def scale_bboxes_to_original(bboxes, scaling_config) do
    # h_input = 640 - 2*140 = 360
    # w_input = 640
    %{padding: {width_padding, height_padding}, scale: {ratio, _}} = scaling_config

    Enum.map(bboxes, fn [cx, cy, w, h, prob, class] ->
      [
        round((cx - width_padding) / ratio),
        round((cy - height_padding) / ratio),
        round(w / ratio),
        round(h / ratio),
        prob,
        class
      ]
    end)
  end
end
