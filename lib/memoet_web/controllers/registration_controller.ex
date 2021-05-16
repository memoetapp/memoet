defmodule MemoetWeb.RegistrationController do
  use MemoetWeb, :controller

  alias Memoet.{Accounts, Users, Utils.Timezones}
  alias Memoet.Accounts.Roles

  def new(conn, _params) do
    changeset = Pow.Plug.change_user(conn)

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> user_with_account_transaction(user_params)
    |> Memoet.Repo.transaction()
    |> case do
      {:ok, %{conn: conn}} ->
        conn
        |> put_flash(:info, "Welcome!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, _op, changeset, _changes} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  @spec user_with_account_transaction(Conn.t(), map()) :: Ecto.Multi.t()
  def user_with_account_transaction(conn, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:account, fn _repo, %{} ->
      Accounts.create_account(%{name: "My account"})
    end)
    |> Ecto.Multi.run(:conn, fn _repo, %{account: account} ->
      user_params =
        Enum.into(params, %{
          "account_id" => account.id,
          "role" => Roles.admin()
        })

      case Pow.Plug.create_user(conn, user_params) do
        {:ok, user, conn} ->
          conn =
            conn
            |> put_session(:current_user_id, user.id)
            |> configure_session(renew: true)

          init_user_timezone(user.id, user_params)

          {:ok, conn}

        {:error, changeset, _conn} ->
          {:error, changeset}
      end
    end)
  end

  defp init_user_timezone(user_id, user_params) do
    offset =
      case user_params do
        %{"timezone_offset" => timezone_offset} -> timezone_offset
        _ -> "0"
      end

    timezone = Timezones.get_timezone_from_offset(offset)
    Users.update_srs_config(user_id, %{"timezone" => timezone})
  end
end
