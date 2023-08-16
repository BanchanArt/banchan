defmodule Banchan.CompileEnv do
  @moduledoc """
  Small utility for conditional compilation based on envs.
  Ref: https://elixirforum.com/t/conditional-import-fails-to-compile/42907/2
  """
  defmacro only_in(envs, body) do
    if Application.get_env(:banchan, :env) in List.wrap(envs) do
      body[:do]
    else
      body[:else]
    end
  end
end
