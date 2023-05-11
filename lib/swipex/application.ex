defmodule Swipex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SwipexWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Swipex.PubSub},
      # Start the Endpoint (http/https)
      SwipexWeb.Endpoint,
      # Start the Bolt Sips link
      {Bolt.Sips, Application.get_env(:bolt_sips, Bolt)},
      # Start the Presence tracker
      SwipexWeb.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Swipex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SwipexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
