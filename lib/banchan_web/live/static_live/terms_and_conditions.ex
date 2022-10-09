defmodule BanchanWeb.StaticLive.TermsAndConditions do
  @moduledoc """
  Banchan Terms and Conditions Page
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Markdown

  alias BanchanWeb.Components.Layout

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flash={@flash}>
      <#Markdown class="prose">
        # Terms and Conditions

        Last updated: September 21, 2022

        Please read these terms and conditions carefully before using Our Service.

        # Interpretation and Definitions

        ## Interpretation

        Capitalized words have meanings defined below. These definitions shall have the same meaning regardless of whether they appear in singular or in plural.

        ## Definitions

        For the purposes of these Terms and Conditions:

        **Affiliate** means an entity that controls, is controlled by or is under common control with a party, where "control" means ownership of 50% or more of the shares, equity interest or other securities entitled to vote for election of directors or other managing authority.

        **Account** means a unique account created for You to access Our Service or parts of Our Service.

        **Commissions** refer to the items offered for sale on the Service.

        **Company** (referred to as either "the Company", "We", "Us" or "Our" in these Terms) refers to Banchan Art LLC, 340 S Lemon Ave #8687, Walnut, CA 91789.

        **Content** refers to content such as text, images, or other information that can be posted, uploaded, linked to or otherwise made available by You, regardless of the form of that content.

        **Device** means any device that can access the Service such as a computer, a cellphone or a digital tablet.

        **Feedback** means feedback, innovations or suggestions sent by You regarding the attributes, performance or features of our Service.

        **Orders** mean a request by You to purchase a Commission through the Service.

        **Promotions** refer to contests, sweepstakes or other promotions offered through the Service.

        **Service** refers to the Website.

        **Studio** refers to a specific type of user of the Service that offers Commissions via the Service.

        **Terms and Conditions** (also referred as "Terms") mean these Terms and Conditions that form the entire agreement between You and the Company regarding the use of the Service.

        **Third-Party Social Media Service** means any services or content (including data, information, products or services) provided by a third party that may be displayed, included or made available by the Service.

        **Website** refers to Banchan Art, accessible from https://banchan.art.

        **You** means the individual accessing or using the Service, or the company, or other legal entity on behalf of which such individual is accessing or using the Service, as applicable.

        # Acknowledgment

        These are the Terms and Conditions governing the use of this Service and the operative agreement between You and the Company. These Terms and Conditions set out the rights and obligations of all users regarding the use of the Service.

        Your access to and use of the Service is conditioned on Your acceptance of and compliance with these Terms and Conditions. These Terms and Conditions apply to all visitors, users and others who access or use the Service.

        By accessing or using the Service You agree to be bound by these Terms and Conditions. If You disagree with any part of these Terms and Conditions then You may not access the Service.

        You represent that you are over the age of 18. The Company does not permit those under 18 to use the Service.

        Your access to and use of the Service is also conditioned on Your acceptance of and compliance with the Privacy Policy of the Company. Our Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your personal information when You use the Service or the Website and tells You about Your privacy rights and how the law protects You. Please read Our Privacy Policy carefully before using Our Service.

        # Placing Orders for Commissions

        By placing an Order for a Commission through the Service, You warrant that You are legally capable of entering into binding contracts.

        ## Your Information

        If You wish to place an Order for a Commission available on the Service, You may be asked to supply certain information relevant to Your Order including, without limitation, Your name, Your email, Your phone number, Your credit card number, the expiration date of Your credit card, Your billing address, and Your shipping information.

        You represent and warrant that: (i) You have the legal right to use any credit or debit card(s) or other payment method(s) in connection with any Order; and that (ii) the information You supply to us is true, correct and complete.

        By submitting such information, You grant us the right to provide the information to payment processing third parties for purposes of facilitating the completion of Your Order.

        ## Order Cancellation

        Both the Studio and Us reserve the right to refuse or cancel Your Order at any time for certain reasons including but not limited to:

        - Commissions availability
        - Errors in the description or prices for Commissions
        - Errors in Your Order

        We also reserve the right to refuse or cancel Your Order if fraud or an unauthorized or illegal transaction is suspected.

        ### Your Order Cancellation Rights

        Any Commissions you purchase can only be returned in accordance with these Terms and Conditions and Our Disputes Policy.

        Our Disputes Policy forms a part of these Terms and Conditions. Please read our Disputes Policy to learn more about your right to cancel Your Order.

        ## Availability, Errors and Inaccuracies

        Studios are constantly updating their offerings of Commissions on the Service. The Commissions available on the Service may be mispriced, described inaccurately, or unavailable, and We or the Studios may experience delays in updating information regarding Commissions on the Service and in Our advertising on other websites.

        We cannot and do not guarantee the accuracy or completeness of any information, including prices, product images, specifications, availability, and services. We reserve the right to change or update information and to correct errors, inaccuracies, or omissions at any time without prior notice.

        ## Pricing Policy

        Studios have the right to revise their prices at any time prior to accepting an Order.

        The prices quoted may be revised by the Studio subsequent to accepting an Order in the event of any occurrence affecting delivery caused by government action, variation in higher foreign exchange costs and any other matter beyond the control of the Studio. In that event, You will have the right to cancel Your Order.

        Additionally, if You request extra work or features for a Commission after it is accepted, the Studio may increase the price for the Commission. Studios may also limit how many changes can be requested on a Commission past a certain point. See the specific Studio's policies for more information.

        ## Payments

        All Commissions purchased are subject to payment, as prescribed by the Studio. Payments are conducted through Stripe. Transactions using cryptocurrency are strictly prohibited.

        Payment cards (credit cards or debit cards) are subject to validation checks and authorization by Your card issuer. If we do not receive the required authorization, We will not be liable for any delay or non-delivery of Your Order.

        ## Limitation on NFTs

        Studios are expressly prohibited from offering or selling NFT-related Commissions. This includes selling NFTs directly, as well as commissioning art that will later be sold as NFTs on platforms like OpenSea.

        # Promotions

        Any Promotions made available through the Service may be governed by rules that are separate from these Terms.

        If You participate in any Promotions, please review the applicable rules as well as our Privacy policy. If the rules for a Promotion conflict with these Terms, the Promotion rules will apply.

        # User Accounts

        When You create an account with Us, You must provide Us information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of Your account on Our Service.

        You are responsible for safeguarding the password that You use to access the Service and for any activities or actions under Your password, whether Your password is with Our Service or a Third-Party Social Media Service.

        You agree not to disclose Your password to any third party. You must notify Us immediately upon becoming aware of any breach of security or unauthorized use of Your account.

        You may not use as a username the name of another person or entity or that is not lawfully available for use, a name or trademark that is subject to any rights of another person or entity other than You without appropriate authorization, or a name that is otherwise offensive, vulgar or obscene.

        # Content

        ## Your Right to Post Content

        Our Service allows You to post Content. You are responsible for the Content that You post to the Service, including its legality, reliability, and appropriateness.

        By posting Content to the Service, You grant Us the right and license to use, modify, publicly perform, publicly display, reproduce, and distribute such Content on and through the Service. You retain any and all of Your rights to any Content You submit, post or display on or through the Service and You are responsible for protecting those rights. You agree that this license includes the right for Us to make Your Content available to other users of the Service, who may also use Your Content subject to these Terms.

        You represent and warrant that: (i) the Content is Yours (You own it) or You have the right to use it and grant Us the rights and license as provided in these Terms, and (ii) the posting of Your Content on or through the Service does not violate the privacy rights, publicity rights, copyrights, contract rights or any other rights of any person.

        ## Content Restrictions

        The Company is not responsible for the content of the Service's users. You expressly understand and agree that You are solely responsible for the Content and for all activity that occurs under Your account, whether done so by You or any third person using Your account.

        You may not transmit any Content that is unlawful, offensive, upsetting, intended to disgust, threatening, libelous, defamatory, obscene or otherwise objectionable. Examples of such objectionable Content include, but are not limited to, the following:

        - Unlawful or promoting unlawful activity.
        - Defamatory, discriminatory, or mean-spirited content, including references or commentary about religion, race, sexual orientation, gender, national/ethnic origin, or other targeted groups.
        - Spam (machine- or randomly generated) constituting unauthorized or unsolicited advertising, chain letters, any other form of unauthorized solicitation, or any form of lottery or gambling.
        - Containing or installing any viruses, worms, malware, trojan horses, or other content that is designed or intended to disrupt, damage, or limit the functioning of any software, hardware or telecommunications equipment or to damage or obtain unauthorized access to any data or other information of a third person.
        - Infringing on any proprietary rights of any party, including patent, trademark, trade secret, copyright, right of publicity or other rights.
        - Impersonating any person or entity including the Company and its employees or representatives.
        - Violating the privacy of any third person.
        - False information and features.

        The Company reserves the right, but not the obligation, to, in its sole discretion, determine whether or not any Content is appropriate and complies with these Terms, refuse or remove this Content. The Company further reserves the right to make formatting and edits and change the manner of any Content. The Company can also limit or revoke the use of the Service if You post such objectionable Content. As the Company cannot control all content posted by users and/or third parties on the Service, you agree to use the Service at your own risk. You understand that by using the Service You may be exposed to content that You may find offensive, indecent, incorrect or objectionable, and You agree that under no circumstances will the Company be liable in any way for any content, including any errors or omissions in any content, or any loss or damage of any kind incurred as a result of your use of any content.

        ## Content Backups

        Although regular backups of Content are performed, the Company does not guarantee there will be no loss or corruption of data.

        Corrupt or invalid backup points may be caused by, without limitation, Content that is corrupted prior to being backed up or that changes during the time a backup is performed.

        The Company will provide support and attempt to troubleshoot any known or discovered issues that may affect the backups of Content. But You acknowledge that the Company has no liability related to the integrity of Content or the failure to successfully restore Content to a usable state.

        You agree to maintain a complete and accurate copy of any Content in a location independent of the Service.

        # Copyright Policy

        ## Intellectual Property Infringement

        We respect the intellectual property rights of others. It is Our policy to respond to any claim that Content posted on the Service infringes a copyright or other intellectual property infringement of any person.

        If You are a copyright owner, or authorized on behalf of one, and You believe that the copyrighted work has been copied in a way that constitutes copyright infringement that is taking place through the Service, You must submit Your notice in writing to the attention of our copyright agent via email at support@banchan.art and include in Your notice a detailed description of the alleged infringement.

        You may be held accountable for damages (including costs and attorneys' fees) for misrepresenting that any Content is infringing Your copyright.

        ## DMCA Notice and DMCA Procedure for Copyright Infringement Claims

        You may submit a notification pursuant to the Digital Millennium Copyright Act (DMCA) by providing our Copyright Agent with the following information in writing (see 17 U.S.C 512(c)(3) for further detail):

        - An electronic or physical signature of the person authorized to act on behalf of the owner of the copyright's interest.
        - A description of the copyrighted work that You claim has been infringed, including the URL (i.e., webpage address) of the location where the copyrighted work exists or a copy of the copyrighted work.
        - Identification of the URL or other specific location on the Service where the material that You claim is infringing is located.
        - Your address, telephone number, and email address.
        - A statement by You that You have a good-faith belief that the disputed use is not authorized by the copyright owner, its agent, or the law.
        - A statement by You, made under penalty of perjury, that the above information in Your notice is accurate and that You are the copyright owner or authorized to act on the copyright owner's behalf.

        You can contact our copyright agent via email at [support@banchan.art](mailto:support@banchan.art). Upon receipt of a notification, the Company will take whatever action, in its sole discretion, it deems appropriate, including removal of the challenged content from the Service.

        # Intellectual Property

        The Service and its original content (excluding Content provided by You or other users), features and functionality are and will remain the exclusive property of the Company and its licensors.

        The Service is protected by copyright, trademark, and other laws of both the United States and foreign countries.

        Our trademarks, service marks and trade dress may not be used in connection with any product or service without the prior written consent of the Company.

        # Your Feedback to Us

        You assign all rights, title and interest in any Feedback You provide the Company. If for any reason such assignment is ineffective, You agree to grant the Company a non-exclusive, perpetual, irrevocable, royalty free, worldwide right and license to use, reproduce, disclose, sub-license, distribute, modify and exploit such Feedback without restriction.

        # Links to Other Websites

        Our Service may contain links to third-party websites or services that are not owned or controlled by the Company.

        The Company has no control over, and assumes no responsibility for, the content, privacy policies, or practices of any third-party websites or services. You further acknowledge and agree that the Company shall not be responsible or liable, directly or indirectly, for any damage or loss caused or alleged to be caused by or in connection with the use of or reliance on any such content, goods or services available on or through any such websites or services.

        We strongly advise You to read the terms and conditions and privacy policies of any third-party websites or services that You visit.

        # Termination

        We may terminate or suspend Your Account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if You breach these Terms and Conditions.

        Upon termination, Your right to use the Service will cease immediately. If You wish to terminate Your Account, You may simply discontinue using the Service.

        # Limitation of Liability

        Notwithstanding any damages that You might incur, the entire liability of the Company and any of its suppliers under any provision of these Terms and Your exclusive remedy for all of the foregoing shall be limited to the amount actually paid by You through the Service or $100 USD if You haven't purchased anything through the Service.

        To the maximum extent permitted by applicable law, in no event shall the Company or its suppliers be liable for any special, incidental, indirect, or consequential damages whatsoever (including, but not limited to, damages for loss of profits, loss of data or other information, for business interruption, for personal injury, loss of privacy arising out of or in any way related to the use of or inability to use the Service, third-party software and/or third-party hardware used with the Service, or otherwise in connection with any provision of these Terms), even if the Company or any supplier has been advised of the possibility of such damages and even if the remedy fails of its essential purpose.

        Some states do not allow the exclusion of implied warranties or limitation of liability for incidental or consequential damages, which means that some of the above limitations may not apply. In these states, each party's liability will be limited to the greatest extent permitted by law.

        # "AS IS" and "AS AVAILABLE" Disclaimer

        The Service is provided to You "AS IS" and "AS AVAILABLE" and with all faults and defects without warranty of any kind. To the maximum extent permitted under applicable law, the Company, on its own behalf and on behalf of its Affiliates and its and their respective licensors and service providers, expressly disclaims all warranties, whether express, implied, statutory or otherwise, with respect to the Service, including all implied warranties of merchantability, fitness for a particular purpose, title and non-infringement, and warranties that may arise out of course of dealing, course of performance, usage or trade practice. Without limitation to the foregoing, the Company provides no warranty or undertaking, and makes no representation of any kind that the Service will meet Your requirements, achieve any intended results, be compatible or work with any other software, applications, systems or services, operate without interruption, meet any performance or reliability standards or be error free or that any errors or defects can or will be corrected.

        Without limiting the foregoing, neither the Company nor any of the Company's providers makes any representation or warranty of any kind, express or implied: (i) as to the operation or availability of the Service, or the information, content, and materials or products included thereon; (ii) that the Service will be uninterrupted or error-free; (iii) as to the accuracy, reliability, or currency of any information or content provided through the Service; or (iv) that the Service, its servers, the content, or emails sent from or on behalf of the Company are free of viruses, scripts, trojan horses, worms, malware, timebombs or other harmful components.

        Some jurisdictions do not allow the exclusion of certain types of warranties or limitations on applicable statutory rights of a consumer, so some or all of the above exclusions and limitations may not apply to You. But in such a case the exclusions and limitations set forth in this section shall be applied to the greatest extent enforceable under applicable law.

        # Governing Law

        The laws of California, excluding its conflicts-of-law rules, shall govern these Terms and Your use of the Service. Your use of the Website Our Service may also be subject to other local, state, national, or international laws.

        # Dispute Resolution

        If You have any concern or dispute about the Service, You agree to first try to resolve the dispute informally by contacting the Studio. For more information, see our Disputes Policy.

        # For European Union (EU) Users

        If You are a European Union consumer, you will benefit from any mandatory provisions of the law of the country in which you are resident in.

        # United States Legal Compliance

        You represent and warrant that (i) You are not located in a country that is subject to the United States government embargo, or that has been designated by the United States government as a "terrorist supporting" country, and (ii) You are not listed on any United States government list of prohibited or restricted parties.

        # Severability and Waiver

        ## Severability

        If any provision of these Terms is held to be unenforceable or invalid, such provision will be changed and interpreted to accomplish the objectives of such provision to the greatest extent possible under applicable law and the remaining provisions will continue in full force and effect.

        ## Waiver

        Except as provided herein, the failure to exercise a right or to require performance of an obligation under these Terms shall not effect a party's ability to exercise such right or require such performance at any time thereafter nor shall the waiver of a breach constitute a waiver of any subsequent breach.

        # Changes to These Terms and Conditions

        We reserve the right, at Our sole discretion, to modify or replace these Terms at any time. If a revision is material We will make reasonable efforts to provide at least 30 days' notice prior to any new terms taking effect. What constitutes a material change will be determined at Our sole discretion.

        By continuing to access or use Our Service after those revisions become effective, You agree to be bound by the revised terms. If You do not agree to the new terms, in whole or in part, please stop using the website and the Service.

        # Contact Us

        If you have any questions about these Terms and Conditions, You can contact us:

        - By email: [support@banchan.art](mailto:support@banchan.art)

      </#Markdown>
    </Layout>
    """
  end
end
