# Stream, Decode, Detect

**How to run it**

To run this demo, you have to
 - make sure that HLS playlist address used in [Demos.BoomboxWithYOLO.Elixir.demo/0](https://github.com/membraneframework-labs/codebeam_2025_stream_decode_detect/blob/26fdcede26cb5ec482c4331d5098aa61f0afcc98/lib/demos/boombox_with_yolo/elixir.ex#L12) is valid
 - download ONNX model and classes data so that paths used is `Demos.BoomboxWithYOLO.Elixir.GenServer.init/1` are correct (follow instructions from https://github.com/poeticoding/yolo_elixir/blob/main/examples/yolox.livemd#download-yolox-model)

In order to get a new HLS playslit address, you can 
- enter a webpage like [this](https://www.skylinewebcams.com/en/webcam/italia/liguria/imperia/festival-sanremo-ariston.html)
- inspect the webpage
- go to Network tab
- add "m3u8" filter
- and look for a playlist address. It should contain m3u8 extension, but it doesn't necessarily has to be at the end of the address. 

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/trying_things>.

