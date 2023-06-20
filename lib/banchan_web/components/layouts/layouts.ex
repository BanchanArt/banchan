defmodule BanchanWeb.Layouts do
  @moduledoc """
  Layouts and dead views are loaded through here.
  """
  use BanchanWeb, :html

  embed_sface "email.sface"
  embed_sface "root.sface"
end
