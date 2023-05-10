import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :swipex, SwipexWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "jZKKmUX4BNkGpU2N8ZR7ET3smmdQwF4krKv5la5DiCVgij2rRewVrrJuoc2jg9YQ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
