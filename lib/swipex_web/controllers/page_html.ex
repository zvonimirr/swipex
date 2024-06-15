defmodule SwipexWeb.PageHTML do
  use SwipexWeb, :html
  import Phoenix.HTML.Tag

  def index(assigns) do
    ~H"""
    <p>Welcome to Swipex!</p>
    <p>If you have a profile, you can <a class="text-blue-400" href="/login">login here</a>.</p>
    <p>
      If you don't have a profile, you can <a class="text-blue-400" href="/register">register here</a>.
    </p>
    """
  end

  def register(assigns) do
    ~H"""
    <div class="max-w-md mx-auto">
      <p>Register for Swipex</p>
      <form action="/register" method="post" class="flex flex-col gap-4">
        <input type="text" name="name" placeholder="Name" />
        <input type="password" name="password" placeholder="Password" />
        <%= csrf_input_tag("/login") %>
        <input type="submit" value="Register" />
      </form>
    </div>
    """
  end
end
