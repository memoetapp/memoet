defmodule MemoetWeb.UserController do
  use MemoetWeb, :controller

  alias Memoet.Users
  alias Memoet.Users.User
  alias Memoet.Str

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, _params) do
    user = Pow.Plug.current_user(conn)
    # Non-cached version
    user = Users.find_user_by_id(user.id)
    render(conn, "show.html", user: user)
  end

  @spec refresh_api_token(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def refresh_api_token(conn, _params) do
    user = Pow.Plug.current_user(conn)

    case Users.refresh_api_token(user) do
      {:ok, %User{} = _user} ->
        conn
        |> put_flash(:info, "Refresh token success!")
        |> redirect(to: Routes.account_path(conn, :show))

      {:error, changeset} ->
        conn
        |> put_flash(:error, Str.changeset_error_to_string(changeset))
        |> redirect(to: Routes.account_path(conn, :show))
    end
  end
end
