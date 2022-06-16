defmodule BanchanWeb.LayoutView do
  use BanchanWeb, :view

  def render(_, assigns) do
    ~F"""
    <!DOCTYPE html>
    <html lang="en" class="h-full bg-base-100" data-theme="">
      <head>
        <meta charset="utf-8">
        {Phoenix.HTML.Tag.csrf_meta_tag()}
        <meta name="viewport" content="width=device-width, initial-scale=1.0">

        {!-- OpenGraph/Card display --}
        {!-- # TODO: Make title/description/image dynamic based on page.... somehow? --}
        <meta property="og:title" content="Banchan Art">
        <meta property="og:description" content="The co-operative commissions marketplace.">
        <meta property="og:image" content={Routes.static_url(Endpoint, "/images/640x360.png")}>
        <meta property="og:image:width" content="640">
        <meta property="og:image:height" content="360">
        <meta property="og:site_name" content="Banchan Art">
        <meta name="twitter:card" content="summary_large_image">
        <meta name="twitter:site" content="@BanchanArt">
        <meta name="twitter:image:src" content={Routes.static_url(Endpoint, "/images/640x360.png")}>

        {!-- Icons and favicons --}
        <link rel="apple-touch-icon" sizes="76x76" href="/apple-touch-icon.png">
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
        <link rel="manifest" href="/site.webmanifest">
        <meta name="msapplication-TileColor" content="#da532c">

        {!-- Styles and themes --}
        <meta name="theme-color" content="#ffffff">
        {live_title_tag(assigns[:page_title] || "Banchan Art")}
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
