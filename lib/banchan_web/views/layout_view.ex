defmodule BanchanWeb.LayoutView do
  use BanchanWeb, :view

  def render(_, assigns) do
    ~F"""
    <!DOCTYPE html>
    <html lang="en" class="h-full bg-base-100" data-theme="">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1">
        {live_title_tag(assigns[:page_title] || "Art Goes Here", prefix: "Banchan Art | ")}
        {Phoenix.HTML.Tag.csrf_meta_tag()}

        {!-- OpenGraph/Card display --}
        <meta property="og:site_name" content="Banchan Art">
        <meta property="og:title" content={"Banchan Art | #{assigns[:page_title] || "Art Goes Here"}"}>
        <meta
          property="og:description"
          content={assigns[:page_description] ||
            "The co-operative commissions marketplace."}
        />
        {#if assigns[:page_small_image]}
          <meta property="og:image" content={assigns[:page_small_image]}>
          <meta name="twitter:image:src" content={assigns[:page_image]}>
          <meta name="twitter:card" content="summary">
        {#elseif assigns[:page_image]}
          <meta property="og:image" content={assigns[:page_image]}>
          <meta name="twitter:image:src" content={assigns[:page_image]}>
          <meta name="twitter:card" content="summary_large_image">
        {/if}
        <meta name="twitter:site" content="@BanchanArt">

        {!-- Icons and favicons --}
        <link rel="apple-touch-icon" sizes="76x76" href="/apple-touch-icon.png">
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
        <link rel="manifest" href="/site.webmanifest">
        <meta name="msapplication-TileColor" content="#da532c">

        {!-- Styles and themes --}
        <meta name="theme-color" content="#ffffff">
        <link phx-track-static rel="stylesheet" href={Routes.static_path(@conn, "/assets/app.css")}>

        <script
          defer
          phx-track-static
          type="text/javascript"
          src={Routes.static_path(@conn, "/assets/app.js")}
        />
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end
