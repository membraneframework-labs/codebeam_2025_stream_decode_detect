import Config

config :ortex, Ortex.Native, features: [:coreml]
config :nx, :default_backend, EXLA.Backend
config :ex_hls, debug_verbose: true
