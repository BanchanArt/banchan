defmodule BanchanWeb.Components.Socials do
  @moduledoc """
  Displays social media links.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  prop entity, :struct, required: true
  prop class, :css_class

  def render(assigns) do
    mastodon_url =
      if assigns.entity.mastodon_handle do
        case Regex.named_captures(
               ~r/(?<handle>[^@]+)@(?<domain>.+)/,
               assigns.entity.mastodon_handle
             ) do
          %{"handle" => handle, "domain" => domain} ->
            "https://#{domain}/@#{handle}"

          _ ->
            nil
        end
      end

    ~F"""
    <div :if={!@entity.disable_info} class={"flex flex-row flex-wrap gap-4", @class}>
      <a
        :if={@entity.website_url}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={@entity.website_url}
      >
        <Icon name="link" /><div class="font-medium text-sm hover:link">{@entity.website_url}</div>
      </a>
      <a
        :if={@entity.twitter_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://twitter.com/#{@entity.twitter_handle}"}
      >
        <svg role="img" width="12" height="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>X</title><path
            fill="currentColor"
            d="M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z"
          /></svg><div class="font-medium text-sm hover:link">@{@entity.twitter_handle}</div>
      </a>
      <a
        :if={@entity.mastodon_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={mastodon_url}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Mastodon</title><path
            fill="currentColor"
            d="M23.268 5.313c-.35-2.578-2.617-4.61-5.304-5.004C17.51.242 15.792 0 11.813 0h-.03c-3.98 0-4.835.242-5.288.309C3.882.692 1.496 2.518.917 5.127.64 6.412.61 7.837.661 9.143c.074 1.874.088 3.745.26 5.611.118 1.24.325 2.47.62 3.68.55 2.237 2.777 4.098 4.96 4.857 2.336.792 4.849.923 7.256.38.265-.061.527-.132.786-.213.585-.184 1.27-.39 1.774-.753a.057.057 0 0 0 .023-.043v-1.809a.052.052 0 0 0-.02-.041.053.053 0 0 0-.046-.01 20.282 20.282 0 0 1-4.709.545c-2.73 0-3.463-1.284-3.674-1.818a5.593 5.593 0 0 1-.319-1.433.053.053 0 0 1 .066-.054c1.517.363 3.072.546 4.632.546.376 0 .75 0 1.125-.01 1.57-.044 3.224-.124 4.768-.422.038-.008.077-.015.11-.024 2.435-.464 4.753-1.92 4.989-5.604.008-.145.03-1.52.03-1.67.002-.512.167-3.63-.024-5.545zm-3.748 9.195h-2.561V8.29c0-1.309-.55-1.976-1.67-1.976-1.23 0-1.846.79-1.846 2.35v3.403h-2.546V8.663c0-1.56-.617-2.35-1.848-2.35-1.112 0-1.668.668-1.67 1.977v6.218H4.822V8.102c0-1.31.337-2.35 1.011-3.12.696-.77 1.608-1.164 2.74-1.164 1.311 0 2.302.5 2.962 1.498l.638 1.06.638-1.06c.66-.999 1.65-1.498 2.96-1.498 1.13 0 2.043.395 2.74 1.164.675.77 1.012 1.81 1.012 3.12z"
          /></svg><div class="font-medium text-sm hover:link">@{@entity.mastodon_handle}</div>
      </a>
      <a
        :if={@entity.instagram_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://instagram.com/#{@entity.instagram_handle}"}
      >
        <svg role="img" width="12" height="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Instagram</title><path
            fill="currentColor"
            d="M7.0301.084c-1.2768.0602-2.1487.264-2.911.5634-.7888.3075-1.4575.72-2.1228 1.3877-.6652.6677-1.075 1.3368-1.3802 2.127-.2954.7638-.4956 1.6365-.552 2.914-.0564 1.2775-.0689 1.6882-.0626 4.947.0062 3.2586.0206 3.6671.0825 4.9473.061 1.2765.264 2.1482.5635 2.9107.308.7889.72 1.4573 1.388 2.1228.6679.6655 1.3365 1.0743 2.1285 1.38.7632.295 1.6361.4961 2.9134.552 1.2773.056 1.6884.069 4.9462.0627 3.2578-.0062 3.668-.0207 4.9478-.0814 1.28-.0607 2.147-.2652 2.9098-.5633.7889-.3086 1.4578-.72 2.1228-1.3881.665-.6682 1.0745-1.3378 1.3795-2.1284.2957-.7632.4966-1.636.552-2.9124.056-1.2809.0692-1.6898.063-4.948-.0063-3.2583-.021-3.6668-.0817-4.9465-.0607-1.2797-.264-2.1487-.5633-2.9117-.3084-.7889-.72-1.4568-1.3876-2.1228C21.2982 1.33 20.628.9208 19.8378.6165 19.074.321 18.2017.1197 16.9244.0645 15.6471.0093 15.236-.005 11.977.0014 8.718.0076 8.31.0215 7.0301.0839m.1402 21.6932c-1.17-.0509-1.8053-.2453-2.2287-.408-.5606-.216-.96-.4771-1.3819-.895-.422-.4178-.6811-.8186-.9-1.378-.1644-.4234-.3624-1.058-.4171-2.228-.0595-1.2645-.072-1.6442-.079-4.848-.007-3.2037.0053-3.583.0607-4.848.05-1.169.2456-1.805.408-2.2282.216-.5613.4762-.96.895-1.3816.4188-.4217.8184-.6814 1.3783-.9003.423-.1651 1.0575-.3614 2.227-.4171 1.2655-.06 1.6447-.072 4.848-.079 3.2033-.007 3.5835.005 4.8495.0608 1.169.0508 1.8053.2445 2.228.408.5608.216.96.4754 1.3816.895.4217.4194.6816.8176.9005 1.3787.1653.4217.3617 1.056.4169 2.2263.0602 1.2655.0739 1.645.0796 4.848.0058 3.203-.0055 3.5834-.061 4.848-.051 1.17-.245 1.8055-.408 2.2294-.216.5604-.4763.96-.8954 1.3814-.419.4215-.8181.6811-1.3783.9-.4224.1649-1.0577.3617-2.2262.4174-1.2656.0595-1.6448.072-4.8493.079-3.2045.007-3.5825-.006-4.848-.0608M16.953 5.5864A1.44 1.44 0 1 0 18.39 4.144a1.44 1.44 0 0 0-1.437 1.4424M5.8385 12.012c.0067 3.4032 2.7706 6.1557 6.173 6.1493 3.4026-.0065 6.157-2.7701 6.1506-6.1733-.0065-3.4032-2.771-6.1565-6.174-6.1498-3.403.0067-6.156 2.771-6.1496 6.1738M8 12.0077a4 4 0 1 1 4.008 3.9921A3.9996 3.9996 0 0 1 8 12.0077"
          /></svg><div class="font-medium text-sm hover:link">@{@entity.instagram_handle}</div>
      </a>
      <a
        :if={@entity.facebook_url}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={@entity.facebook_url}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Facebook</title><path
            fill="currentColor"
            d="M9.101 23.691v-7.98H6.627v-3.667h2.474v-1.58c0-4.085 1.848-5.978 5.858-5.978.401 0 .955.042 1.468.103a8.68 8.68 0 0 1 1.141.195v3.325a8.623 8.623 0 0 0-.653-.036 26.805 26.805 0 0 0-.733-.009c-.707 0-1.259.096-1.675.309a1.686 1.686 0 0 0-.679.622c-.258.42-.374.995-.374 1.752v1.297h3.919l-.386 2.103-.287 1.564h-3.246v8.245C19.396 23.238 24 18.179 24 12.044c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.628 3.874 10.35 9.101 11.647Z"
          /></svg><div class="font-medium text-sm hover:link">{@entity.facebook_url}</div>
      </a>
      <a
        :if={@entity.furaffinity_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.furaffinity.net/user/#{@entity.furaffinity_handle}"}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Fur Affinity</title><path
            fill="currentColor"
            d="M5.7 22.086c-.43-.11-1.068-.505-1.193-.74-.113-.21-.02-1.356.116-1.44.113-.07.113-.265 0-.444-.069-.109-.235-.081-.801.132-.89.335-1.195.336-1.839.01C1.348 19.282.7 18.557.273 17.69c-.45-.914-.388-1.097.518-1.538.392-.19.932-.485 1.2-.655l.485-.31-.049-.724-.05-.725.492-.525.492-.526-.185-.285-.438-.671c-.212-.323-.234-.424-.132-.615.158-.295.095-.347-.256-.213-.157.06-.33.108-.384.108-.133 0-.124-.387.016-.648.158-.296.036-.373-.221-.14-.157.141-.245.162-.331.076-.299-.299.627-2.522 1.193-2.867l.351-.214h-.447c-.247 0-.448-.04-.448-.09 0-.302 1.386-.99 2.37-1.175l.678-.128 1.169-1.878c.643-1.033 1.235-1.932 1.316-2 .313-.26.532-.028 1.471 1.548.524.879.982 1.628 1.018 1.664.037.037.371-.164.743-.446.83-.627 3.339-2.091 4.391-2.562.588-.262.817-.32.949-.237.142.09.206.518.355 2.364.1 1.24.18 2.61.177 3.045-.007 1.202.004 1.37.09 1.367.043 0 .265-.262.493-.58.702-.981.523-.945 2.491-.508l1.731.384 1.197 1.007c1.127.949 1.378 1.217 1.253 1.342-.03.029-.758.063-1.62.076-1.845.028-2.937.289-3.567.852-.328.294-.366.386-.377.907-.007.319-.009.612-.004.65.005.04.445-.114.977-.342.532-.227 1.042-.413 1.135-.413.092 0 .582.416 1.089.926l.921.925-.55 1.06-.552 1.06.5.57c.274.313.485.622.47.686-.044.179-1.023.99-1.195.99-.083 0-.151-.036-.152-.079 0-.043-.09-.228-.202-.41l-.201-.33-.718.199c-.956.265-1.105.253-1.456-.114-.358-.373-.478-.33-.478.173 0 .512-.368 1.125-.83 1.381-.409.227-2.396.944-3.438 1.24a7.784 7.784 0 0 0-1.13.43c-1.05.528-1.072.256-.089-1.108.608-.842.946-1.18 2.002-2.007.698-.547 1.29-1.068 1.316-1.16.025-.09.153-.944.284-1.896l.238-1.732-.52-.983c-.518-.978-.52-.984-.34-1.298.098-.173.16-.315.137-.315-.038 0-.784.414-.887.492-.023.018.085.132.24.255.323.253.724.99.904 1.659.137.507.04 2.034-.113 1.792-.057-.09-.09.025-.09.314-.003.465-.376 1.495-.542 1.495-.051 0-.093-.095-.093-.21 0-.117-.048-.212-.106-.212-.065 0-.081.16-.042.41l.066.41-.685-.015c-.502-.01-.738.032-.881.159-.287.253-2.584 1.447-3.396 1.766-1.069.419-1.14.494-1.498 1.602-.176.545-.389 1.096-.473 1.226-.34.521-1.547.87-2.326.67zm1.11-.594c.18-.204.327-.309.327-.231a.447.447 0 0 1-.125.265c-.068.069-.092.158-.051.198.1.1.344-.254.502-.734.153-.463.299-.61.226-.228-.027.143-.025.26.005.26.148 0 .537-.872.724-1.622.28-1.122.361-1.259 1.283-2.13.63-.596.816-.842.91-1.212.192-.748.233-.814.32-.516.044.145.055.382.025.527-.08.403.11.163.607-.763.543-1.011.668-1.105.617-.467l-.038.484.351-.338c.465-.447 1.386-1.672 1.387-1.845 0-.075-.13-.257-.289-.405-.276-.255-.231-.269.25-.075.139.056.156.023.091-.184-.424-1.372-.948-2.169-2.166-3.296-1-.925-1.51-1.273-2.411-1.645l-.727-.299-.658.386c-.614.36-3.89 3.406-3.89 3.617 0 .558 2.683-1.523 3.953-3.064.326-.397.607-.64.74-.64.392-.002 1.555.78 2.428 1.632 1.001.978 1.359 1.584 1.28 2.171-.06.442-.456 1.3-.691 1.495-.13.107-.146.075-.103-.215.027-.189.034-.343.014-.343-.02 0-.181.155-.36.343-.285.303-.317.315-.271.105.063-.289.046-.29-.729-.022a25.67 25.67 0 0 1-1.628.47c-1.125.287-1.701.505-2.13.81-.346.246-.372.402-.065.402.124 0 .388.172.586.383l.362.383.165-.236c.155-.221.728-.53.983-.53.063 0-.006.158-.153.35-.24.315-.267.443-.258 1.239.009.824-.03.993-.543 2.363-.303.811-.665 1.628-.804 1.815-.339.455-1.1.887-1.678.952-.444.05-.462.064-.303.24.284.314.759.464 1.05.331.209-.095.243-.088.194.038-.117.306.364.154.69-.219zm-1.664-.97a4.035 4.035 0 0 0-.251-.386c-.144-.192-.154-.188-.225.095-.08.317.047.47.39.473.147.001.166-.038.086-.183zm1.443-.68c.194-.194.152-.355-.127-.482-.326-.15-.387-.078-.255.3.118.338.191.372.382.182zm-3.1-.35c.21-.087.381-.178.381-.201 0-.175-1.24-.886-2.034-1.165a38.388 38.388 0 0 1-1.158-.421c-.306-.131.179.609.8 1.22.714.703 1.294.867 2.01.567zm-1.279-.127c-.158-.056-.177-.345-.023-.345.11 0 .269.295.195.359-.022.018-.1.012-.172-.014zm-.734-.688c-.2-.26-.242-.381-.149-.439.128-.08.664.352.588.474-.085.138-.32.12-.44-.035zm3.975.296c.813-.147.928-.198 1.245-.557.563-.638.986-1.455.948-1.834-.052-.525-.448-.75-1.425-.805-.451-.026-1.02.006-1.262.072-.582.157-1.206.863-1.45 1.64l-.184.583.276.47c.296.506.547.706.798.637.087-.024.561-.116 1.054-.206zm.1-.96c-.11-.134-.106-.192.03-.328.21-.21.397-.099.397.234 0 .293-.22.342-.426.094zm-.953-.638c-.27-.326.26-.736.594-.459.224.186.19.288-.152.465-.273.141-.32.14-.442-.006zm1.226-.526c-.161-.161-.162-.193-.013-.343.183-.182.338-.09.395.237.047.268-.162.326-.382.106zm4.412 1.437c.425-.182.99-.798.855-.932-.1-.1-1.189.63-1.3.873-.145.319-.157.317.445.06zm-8.732-.641c-.46-.23-.879-.458-.929-.508-.05-.05.19-.122.546-.163.7-.079 1.748-.36 1.662-.447-.03-.03-.426.017-.88.105-1.457.28-1.653.294-1.5.109.074-.089.363-.277.642-.418.544-.276.68-.42.236-.251-.602.229-1.204.657-1.204.857 0 .136.77.61 1.44.885.932.383.926.298-.013-.169zm10.603-.325c.972-.547.98-.556.391-.48-.636.084-1.04.274-1.04.49a.49.49 0 0 1-.127.299c-.218.218-.023.14.776-.309zm8.076-1.603c.037-.565-.019-.588-.69-.283-.496.225-.491.213-.34.761l.11.39.444-.189c.422-.179.446-.212.476-.679zm-5.436-.145c.046-.392-.033-.972-.179-1.32-.045-.107-.031-.185.032-.185.117 0 .546 1.053.546 1.342 0 .14.026.149.13.044.247-.246.077-1.808-.293-2.703-.169-.407.257.05.481.515l.208.433-.035-.527c-.062-.934-.38-1.46-1.203-1.993-1.042-.673-1.089-.759-.417-.753.563.004 1.724-.433 1.985-.747.099-.12.085-.133-.077-.071-.12.046-.042-.085.196-.33.518-.533.535-.822.026-.433-.445.338-.466.277-.08-.229.267-.349.293-.47.327-1.494.036-1.091.033-1.11-.165-.932-.123.111-.24.145-.3.086-.23-.227-.43.18-.615 1.258-.105.609-.253 1.258-.33 1.442-.143.347-.665.751-1.323 1.025l-.38.157-.58-.933-.582-.932.32-.064c.297-.06.306-.075.128-.205-.18-.131-.171-.146.113-.209.309-.068.85-.456.761-.545-.026-.026-.2-.005-.384.048-.39.112-.44-.006-.098-.234.13-.087.397-.453.593-.813.327-.603.338-.65.132-.585-.178.056-.246.014-.33-.206a1.805 1.805 0 0 1-.105-.53c0-.182-.045-.237-.157-.194-.222.085-.298-.192-.175-.637.057-.208.082-.378.055-.378-.118 0-1.311.811-1.962 1.334-.79.634-.854.828-.55 1.67.083.231.152.428.153.438 0 .01-.07.006-.158-.007-.088-.013-.337-.196-.553-.407-.573-.557-1.494-.93-2.448-.992-.83-.053-.883.098-.083.233.863.146.47.26-.896.26-1.059 0-1.615.052-2.222.207-.99.253-1.374.438-.732.353.554-.074 1.637.055 1.556.185-.033.054-.2.098-.373.098-.573 0-1.49.4-1.95.853-.402.394-1.07 1.528-.963 1.634.025.025.254-.07.509-.213.66-.366 1.57-.708 1.57-.59 0 .055-.102.154-.226.22-.53.285-1.46 1.31-1.46 1.611 0 .027.25-.018.553-.099.305-.08.673-.147.82-.148.248-.001.264.029.232.447l-.034.447.237-.316c.395-.528 2.1-2.244 2.853-2.872.39-.325.697-.604.682-.619-.015-.015-.204.013-.42.061-.609.138-.461-.06.214-.285l.606-.202-.395-.075c-.676-.127-.433-.245.304-.146 1.468.197 2.966 1.002 4.336 2.33 1.051 1.02 1.635 1.917 2.014 3.097l.311.972-.5.766c-.659 1.007-.906 1.438-.848 1.48.051.037 1.375.473 1.485.489.037.005.088-.167.113-.382zm-9.664-.727l1.053-1.013-.422.068-.421.068.263-.211c.312-.251.258-.269-.224-.072-.195.08-.474.182-.619.225-.262.08-.262.079-.063-.145.438-.49.006-.183-.76.54-.446.42-1 .92-1.232 1.108-.366.298-.387.336-.158.289.145-.03.5-.012.79.039.29.05.575.098.634.105.058.007.58-.444 1.159-1zm-1.747-.388c.327-.297.423-.452.375-.606-.068-.212-.262-.287-.262-.1a.106.106 0 0 1-.106.105c-.058 0-.105-.118-.105-.263 0-.34-.14-.335-.414.014-.276.351-.28.5-.008.355.249-.134.273-.017.056.27-.167.221-.22.718-.068.66.05-.019.29-.215.532-.435zm15.769-.113c.443-.196.754-.388.69-.427-.135-.084-1.518.504-1.573.669-.055.163-.008.15.883-.242zm-15.231-1.64c-.06-.112-.11-.35-.11-.527 0-.344-.173-.437-.283-.151-.07.183.254.882.41.882.05 0 .043-.092-.017-.204zm.38-.272c.063-.164-.127-.473-.291-.473-.108 0-.126.459-.023.562.117.117.25.08.314-.089zm4.212-.492l.347-.262c.023-.018-.078-.126-.225-.242-.319-.25-.641-.998-.552-1.28.087-.272-.09-.25-.445.056-.252.216-.295.33-.289.768.009.626.309 1.19.634 1.19.124 0 .363-.104.53-.23zm-4.962-1.33c-.078-.078-.396.107-.447.26-.02.058.072.155.204.214.211.095.244.077.275-.15.018-.142.004-.288-.032-.324zm5.232.016c.106-.096.192-.231.192-.3 0-.208-.378-.484-.564-.413-.203.078-.234.574-.047.76.163.164.189.161.419-.047zm5.653-1.38c.377-.361.427-.476.583-1.344.094-.521.244-1.517.334-2.213a87.1 87.1 0 0 1 .262-1.89c.055-.345.082-.644.06-.666-.021-.021-.261.616-.533 1.417-.272.8-.52 1.527-.552 1.614-.033.089.062.047.22-.098.152-.14.277-.216.277-.167 0 .271-.39 1.314-.599 1.601-.28.385-.317.542-.083.347.433-.36.226.322-.27.887-.304.345-.318.554-.017.254.238-.239.14.15-.103.41-.378.402-.023.274.421-.152zm-4.133-2.467c-.191-.273-.227-.183-.055.138.063.117.139.188.17.158.03-.03-.022-.163-.115-.296zm-.64-1.149c.16-.31.156-.343-.125-.817-.208-.352-.303-.44-.33-.31-.047.23-.22.235-.532.016-.24-.167-.24-.166-.172.2.038.201.025.394-.028.427-.054.033-.339-.103-.634-.302l-.537-.362-.069.314c-.038.173-.11.314-.16.314-.137 0-.419-.442-.419-.656 0-.331-.148-.201-.599.525l-.44.71.322.034c.177.02.373-.016.435-.079.187-.186 1.744-.127 2.337.089.729.265.763.261.952-.103zm1.1 14.733l-.47-.237v-1.264l.79-.394c.435-.216.824-.394.865-.395.106-.002.61.881.61 1.07 0 .159-1.114 1.457-1.25 1.457-.042 0-.287-.106-.545-.237zm-1.154-.657c-.196-.202-.335-.386-.31-.41.025-.024.223-.117.44-.207l.395-.164v.574c0 .316-.038.574-.084.574-.047 0-.245-.165-.44-.367zm2.876-1.33c-.278-.42-.282-.448-.097-.558.107-.063.51-.316.894-.561.691-.441.962-.54.962-.354 0 .116-1.2 1.748-1.356 1.845-.061.038-.243-.13-.403-.373z"
          /></svg><div class="font-medium text-sm hover:link">{@entity.furaffinity_handle}</div>
      </a>
      <div :if={@entity.discord_handle} class="flex flex-row flex-nowrap gap-1 items-center">
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Discord</title><path
            fill="currentColor"
            d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"
          /></svg><div class="font-medium text-sm hover:link">{@entity.discord_handle}</div>
      </div>
      <a
        :if={@entity.artstation_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://artstation.com/#{@entity.artstation_handle}"}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>ArtStation</title><path
            fill="currentColor"
            d="M0 17.723l2.027 3.505h.001a2.424 2.424 0 0 0 2.164 1.333h13.457l-2.792-4.838H0zm24 .025c0-.484-.143-.935-.388-1.314L15.728 2.728a2.424 2.424 0 0 0-2.142-1.289H9.419L21.598 22.54l1.92-3.325c.378-.637.482-.919.482-1.467zm-11.129-3.462L7.428 4.858l-5.444 9.428h10.887z"
          /></svg><div class="font-medium text-sm hover:link">{@entity.artstation_handle}</div>
      </a>
      <a
        :if={@entity.deviantart_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.deviantart.com/#{@entity.deviantart_handle}"}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>DeviantArt</title><path
            fill="currentColor"
            d="M19.207 4.794l.23-.43V0H15.07l-.436.44-2.058 3.925-.646.436H4.58v5.993h4.04l.36.436-4.175 7.98-.24.43V24H8.93l.436-.44 2.07-3.925.644-.436h7.35v-5.993h-4.05l-.36-.438 4.186-7.977z"
          /></svg><div class="font-medium text-sm hover:link">{@entity.deviantart_handle}</div>
      </a>
      <a
        :if={@entity.tumblr_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.tumblr.com/blog/#{@entity.tumblr_handle}"}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Tumblr</title><path
            fill="currentColor"
            d="M14.563 24c-5.093 0-7.031-3.756-7.031-6.411V9.747H5.116V6.648c3.63-1.313 4.512-4.596 4.71-6.469C9.84.051 9.941 0 9.999 0h3.517v6.114h4.801v3.633h-4.82v7.47c.016 1.001.375 2.371 2.207 2.371h.09c.631-.02 1.486-.205 1.936-.419l1.156 3.425c-.436.636-2.4 1.374-4.156 1.404h-.178l.011.002z"
          /></svg><div class="font-medium text-sm hover:link">{@entity.tumblr_handle}</div>
      </a>
      <a
        :if={@entity.twitch_channel}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.twitch.tv/#{@entity.twitch_channel}"}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Twitch</title><path
            fill="currentColor"
            d="M11.571 4.714h1.715v5.143H11.57zm4.715 0H18v5.143h-1.714zM6 0L1.714 4.286v15.428h5.143V24l4.286-4.286h3.428L22.286 12V0zm14.571 11.143l-3.428 3.428h-3.429l-3 3v-3H6.857V1.714h13.714Z"
          /></svg><div class="font-medium text-sm hover:link">{@entity.twitch_channel}</div>
      </a>
      <a
        :if={@entity.pixiv_handle && @entity.pixiv_url}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={@entity.pixiv_url}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>pixiv</title><path
            fill="currentColor"
            d="M4.935 0A4.924 4.924 0 0 0 0 4.935v14.13A4.924 4.924 0 0 0 4.935 24h14.13A4.924 4.924 0 0 0 24 19.065V4.935A4.924 4.924 0 0 0 19.065 0zm7.81 4.547c2.181 0 4.058.676 5.399 1.847a6.118 6.118 0 0 1 2.116 4.66c.005 1.854-.88 3.476-2.257 4.563-1.375 1.092-3.225 1.697-5.258 1.697-2.314 0-4.46-.842-4.46-.842v2.718c.397.116 1.048.365.635.779H5.79c-.41-.41.19-.65.644-.779V7.666c-1.053.81-1.593 1.51-1.868 2.031.32 1.02-.284.969-.284.969l-1.09-1.73s3.868-4.39 9.553-4.39zm-.19.971c-1.423-.003-3.184.473-4.27 1.244v8.646c.988.487 2.484.832 4.26.832h.01c1.596 0 2.98-.593 3.93-1.533.952-.948 1.486-2.183 1.492-3.683-.005-1.54-.504-2.864-1.42-3.86-.918-.992-2.274-1.645-4.002-1.646Z"
          /></svg><div class="font-medium text-sm hover:link">{@entity.pixiv_handle}</div>
      </a>
      <a
        :if={@entity.picarto_channel}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://picarto.tv/#{@entity.picarto_channel}"}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Picarto.TV</title><path
            fill="currentColor"
            d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12c6.628 0 12-5.373 12-12S18.628 0 12 0zM7.08 4.182h2.781c.233 0 .42.21.42.47v14.696c0 .26-.187.47-.42.47h-2.78c-.233 0-.42-.21-.42-.47V4.652c0-.26.187-.47.42-.47zm4.664 0a.624.624 0 0 1 .326.091c.355.209 7.451 4.42 8.057 4.78a.604.604 0 0 1 0 1.039c-.436.264-7.558 4.495-8.074 4.789a.577.577 0 0 1-.873-.512v-1.812c0-1.712 2.962-2.201 3.398-2.465a.604.604 0 0 0 0-1.04c-.605-.36-3.398-.746-3.398-2.452V4.79c0-.334.251-.605.564-.61z"
          /></svg><div class="font-medium text-sm hover:link">{@entity.picarto_channel}</div>
      </a>
      <a
        :if={@entity.tiktok_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.tiktok.com/@#{@entity.tiktok_handle}"}
      >
        <svg role="img" height="12" width="12" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>TikTok</title><path
            fill="currentColor"
            d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"
          /></svg><div class="font-medium text-sm hover:link">@{@entity.tiktok_handle}</div>
      </a>
      <a
        :if={@entity.artfight_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://artfight.net/~#{@entity.artfight_handle}"}
      >
        <img width="16" src={Routes.static_path(Endpoint, "/images/artfight-favicon.svg")}><div class="font-medium text-sm hover:link">~{@entity.artfight_handle}</div>
      </a>
    </div>
    """
  end
end
