defmodule BanchanWeb.StaticLive.DisputesPolicy do
  @moduledoc """
  Banchan Disputes Policy Page
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Markdown

  alias BanchanWeb.Components.Layout

  @impl true
  def handle_params(_params, uri, socket) do
    socket = Context.put(socket, uri: uri)
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout>
      <#Markdown class="prose">
        # Disputes Policy

        Last updated: September 21, 2022

        Thank you for shopping at Banchan Art.

        If, for any reason, You are not completely satisfied with a purchase, We invite You to review this policy for more information on how We handle disputes, chargebacks, and refunds.

        The following terms are applicable for any Orders that You placed through the Service.

        # Interpretation and Definitions

        ## Interpretation

        Capitalized words have meanings defined below. These definitions shall have the same meaning regardless of whether they appear in singular or in plural.

        ## Definitions

        For the purposes of this Disputes Policy:

        **Commissions** refer to the items offered for sale on the Service.

        **Company** (referred to as either "the Company", "We", "Us" or "Our" in this Agreement) refers to Banchan Art LLC, 340 S Lemon Ave #8687, Walnut, CA 91789.

        **Orders** mean a request by You to purchase Commissions through the Service.

        **Service** refers to the Website.

        **Studio** refers to a specific type of user of the Service that offers Commissions via the Service.

        **Website** refers to Banchan Art, accessible from https://banchan.art.

        **You** means the individual accessing or using the Service, or the company, or other legal entity on behalf of which such individual is accessing or using the Service, as applicable.

        # Your Order Withdrawal Rights

        You are entitled to withdraw Your Order for any reason before the Studio has begun work on Your Order. In other words, if the status of Your Order is "submitted" or "accepted," you may withdraw Your Order by changing the status to "withdrawn" on the Service.

        We will reimburse You for any payment already made that has not yet been released to the studio no later than 14 days from the day on which You withdraw Your Order (minus any platform fees, e.g., Stripe fees). We will use the same means of payment as You used for the Order.

        If you want to withdraw Your Order where the status of Your Commission is "in progress," please first contact the Studio directly to inquire if they would be willing to agree to a withdrawal or modification pursuant to their Studio policies, as described below.

        # Resolving Issues Directly with the Studio

        If You are looking to withdraw Your Order after it is "in progress," or if you are wanting a refund or to otherwise notify the Studio of a problem with Your Order, You must first contact the Studio directly via the Commission page and let the Studio know the issue. It is important for Studios to fill out their Studio policies and to address requests. It is also important for You to read and understand the Studio's policies before placing Your Order.

        Studios are expected to regularly respond to messages related to an active Commission. If You have reached out to the Studio via the Commission page and haven't heard back within 120 business hours, or if the Studio is unable to resolve the issue within 120 business hours, You can submit a dispute to Us, as described below.

        # Submitting a Dispute

        If you have not been able to resolve an issue with the Studio as described above, you may submit a dispute to Us by emailing us at [support@banchan.art](mailto:support@banchan.art) with a link to the Commission in question and a description of the issue.

        When a dispute is submitted, the Company will assist in the resolution of the dispute between You and the Studio. This may include, but is not limited to, automatically closing the dispute and issuing You a refund, or reviewing the case further to help both parties work together to resolve the issue.

        Here are a few things to keep in mind:

        - You cannot dispute a Commission that You have already approved. If a Studio has submitted a Commission for your review but it does not meet the Commission specifications, DO NOT mark the Commission as "approved."
        - You cannot submit a dispute if more than 100 days have passed since the date the Commission was completed or estimated to be completed.
        - The Company cannot resolve disputes where payment and/or communications between You and the Studio were handled outside of the Service. If the Company doesn't have sufficient evidence of the agreement between You and the Studio, or that the agreement was fulfilled, the Company will err on the side of finding in Your favor. As such, it is in the Studio's best interest to have its own clear Studio policies and to conduct all payment transactions on the Service.
        - The Company will rely exclusively on e-mail to interact with both parties during the dispute resolution process. At any point after a dispute has been filed, the Company may freeze part or all of the disputed funds for up to 90 days. Failure to promptly respond to requests made by the Company during the dispute resolution process may result in an unfavorable resolution for You. The Company cannot provide an exact time period to resolve a dispute.

        The Company's decision regarding how to resolve the dispute is final and the Commission cannot be re-disputed. In the event the resolution involves refunding some or all of the price paid, any platform fees (e.g., Stripe fees) will be deducted from the refund amount to cover the Company's processing charges.

        The fixed fee charged to the Studio will not be refunded, regardless of resolution, except in the sole discretion of the Company.

        # Chargebacks

        A chargeback filed with the issuing bank against the Company will be counter-disputed. The Studio may be held financially responsible if the dispute results in an unfavorable outcome for the Company. Studios may be held financially responsible for disputes or chargebacks that are identified to be legitimate (for example, if a Studio does not deliver a Commission) or if a Studio does not promptly respond to assistance requests made by the Company.

        Frequent chargebacks against a Studio, regardless of legitimacy, may result in the termination of the Studio's account.

        # Contact Us

        If you have any questions about our Disputes Policy, please contact us:

        - By email: [support@banchan.art](mailto:support@banchan.art)

      </#Markdown>
    </Layout>
    """
  end
end
