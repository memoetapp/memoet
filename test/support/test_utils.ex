defmodule Memoet.TestUtils do
  alias Memoet.Factory

  def create_user(_) do
    {:ok, user: Factory.insert(:user)}
  end

  def log_in(%{user: user, conn: conn}) do
    conn = Pow.Plug.assign_current_user(conn, user, otp_app: :memoet)
    {:ok, conn: conn}
  end
end
