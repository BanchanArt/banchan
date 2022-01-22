defmodule BanchanWeb.StudioLive.Components.ShopTab do
  @moduledoc """
  Component for the Shop tab in the Studio page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.CommissionCard

  prop offerings, :list, required: true
  prop members, :list, required: true
  prop studio, :struct, required: true
  prop current_user_member?, :boolean

  def render(assigns) do
    ~F"""
    <div class="offerings">
      {#for offering <- @offerings}
        <div class="shadow-lg bg-base-200 p-2 my-4 rounded">
          {!-- TODO: Add image --}
          <CommissionCard
            studio={@studio}
            type_id={offering.type}
            name={offering.name}
            description={offering.description}
            image={Routes.static_path(Endpoint, "/images/640x360.png")}
            open={offering.open}
            price_range={offering.price_range}
          />
        </div>
      {/for}
      {#if @current_user_member?}
        <div class="">
          <button type="button" class="btn btn-sm text-center rounded-full px-2 py-1 btn-accent">Add an Offering</button>
        </div>
      {/if}
    </div>
    <div class="col-start-3">
      <div class="shadow-lg bg-base-200 p-2 my-4 rounded">
        <Card>
          <:header>
            Summary
          </:header>
          <div class="content leading-loose">
            <h3 class="text-2xl mt-4">These are all private commissions, meaning: <strong>non-commercial</strong></h3>
            <p class="mt-4">You're only paying for my service to create the work not copyrights or licensing of the work itself!</p>
            <h3 class="text-xl mt-4">I will draw</h3>
            <ul class="list-disc list-inside">
              <li>Humans/humanoids</li>
              <li>anthros+furries/creatures/monsters/animals</li>
              <li>mecha/robots/vehicles</li>
              <li>environments/any type of background</li>
            </ul>
            <h3 class="text-xl mt-4">I will not draw</h3>
            <ul class="list-disc list-inside">
              <li>NSFW</li>
              <li>Fanart</li>
            </ul>
          </div>
        </Card>
      </div>
      <div class="shadow-lg bg-base-200 p-2 my-4 rounded">
        <h2 class="text-xl">Members</h2>
        <div class="studio-members grid grid-cols-4 gap-1">
          {#for member <- @members}
            <figure class="col-span-1">
              <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, member.handle)}>
                <img
                  alt={member.name}
                  class="rounded-full h-24 w-24 flex items-center justify-center"
                  src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
                />
              </LiveRedirect>
            </figure>
          {/for}
        </div>
      </div>
    </div>
    """
  end
end
