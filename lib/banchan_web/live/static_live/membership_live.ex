defmodule BanchanWeb.StaticLive.Membership do
  @moduledoc """
  Banchan Membership Page
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Markdown

  alias BanchanWeb.Components.Layout

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <#Markdown class="w-full px-4 py-2 mx-auto prose max-w-7xl">
        # Joining Banchan

        What sets co-operatives apart from other kinds of companies is that they are owned
        by their members, who are usually either the workers themselves, the customers, other
        companies, or similar parties whose interest in the co-operative is not to extract
        value, but to work together with other members to increase the value for everyone, not
        for investors.

        We are currently a [Limited Liability Company](https://en.wikipedia.org/wiki/Limited_liability_company),
        a structure often taken by companies structured similar to legal co-operatives as an
        alternative to "Cooperative Corporations", which are a very specific kind of entity
        with specific restrictions and requirements. Our Operating Agreement defines us closer
        to a [Worker Cooperative](https://en.wikipedia.org/wiki/Worker_cooperative) right now,
        where the members are the developers of Banchan itself. This is an initial structure
        to get the company off the ground until we can afford to go through the legal process
        of introducing artists as an official member class with actual ownership.

        ## Membership

        Banchan only has a single class of member right now: Worker-members, which are the developers
        of the platform itself. Once we have the resources to do so, we will introduce a second class
        of members, Artist-members, who will be able to gain membership through their participation
        on the platform.

        The specifics haven't been determined yet, but this is likely to be a combination
        of a minimum number of sales volume, with allowances that take into account other kinds of
        contributions, such as volunteering artwork and designs for the platform itself, doing community
        work for the platform, and so on.

        ## Committees

        Even though only a couple of developers are the "official" members of the company,
        we already have a set of committees open to membership from the larger community meant
        to bootstrap governance, and to help set the parameters that we eventually want for the
        full platform configuration.

        There are currently three committees: the Technical Committee, the Artist Advisory
        Committee, and the Community Committee.

        ### Artist Advisory Committee

        This is a committee of artist who are working with Banchan to help decide what the product
        should be, and how to best fulfill the needs of artists as a community. They are representatives
        of Banchan's artist community at large, and meet on a regular basis.

        When the time comes, the Artist Advisory Committee will be central to defining what Artist
        Membership will look like in Banchan: what the requirements for becoming a member are, what
        the benefits are, and how decisions will be made by the artist member community in Banchan.

        Membership in the Artist Advisory Committee is currently comprised of a handful of working
        artists who have been involved in advising the project from early on, and anyone can join
        as long as the Committee approves them joining.

        While specific technical decisions are the domain of the Technical Committee, the Artist Advisory
        Committee works together with the Technical Committee to help define the product, and to
        agree on what will work, versus what they might initially want.

        ### Technical Committee

        The technical committee is made up of the developers and designers of Banchan, who work
        together to make the Artist Advisory Committee's vision a reality. They are responsible for
        development and maintenance of the product's code, design, and server systems, making sure
        it's the best platform it can be and that it provides the experience artists want to see.

        Members of the Committee are contributors to [Banchan's Open Source
        Platform](https://github.com/BanchanArt/banchan/). Any contributors may join, subject to
        the Committee's consent, typically after significant contributions to the project.

        ### Community Committee

        The final committee is the Community Committee, responsible for the health and safety of the
        overall Banchan community, both on the Banchan platform itself, and in our external community
        channels like our Discord server.

        They are responsible for defining and enforcing the Code of Conduct and, like the other
        committees, are comprised of members of the community willing to share their time for the
        sake of the collective.
      </#Markdown>
    </Layout>
    """
  end
end
