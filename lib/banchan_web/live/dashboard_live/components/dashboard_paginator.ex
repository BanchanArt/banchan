defmodule BanchanWeb.DashboardLive.Components.DashboardPaginator do
  @moduledoc """
  Pagination component for the dashboard page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LivePatch

  @distance 5

  prop page, :struct, required: true

  def render(assigns) do
    ~F"""
    <div class="flex justify-center my-2">
      <div class="btn-group">
        {#if @page.page_number == 1}
          <button class="btn" disabled="true">Prev</button>
        {#else}
          <LivePatch class="btn" to={"?page=#{@page.page_number - 1}"}>Prev</LivePatch>
        {/if}

        {#for num <- start_page(@page.page_number)..end_page(@page.page_number, @page.total_pages)}
          {#if @page.total_pages == 1}
            <button class="btn" disabled="true">{num}</button>
          {#else}
            <LivePatch class={"btn", "btn-active": num == @page.page_number} to={"?page=#{num}"}>{num}</LivePatch>
          {/if}
        {/for}

        {#if @page.page_number != @page.total_pages}
          <LivePatch class="btn" to={"?page=#{@page.page_number + 1}"}>Next</LivePatch>
        {#else}
          <button class="btn" disabled="true">Next</button>
        {/if}
      </div>
    </div>
    """
  end

  def start_page(current_page) when current_page - @distance <= 0, do: 1
  def start_page(current_page), do: current_page - @distance

  def end_page(current_page, 0), do: current_page

  def end_page(current_page, total)
      when current_page <= @distance and @distance * 2 <= total do
    @distance * 2
  end

  def end_page(current_page, total) when current_page + @distance >= total do
    total
  end

  def end_page(current_page, _total), do: current_page + @distance - 1
end
