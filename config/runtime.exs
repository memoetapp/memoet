import Config
require Logger
:ok == Application.ensure_started(:logger)


exit_from_exception = fn exception, message ->
  Logger.error(exception.message)
  Logger.error(message)
  Logger.flush()
  System.halt(1)
end

if config_env() == :prod do
  # Database
  try do
    database_url = System.fetch_env!("DATABASE_URL")
    ssl = System.get_env("DATABASE_SSL") in [1, "1", "true", "TRUE"]
    ca_cert_pem = System.get_env("DATABASE_CERT")

    ssl_opts =
      if ca_cert_pem not in [nil, ""] do
        cacerts =
          ca_cert_pem
          |> :public_key.pem_decode()
          |> Enum.map(fn {_, der_or_encrypted_der, _} -> der_or_encrypted_der end)

        [verify: :verify_peer, cacerts: cacerts]
      else
        []
      end

    socket_opts = if System.get_env("DATABASE_IPV6") in [1, "1", "true", "TRUE"] do [:inet6] else [] end

    config :memoet, Memoet.Repo,
      ssl: ssl,
      socket_options: socket_opts,
      url: database_url,
      ssl_opts: ssl_opts,
      pool_size: String.to_integer(System.get_env("DATABASE_POOL") || "10")
  rescue
    e ->
      exit_from_exception.(e, """
      You must provide the DATABASE_URL environment variable in the format:
      postgres://user:password/database
      """)
  end

  # Secret Key Base
  try do
    secret_key_base = System.fetch_env!("SECRET_KEY_BASE")

    config :memoet, MemoetWeb.Endpoint,
      http: [
        port: String.to_integer(System.get_env("PORT") || "4000"),
        transport_options: [socket_opts: [:inet6]]
      ],
      secret_key_base: secret_key_base
  rescue
    e ->
      exit_from_exception.(e, """
      You must set SECRET_KEY_BASE.
      This should be a strong secret with a length
      of at least 64 characters.
      One way to create a strong secret is running the following command:
      head -c 48 /dev/urandom | base64
      """)
  end

  # Endpoint
  url_host = System.get_env("URL_HOST")
  url_port = String.to_integer(System.get_env("URL_PORT") || "80")
  url_schema = System.get_env("URL_SCHEMA")

  url_schema =
    cond do
      url_schema not in [nil, ""] -> url_schema
      url_port == 443 -> "https"
      true -> "http"
    end

  if url_host not in [nil, ""] do
    config :memoet, MemoetWeb.Endpoint,
      url: [scheme: url_schema, host: url_host, port: url_port]
  else
    Logger.warn("""
    You have not configured the application URL. Defaulting to http://localhost.
    Use the following environment variables:
    - URL_HOST
    - URL_PORT (defaults to 80)
    - URL_SCHEMA (defaults to "https" for port 443, otherwise to "http")
    """)
  end
end
