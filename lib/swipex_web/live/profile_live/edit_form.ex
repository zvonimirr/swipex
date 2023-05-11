defmodule SwipexWeb.ProfileLive.EditForm do
  use SwipexWeb, :live_component

  def render(assigns) do
    ~H"""
    <form phx-submit="save" class="flex flex-col gap-4">
      <input type="text" name="name" placeholder="Name" value={@user.name} />
      <textarea name="bio" placeholder="Bio"><%= @user.bio %></textarea>
      <button type="submit" class="bg-blue-300 text-white rounded-md p-3">Save</button>
    </form>
    """
  end
end
