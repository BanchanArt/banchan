defmodule BanchanWeb.StaticLive.Contact do
  @moduledoc """
  Banchan Contact Page
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Markdown

  alias BanchanWeb.Components.Layout

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <#Markdown class="prose">
        # Contact Us

        ## General

        For general support issues, we can be reached at [support@banchan.art](mailto:support@banchan.art).
        We're a very small team, so please give us some time to respond.

        You can also provide feedback or get support via [our support/feedback site](/feedback),
        which inclues a self-serve knowledge base, or
        [our Github repo](https://github.com/BanchanArt/banchan/issues/new/choose).

        We're also available [on our Discord](https://discord.gg/FUkTHjGKJF), where
        most of the project discussion happens. Come chat with us! We're all stronger together.

        We also have [a Twitter account](https://twitter.com/banchan_art)
        and [Mastodon/Fediverse account](https://mastodon.art/@banchan).

        ## Security

        Please direct any security-relared emails at [security@banchan.art](mailto:security@banchan.art) and
        we'll handle it as soon as possible.

        ## Address

        Our mailing address is:

        Banchan Art LLC
        440 N Barranca Ave #8687
        Covina, CA 91723
      </#Markdown>
    </Layout>
    """
  end
end
