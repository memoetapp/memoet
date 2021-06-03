defmodule MemoetWeb.PageControllerTest do
  use MemoetWeb.ConnCase

  import Memoet.TestUtils

  describe "GET / landing" do
    test "show landing page", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Play your quizzes"
    end
  end

  describe "GET / user" do
    setup [:create_user, :log_in]

    test "show today collection", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Today"
    end
  end
end
