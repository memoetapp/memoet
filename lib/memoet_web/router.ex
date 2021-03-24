defmodule MemoetWeb.Router do
  use MemoetWeb, :router

  use Pow.Phoenix.Router

  use Pow.Extension.Phoenix.Router,
    extensions: [PowResetPassword]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, {MemoetWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(MemoetWeb.APIAuthPlug, otp_app: :memoet)
  end

  pipeline :api_protected do
    plug(Pow.Plug.RequireAuthenticated, error_handler: MemoetWeb.APIAuthErrorHandler)
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :not_authenticated do
    plug Pow.Plug.RequireNotAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  scope "/", MemoetWeb do
    pipe_through [:browser, :not_authenticated]

    get "/signup", RegistrationController, :new, as: :signup
    post "/signup", RegistrationController, :create, as: :signup
  end

  scope "/", MemoetWeb do
    pipe_through [:browser, :protected]

    get("/search", DeckController, :search, as: :search)
  end

  # Decks & notes html
  scope "/decks", MemoetWeb do
    pipe_through [:browser, :protected]

    resources("/", DeckController) do
      resources("/notes", NoteController)
    end

    get("/:id/clone", DeckController, :clone, as: :deck)

    get("/:id/practice", DeckController, :practice, as: :practice)
    put("/:id/practice", DeckController, :answer, as: :practice)
  end

  # Decks & notes json
  scope "/api/decks", MemoetWeb do
    pipe_through([:api, :api_protected])

    resources("/", DeckAPIController) do
      resources("/notes", NoteAPIController)
    end

    get("/:id/practice", DeckAPIController, :practice)
    put("/:id/practice", DeckAPIController, :answer)
  end

  scope "/user", MemoetWeb do
    pipe_through [:browser, :protected]

    get("/account", UserController, :show, as: :account)
    post("/token", UserController, :refresh_api_token, as: :account)

    get("/config/srs", SrsConfigController, :edit, as: :srs_config)
    put("/config/srs", SrsConfigController, :update, as: :srs_config)

    post("/files", UploadController, :create, as: :upload)
  end

  scope "/" do
    pipe_through [:browser]

    pow_routes()
    pow_extension_routes()

    get "/community/:id/practice", MemoetWeb.DeckController, :public_practice, as: :community_deck
    put("/community/:id/practice", MemoetWeb.DeckController, :public_answer, as: :community_deck)

    get "/community/:id", MemoetWeb.DeckController, :public_show, as: :community_deck
    get "/community", MemoetWeb.DeckController, :public_index, as: :community_deck
    get "/", MemoetWeb.PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", MemoetWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: MemoetWeb.Telemetry
    end
  end
end
