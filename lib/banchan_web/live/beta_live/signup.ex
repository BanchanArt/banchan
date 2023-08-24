defmodule BanchanWeb.BetaLive.Signup do
  @moduledoc """
  LiveView for the Banchan beta signup form.
  """
  use BanchanWeb, :live_view

  alias Banchan.Accounts

  alias Surface.Components.Form
  alias Surface.Components.Form.{EmailInput, Submit}

  alias BanchanWeb.Components.{Icon, Layout}

  @impl true
  def handle_event("submit", %{"email" => email}, socket) do
    with {:ok, req} <- Accounts.add_invite_request(email),
         {:ok, _} <- Accounts.deliver_artist_invite_confirmation(req) do
      {:noreply,
       socket
       |> push_navigate(to: Routes.beta_confirmation_path(Endpoint, :show))}
    else
      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email")
         |> redirect(to: Routes.beta_signup_path(Endpoint, :new))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <div id="above-fold" class="mt-20 md:px-4">
        <div class="min-h-screen hero">
          <div class="flex flex-col hero-content md:flex-row">
            <div class="flex flex-col items-center max-w-2xl gap-4 p-4 md:gap-10">
              <div class="text-5xl font-bold">
                A Platform for
                <span class="md:whitespace-nowrap">Online Art Commissions</span>
              </div>
              <div class="w-full pt-2 text-2xl font-semibold">
                <span class="font-bold text-primary">Owned by the Artists</span>
              </div>
              <div class="pt-2 text-2xl font-semibold">
                Banchan is a
                <a
                  href="https://en.wikipedia.org/wiki/Platform_cooperative"
                  class="font-bold text-primary link"
                  target="_blank"
                  rel="noopener noreferrer"
                >co-op</a>: Artists and workers make the
                <span class="font-bold text-primary">decisions</span> and split
                the <span class="font-bold text-primary">profits</span>, not
                executives and shareholders. One person, one vote. One
                <span class="font-bold text-primary">community</span>.
              </div>
              <div id="top-cta" class="flex flex-col items-start w-full gap-2 py-4 rounded-lg">
                <div class="flex flex-col gap-2 md:flex-row">
                  <div class="text-xl font-medium">
                    Join the
                    <span class="font-bold text-primary">Revolution</span>!
                  </div>
                  <div>(or at least the Closed Beta)</div>
                </div>
                <Form for={%{}} as={:signup} submit="submit" class="w-full max-w-xl py-4 form-control">
                  <div class="input-group">
                    <EmailInput
                      name={:email}
                      class="rounded-lg input input-bordered grow"
                      opts={placeholder: "youremail@example.com", required: true}
                    />
                    <Submit class="rounded-lg btn btn-primary">
                      Sign Up
                    </Submit>
                  </div>
                </Form>
              </div>
              <div id="scroll-down-please">
                <Icon name="arrow-down" size="6" label="scroll-down" />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div id="comms" class="px-2 md:px-4">
        <div class="min-h-screen hero">
          <div class="grid grid-cols-1 hero-content md:grid-cols-2">
            <div class="flex flex-col gap-4">
              <div class="text-4xl font-semibold">
                A
                <span class="font-bold text-primary whitespace-nowrap">Complete</span>
                Commissions Experience
              </div>
              <div class="text-2xl font-semibold">
                Discovery, communications, delivery, invoicing, payments.
                <span class="text-primary whitespace-nowrap">All in one spot</span>.
              </div>
            </div>
            <div class="rounded-lg themed dark outline outline-primary outline-3">
              <img
                alt="Screenshot of an ongoing commission. The title is 'Please draw my OC'. There are various elements of interest on the page, such as a status, a summary of what is being paid for, and some art on the page."
                src={Routes.static_path(Endpoint, "/images/banchan-comm-dark.png")}
                class="rounded-lg"
              />
            </div>
            <div class="rounded-lg themed light outline outline-primary outline-3">
              <img
                alt="Screenshot of an ongoing commission. The title is 'Please draw my OC'. There are various elements of interest on the page, such as a status, a summary of what is being paid for, and some art on the page."
                src={Routes.static_path(Endpoint, "/images/banchan-comm-light.png")}
                class="rounded-lg"
              />
            </div>
          </div>
        </div>
      </div>
      <div id="payment" class="px-2 md:px-4">
        <div class="min-h-screen hero">
          <div class="grid grid-cols-1 gap-4 hero-content md:grid-cols-2">
            <div class="flex flex-col gap-4 md:order-2">
              <div class="text-4xl font-semibold">
                Pay or get paid. <span class="text-primary">Securely</span>.
                Wherever you are.
              </div>
              <div class="text-2xl font-semibold">
                Art and payments are held until
                <span class="text-primary">both parties</span>
                are ready. <span class="text-primary">No more</span> runaway
                clients.
              </div>
              <div class="text-2xl font-semibold">
                <span class="text-primary">135+</span> currencies. <span class="text-primary">80+</span> countries.
              </div>
              <div class="text-2xl font-semibold">
                <span class="text-primary">Prepayments</span> built-in.
              </div>
              <div class="text-2xl font-semibold">
                <span class="text-primary">VAT</span> and <span class="text-primary">Sales Tax</span> handled for you.
              </div>
              <div class="text-2xl font-semibold">
                <span class="text-primary">1099k</span> for US artists.
              </div>
            </div>
            <div class="md:order-1">
              <div class="rounded-lg themed dark outline outline-primary outline-3">
                <img
                  alt="Screenshot showing the Banchan invoicing feature. There is a message saying that the commission is complete, and a message box that says Payment Succeeded, $120, plug a Release Now button. There is artwork attached to the message."
                  src={Routes.static_path(Endpoint, "/images/banchan-invoice-dark.png")}
                  class="rounded-lg"
                />
              </div>
              <div class="rounded-lg themed light outline outline-primary outline-3">
                <img
                  alt="Screenshot showing the Banchan invoicing feature. There is a message saying that the commission is complete, and a message box that says Payment Succeeded, $120, plug a Release Now button. There is artwork attached to the message."
                  src={Routes.static_path(Endpoint, "/images/banchan-invoice-light.png")}
                  class="rounded-lg"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div id="shop" class="px-2 md:px-4">
        <div class="min-h-screen hero">
          <div class="grid grid-cols-1 gap-10 hero-content md:grid-cols-2">
            <div class="flex flex-col gap-4">
              <div class="text-5xl font-semibold">
                <span class="text-primary">Curate</span> Your Profile
              </div>
              <div class="text-2xl font-semibold">
                <span class="text-primary">Shops</span> with customizable
                offerings with slots and options support, as well as studio
                portfolios.
              </div>
              <div class="text-2xl font-semibold">
                <span class="text-primary">User profiles</span> to share your art
                on and help you discover new artists.
              </div>
            </div>
            <div>
              <div class="rounded-lg themed dark outline outline-primary outline-3">
                <img
                  alt="Screenshot of an example Banchan shop, including a beautiful header graphic, the name of the studio, and three separate offerings: Flat Full Color, Full Color Shaded, and Sketch. They each have 3 slots available."
                  src={Routes.static_path(Endpoint, "/images/banchan-shop-dark.png")}
                  class="rounded-lg"
                />
              </div>
              <div class="rounded-lg themed light outline outline-primary outline-3">
                <img
                  alt="Screenshot of an example Banchan shop, including a beautiful header graphic, the name of the studio, and three separate offerings: Flat Full Color, Full Color Shaded, and Sketch. They each have 3 slots available."
                  src={Routes.static_path(Endpoint, "/images/banchan-shop-light.png")}
                  class="rounded-lg"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div id="bottom-cta" class="px-2 md:px-4">
        <div class="py-8 hero">
          <div class="flex flex-col items-center gap-10 hero-content">
            <div class="card bg-base-200 shadow-secondary">
              <div class="flex flex-col items-center max-w-4xl gap-4 p-4 card-body">
                <div class="text-5xl font-bold">
                  Sign Up for Updates and
                  <span class="text-primary">Beta Access</span>
                </div>
                <Form for={%{}} as={:signup} submit="submit" class="w-full max-w-xl py-4 form-control">
                  <div class="input-group">
                    <EmailInput
                      id="bottom-cta-input"
                      name={:email}
                      class="rounded-lg input input-bordered grow"
                      opts={placeholder: "youremail@example.com", required: true}
                    />
                    <Submit class="rounded-lg btn btn-primary">
                      Sign Up
                    </Submit>
                  </div>
                  <label for="bottom-cta-input" class="label">
                    <span class="flex flex-row items-center label-text">Beta access invites are
                      <span class="text-primary">first-come, first-serve</span>
                    </span>
                  </label>
                </Form>
              </div>
            </div>
            <div class="flex flex-col items-center gap-2">
              <a
                href="https://discord.gg/FUkTHjGKJF"
                target="_blank"
                rel="noopener noreferrer"
                class="btn bg-[#5865F2] btn-md rounded-full"
              >
                <span>Join Us On Discord</span>
                <svg role="img" viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
                  <title>Discord</title>
                  <path
                    fill="currentColor"
                    d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"
                  />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
