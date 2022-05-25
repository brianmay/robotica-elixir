import Config

config :logger,
  backends: [RingLogger],
  level: :info,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

if Mix.target() != :host do
  config :tzdata, :data_dir, "/root/elixir_tzdata_data"
end
