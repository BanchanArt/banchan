defmodule BanchanWeb.StaticLive.CookiesPolicy do
  @moduledoc """
  Banchan Cookie Policy Page
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Markdown

  alias BanchanWeb.Components.Layout

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <#Markdown class="w-full px-4 py-2 mx-auto prose max-w-7xl">
        # Cookies Policy

        Last updated: August 13, 2023

        This Cookies Policy explains what Cookies are and how We use them. You should read this policy so You can understand what type of cookies We use, or the information We collect using Cookies and how that information is used.

        Cookies do not typically contain any information that personally identifies a user, but personal information that we store about You may be linked to the information stored in and obtained from Cookies. For further information on how We use, store and keep Your personal data secure, see Our Privacy Policy.

        We do not store sensitive personal information, such as mailing addresses, account passwords, etc. in the Cookies We use.

        # Interpretation and Definitions

        ## Interpretation

        Capitalized words have meanings defined below. These definitions shall have the same meaning regardless of whether they appear in singular or in plural.

        ## Definitions

        For the purposes of this Cookies Policy:

        - **Company** (referred to as either "the Company", "We", "Us" or "Our" in this Cookies Policy) refers to Banchan Art LLC, 440 N Barranca Ave #8687 Covina, CA 91723.
        - **Cookies** means small files that are placed on Your computer, mobile device or any other device by a website, containing details of Your browsing history on that website among its many uses.
        - **Website** refers to Banchan Art, accessible from https://banchan.art.
        - **You** means the individual accessing or using the Website, or a company, or any legal entity on behalf of which such individual is accessing or using the Website, as applicable.

        # The Use of the Cookies

        ## Type of Cookies We Use

        Cookies can be "Persistent" or "Session" Cookies. Persistent Cookies remain on Your personal computer or mobile device when You go offline, while Session Cookies are deleted as soon as You close Your web browser.

        We use both session and persistent Cookies for the purposes set out below:

        **Necessary / Essential Cookies**

        Type: Session Cookies

        Administered by: Us

        Purpose: These Cookies are essential to provide You with services available through the Website and to enable You to use some of its features. They help to authenticate users and prevent fraudulent use of user accounts. Without these Cookies, the services that You have asked for cannot be provided, and We only use these Cookies to provide You with those services.

        **Functionality Cookies**

        Type: Persistent Cookies

        Administered by: Us

        Purpose: These Cookies allow us to remember choices You make when You use the Website, such as remembering Your login details or language preference. The purpose of these Cookies is to provide You with a more personal experience and to avoid You having to re-enter Your preferences every time You use the Website.

        ## Your Choices Regarding Cookies

        If You prefer to avoid the use of Cookies on the Website, first You must disable the use of Cookies in Your browser and then delete the Cookies saved in Your browser associated with this website. You may use this option for preventing the use of Cookies at any time.

        If You do not accept Our Cookies, You may experience some inconvenience in Your use of the Website and some features may not function properly.

        If You'd like to delete Cookies or instruct Your web browser to delete or refuse Cookies, please visit the help pages of Your web browser.

        For the Chrome web browser, please visit this page from Google: [https://support.google.com/accounts/answer/32050](https://support.google.com/accounts/answer/32050)

        For the Microsoft Edge web browser, please visit this page from Microsoft: [https://support.microsoft.com/en-us/microsoft-edge/delete-cookies-in-microsoft-edge-63947406-40ac-c3b8-57b9-2a946a29ae09](https://support.microsoft.com/en-us/microsoft-edge/delete-cookies-in-microsoft-edge-63947406-40ac-c3b8-57b9-2a946a29ae09)

        For the Firefox web browser, please visit this page from Mozilla: [https://support.mozilla.org/en-US/kb/delete-cookies-remove-info-websites-stored](https://support.mozilla.org/en-US/kb/delete-cookies-remove-info-websites-stored)

        For the Safari web browser, please visit this page from Apple: [https://support.apple.com/guide/safari/manage-cookies-and-website-data-sfri11471/mac](https://support.apple.com/guide/safari/manage-cookies-and-website-data-sfri11471/mac)

        For any other web browser, please visit Your web browser's official web pages.

        ## Contact Us

        If you have any questions about this Cookies Policy, You can contact Us:

        - By email: [support@banchan.art](mailto:support@banchan.art)
      </#Markdown>
    </Layout>
    """
  end
end
