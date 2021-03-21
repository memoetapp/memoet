defmodule MemoetWeb.NoteAPIView do
  use MemoetWeb, :view

  def render("index.json", %{notes: notes, metadata: metadata}) do
    %{
      data: render_many(notes, __MODULE__, "basic.json", as: :note),
      metadata: render_one(metadata, __MODULE__, "metadata.json", as: :metadata)
    }
  end

  def render("create.json", %{note: note}) do
    %{data: render_one(note, __MODULE__, "expanded.json", as: :note)}
  end

  def render("update.json", %{note: note}) do
    %{data: render_one(note, __MODULE__, "expanded.json", as: :note)}
  end

  def render("show.json", %{note: note}) do
    %{data: render_one(note, __MODULE__, "expanded.json", as: :note)}
  end

  def render("basic.json", %{note: note}) do
    %{
      id: note.id,
      title: note.title
    }
  end

  def render("expanded.json", %{note: note}) do
    %{
      id: note.id,
      title: note.title,
      image: note.image,
      content: note.content,
      type: note.type,
      options: render_many(note.options, __MODULE__, "option.json", as: :option),
      hint: note.hint,
      created_at: note.inserted_at,
      updated_at: note.updated_at
    }
  end

  def render("option.json", %{option: option}) do
    %{
      id: option.id,
      content: option.content,
      correct: option.correct,
      image: option.image
    }
  end

  def render("metadata.json", %{metadata: metadata}) do
    %{
      total_count: metadata.total_count,
      limit: metadata.limit,
      before: metadata.before,
      after: metadata.after
    }
  end
end
