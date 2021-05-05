defmodule MemoetWeb.SrsConfigController do
  use MemoetWeb, :controller

  alias Memoet.{Users, Users.SrsConfig, SRS}

  @spec edit(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def edit(conn, _params) do
    user = Pow.Plug.current_user(conn)
    srs_config = Users.get_srs_config(user.id)
    changeset = SrsConfig.changeset(srs_config, %{})
    render(conn, "edit.html", srs_config: srs_config, changeset: changeset)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"srs_config" => srs_config_params} = _params) do
    user = Pow.Plug.current_user(conn)
    params = Map.merge(srs_config_params, %{"user_id" => user.id})

    case Users.update_srs_config(user.id, params) do
      {:ok, srs_config} ->
        # Cache new scheduler
        SRS.set_config(user.id, srs_config)
        conn
        |> put_flash(:info, "Update config success!")
        |> redirect(to: Routes.srs_config_path(conn, :edit))

      {:error, changeset} ->
        srs_config = Users.get_srs_config(user.id)
        conn
        |> put_flash(:error, "Fail to update config!")
        |> render("edit.html", srs_config: srs_config, changeset: changeset)
    end
  end
end
