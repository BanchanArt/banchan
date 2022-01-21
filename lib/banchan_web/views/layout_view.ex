defmodule BanchanWeb.LayoutView do
  use BanchanWeb, :view

  def render(_, assigns) do
    ~F"""
    <!DOCTYPE html />
    <html lang="en" class="h-full bg-base-100" data-theme="">
      <head>
        <meta charset="utf-8">
        {Phoenix.HTML.Tag.csrf_meta_tag()}
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        {live_title_tag(assigns[:page_title] || "Banchan Art")}
        <link phx-track-static rel="stylesheet" href={Routes.static_path(@conn, "/assets/app.css")}>
        <script
          defer
          phx-track-static
          type="text/javascript"
          src={Routes.static_path(@conn, "/assets/app.js")}
        />
      </head>
      <body class="flex flex-col h-full">
        {@inner_content}
      </body>
    </html>
    """
  end
end
