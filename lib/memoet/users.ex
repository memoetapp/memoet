defmodule Memoet.Users do
  @moduledoc """
  Users context
  """
  import Ecto.Query

  alias Memoet.Repo
  alias Memoet.Users.{User, SrsConfig}

  @spec find_user_by_email(binary()) :: User.t() | nil
  def find_user_by_email(email) do
    User
    |> where(email: ^email)
    |> Repo.one()
  end

  # SRS config
  @spec get_srs_config(integer()) :: SrsConfig.t() | nil
  def get_srs_config(user_id) do
    SrsConfig
    |> where(user_id: ^user_id)
    |> Repo.one()
    |> case do
      %SrsConfig{} = config ->
        config

      nil ->
        create_srs_config(user_id)
    end
  end

  defp create_srs_config(user_id) do
    %SrsConfig{}
    |> SrsConfig.changeset(%{user_id: user_id})
    |> Repo.insert()
    |> case do
      {:ok, config} -> config
      {:serror, _reason} -> nil
    end
  end

  @spec update_srs_config(integer(), map()) ::
          {:ok, SrsConfig.t()} | {:error, Ecto.Changeset.t()}
  def update_srs_config(user_id, params) do
    get_srs_config(user_id)
    |> SrsConfig.changeset(params)
    |> Repo.update()
  end
end
