defmodule MemoetWeb.UploadController do
  use MemoetWeb, :controller

  alias Memoet.FileUploader

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"file" => file}) do
    user = Pow.Plug.current_user(conn)

    scope = %{
      file_name: Ecto.UUID.generate(),
      id: user.id
    }

    case FileUploader.store({file, scope}) do
      {:ok, file_name} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            file_name: file_name,
            file_path: FileUploader.url({file_name, scope})
          }
        })

      {:error, errors} ->
        conn
        |> put_status(400)
        |> json(%{error: %{status: 400, message: "Couldn't upload file", errors: errors}})
    end
  end
end
