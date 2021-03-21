defmodule MemoetWeb.DeckAPIView do
  use MemoetWeb, :view

  alias MemoetWeb.NoteAPIView

  def render("index.json", %{decks: decks, metadata: metadata}) do
    %{
      data: render_many(decks, __MODULE__, "expanded.json", as: :deck),
      metadata: render_one(metadata, __MODULE__, "metadata.json", as: :metadata)
    }
  end

  def render("create.json", %{deck: deck}) do
    %{data: render_one(deck, __MODULE__, "expanded.json", as: :deck)}
  end

  def render("update.json", %{deck: deck}) do
    %{data: render_one(deck, __MODULE__, "expanded.json", as: :deck)}
  end

  def render("show.json", %{deck: deck}) do
    %{data: render_one(deck, __MODULE__, "expanded.json", as: :deck)}
  end

  def render("practice.json", %{card: card}) do
    case card do
      nil -> %{data: nil}
      _ -> %{data: render_one(card, __MODULE__, "card.json", as: :card)}
    end
  end

  def render("card.json", %{card: card}) do
    %{
      id: card.id,
      card_type: card.card_type,
      card_queue: card.card_queue,
      due: card.due,
      interval: card.interval,
      ease_factor: card.ease_factor,
      reps: card.reps,
      lapses: card.lapses,
      remaining_steps: card.remaining_steps,
      created_at: card.inserted_at,
      updated_at: card.updated_at,
      note: render_one(card.note, NoteAPIView, "expanded.json", as: :note)
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

  def render("expanded.json", %{deck: deck}) do
    %{
      id: deck.id,
      name: deck.name,
      public: deck.public,
      source_id: deck.source_id,
      created_at: deck.inserted_at,
      updated_at: deck.updated_at
    }
  end
end
