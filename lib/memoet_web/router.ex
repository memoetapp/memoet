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
    # FIXME: Better way to handle API endpoint, now it receive json and return html (!?)
    # We use this plug for now to avoid error when sending json requests
    plug :fetch_flash
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

  scope "/decks", MemoetWeb do
    pipe_through [:browser, :protected]

    resources("/", DeckController) do
      resources("/notes", NoteController, except: [:index])
    end

    get("/:id/clone", DeckController, :clone, as: :deck)

    get("/:id/review", DeckController, :due, as: :review_card)
    put("/:id/review", DeckController, :review, as: :review_card)
  end

  scope "/user", MemoetWeb do
    pipe_through [:browser, :protected]

    get("/account", UserController, :show, as: :account)
    post("/token", UserController, :refresh_api_token, as: :account)

    get("/config/srs", SrsConfigController, :edit, as: :srs_config)
    put("/config/srs", SrsConfigController, :update, as: :srs_config)
  end

  # TODO: Make this endpoint way more better!
  scope "/api", MemoetWeb do
    pipe_through([:api, :api_protected])

    resources("/decks", DeckController) do
      resources("/notes", NoteController, except: [:index])
    end
  end

  scope "/" do
    pipe_through [:browser]

    pow_routes()
    pow_extension_routes()

    get "/community/:id", MemoetWeb.DeckController, :show, as: :community_deck
    get "/community", MemoetWeb.DeckController, :public, as: :community_deck
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
