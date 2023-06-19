defmodule BanchanWeb.BetaLive.Signup do
  @moduledoc """
  LiveView for the Banchan beta signup form.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Accounts

  alias Surface.Components.Form
  alias Surface.Components.Form.{EmailInput, Submit}

  alias BanchanWeb.Components.Layout

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
      <div id="above-fold" class="md:px-4 mt-20">
        <div class="min-h-screen hero">
          <div class="hero-content flex flex-col md:flex-row">
            <div class="flex flex-col gap-4 md:gap-10 p-4 items-center max-w-2xl">
              <div class="text-5xl font-bold">
                A Platform for
                <span class="md:whitespace-nowrap">Online Art Commissions</span>
              </div>
              <div class="text-2xl font-semibold pt-2 w-full">
                <span class="text-primary font-bold">Owned by the Artists</span>
              </div>
              <div class="text-2xl font-semibold pt-2">
                Banchan is a
                <a
                  href="https://en.wikipedia.org/wiki/Platform_cooperative"
                  class="text-primary link font-bold"
                  target="_blank"
                  rel="noopener noreferrer"
                >co-op</a>: Artists and workers make the
                <span class="text-primary font-bold">decisions</span> and split
                the <span class="text-primary font-bold">profits</span>, not
                executives and shareholders. One person, one vote. One
                <span class="text-primary font-bold">community</span>.
              </div>
              <div id="top-cta" class="w-full flex flex-col gap-2 py-4 rounded-lg items-start">
                <div class="flex flex-col md:flex-row gap-2">
                  <div class="text-xl font-medium">
                    Join the
                    <span class="text-primary font-bold">Revolution</span>!
                  </div>
                  <div>(or at least the Closed Beta)</div>
                </div>
                <Form for={%{}} as={:signup} submit="submit" class="w-full max-w-xl py-4 form-control">
                  <div class="input-group">
                    <EmailInput
                      name={:email}
                      class="input input-bordered grow rounded-lg"
                      opts={placeholder: "E-mail", required: true}
                    />
                    <Submit class="btn btn-primary rounded-lg">
                      Sign Up
                    </Submit>
                  </div>
                </Form>
              </div>
              <div id="scroll-down-please">
                <i class="fas fa-chevron-down animate-bounce text-3xl" />
              </div>
            </div>
          </div>
        </div>
      </div>
      <div id="comms" class="px-2 md:px-4">
        <div class="min-h-screen hero">
          <div class="hero-content grid grid-cols-1 md:grid-cols-2">
            <div class="flex flex-col gap-4">
              <div class="text-4xl font-semibold">
                A
                <span class="text-primary font-bold whitespace-nowrap">Complete</span>
                Commissions Experience
              </div>
              <div class="text-2xl font-semibold">
                Discovery, communications, delivery, invoicing, payments.
                <span class="text-primary whitespace-nowrap">All in one spot</span>.
              </div>
            </div>
            <div class="rounded-lg shadow-xl themed dark shadow-black outline outline-primary outline-3">
              <img
                alt="Screenshot of an ongoing commission. The title is 'Please draw my OC'. There are various elements of interest on the page, such as a status, a summary of what is being paid for, and some art on the page."
                src={Routes.static_path(Endpoint, "/images/banchan-comm-dark.png")}
                class="rounded-lg"
              />
            </div>
            <div class="rounded-lg shadow-xl themed light shadow-secondary outline outline-primary outline-3">
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
          <div class="hero-content grid grid-cols-1 md:grid-cols-2 gap-4">
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
              <div class="rounded-lg shadow-xl themed dark shadow-black outline outline-primary outline-3">
                <img
                  alt="Screenshot showing the Banchan invoicing feature. There is a message saying that the commission is complete, and a message box that says Payment Succeeded, $120, plug a Release Now button. There is artwork attached to the message."
                  src={Routes.static_path(Endpoint, "/images/banchan-invoice-dark.png")}
                  class="rounded-lg"
                />
              </div>
              <div class="rounded-lg shadow-xl themed light shadow-secondary outline outline-primary outline-3">
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
          <div class="hero-content grid grid-cols-1 md:grid-cols-2 gap-10">
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
              <div class="rounded-lg shadow-xl themed dark shadow-black outline outline-primary outline-3">
                <img
                  alt="Screenshot of an example Banchan shop, including a beautiful header graphic, the name of the studio, and three separate offerings: Flat Full Color, Full Color Shaded, and Sketch. They each have 3 slots available."
                  src={Routes.static_path(Endpoint, "/images/banchan-shop-dark.png")}
                  class="rounded-lg"
                />
              </div>
              <div class="rounded-lg shadow-xl themed light shadow-secondary outline outline-primary outline-3">
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
        <div class="hero py-8">
          <div class="hero-content flex flex-col items-center gap-10">
            <div class="card shadow-xl bg-base-200 shadow-secondary">
              <div class="card-body flex flex-col gap-4 p-4 items-center max-w-4xl">
                <div class="text-5xl font-bold">
                  Sign Up for Updates and
                  <span class="text-primary">Beta Access</span>
                </div>
                <Form for={%{}} as={:signup} submit="submit" class="w-full max-w-xl py-4 form-control">
                  <div class="input-group">
                    <EmailInput
                      id="bottom-cta-input"
                      name={:email}
                      class="input input-bordered grow rounded-lg"
                      opts={placeholder: "E-mail", required: true}
                    />
                    <Submit class="btn btn-primary rounded-lg">
                      Sign Up
                    </Submit>
                  </div>
                  <label for="bottom-cta-input" class="label">
                    <span class="label-text">Beta access invites are
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
              >Join Us On Discord <i class="pl-2 fab fa-discord text-xl" />
              </a>
            </div>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
