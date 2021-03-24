defmodule Memoet.FileUploader do
  use Waffle.Definition

  # Include ecto support (requires package waffle_ecto installed):
  # use Waffle.Ecto.Definition

  @versions [:original]
  @extensions_whitelist ~w(.jpg .jpeg .gif .png .svg)

  # To add a thumbnail version:
  # @versions [:original, :thumb]

  # Allow public_read for now
  def acl(:original, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    @extensions_whitelist |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  # def transform(:thumb, _) do
  #   {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250 -format png", :png}
  # end

  # Override the persisted filenames:
  def filename(_version, {_file, scope}) do
    "#{scope.file_name}"
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "uploads/files/#{scope.id}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(_version, _scope) do
    "https://placehold.it/500x500"
  end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  def s3_object_headers(_version, {file, _scope}) do
    [
      content_type: MIME.from_path(file.file_name),
      cache_control: "max-age=2160000"
    ]
  end
end
