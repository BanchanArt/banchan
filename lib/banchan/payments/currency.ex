defmodule Banchan.Payments.Currency do
  @moduledoc """
  Handling of currencies and countries for payments.
  """

  @supported_currencies [
    :USD,
    :AED,
    :AFN,
    :ALL,
    :AMD,
    :ANG,
    :AOA,
    :ARS,
    :AUD,
    :AWG,
    :AZN,
    :BAM,
    :BBD,
    :BDT,
    :BGN,
    :BIF,
    :BMD,
    :BND,
    :BOB,
    :BRL,
    :BSD,
    :BWP,
    :BYN,
    :BZD,
    :CAD,
    :CDF,
    :CHF,
    :CLP,
    :CNY,
    :COP,
    :CRC,
    :CVE,
    :CZK,
    :DJF,
    :DKK,
    :DOP,
    :DZD,
    :EGP,
    :ETB,
    :EUR,
    :FJD,
    :FKP,
    :GBP,
    :GEL,
    :GIP,
    :GMD,
    :GNF,
    :GTQ,
    :GYD,
    :HKD,
    :HNL,
    :HRK,
    :HTG,
    :HUF,
    :IDR,
    :ILS,
    :INR,
    :ISK,
    :JMD,
    :JPY,
    :KES,
    :KGS,
    :KHR,
    :KMF,
    :KRW,
    :KYD,
    :KZT,
    :LAK,
    :LBP,
    :LKR,
    :LRD,
    :LSL,
    :MAD,
    :MDL,
    :MGA,
    :MKD,
    :MMK,
    :MNT,
    :MOP,
    :MRO,
    :MUR,
    :MVR,
    :MWK,
    :MXN,
    :MYR,
    :MZN,
    :NAD,
    :NGN,
    :NIO,
    :NOK,
    :NPR,
    :NZD,
    :PAB,
    :PEN,
    :PGK,
    :PHP,
    :PKR,
    :PLN,
    :PYG,
    :QAR,
    :RON,
    :RSD,
    :RUB,
    :RWF,
    :SAR,
    :SBD,
    :SCR,
    :SEK,
    :SGD,
    :SHP,
    :SLL,
    :SOS,
    :SRD,
    :STD,
    :SZL,
    :THB,
    :TJS,
    :TOP,
    :TRY,
    :TTD,
    :TWD,
    :TZS,
    :UAH,
    :UGX,
    :UYU,
    :UZS,
    :VND,
    :VUV,
    :WST,
    :XAF,
    :XCD,
    :XOF,
    :XPF,
    :YER,
    :ZAR,
    :ZMW
  ]

  @doc """
  Returns a list of supported currencies as atoms using their uppercase
  3-letter currency codes. This is based on Stripe's list of supported
  currencies.

  See https://stripe.com/docs/currencies?presentment-currency=US#presentment-currencies
  """
  def supported_currencies do
    @supported_currencies
    |> Enum.sort_by(&currency_name/1)
  end

  @supported_countries [
    "Antigua and Barbuda": :AG,
    Argentina: :AR,
    Australia: :AU,
    Austria: :AT,
    Bahrain: :BH,
    Bangladesh: :BD,
    Belgium: :BE,
    Benin: :BJ,
    Bolivia: :BO,
    Bulgaria: :BG,
    Canada: :CA,
    Chile: :CL,
    Colombia: :CO,
    "Costa Rica": :CR,
    "Côte d'Ivoire": :CI,
    Croatia: :HR,
    Cyprus: :CY,
    "Czech Republic": :CZ,
    Denmark: :DK,
    "Dominican Republic": :DO,
    Egypt: :EG,
    Estonia: :EE,
    Finland: :FI,
    France: :FR,
    Gambia: :GM,
    Germany: :DE,
    Ghana: :GH,
    Greece: :GR,
    Guatemala: :GT,
    Guyana: :GY,
    "Hong Kong": :HK,
    Hungary: :HU,
    Iceland: :IS,
    India: :IN,
    Indonesia: :ID,
    Ireland: :IE,
    Israel: :IL,
    Italy: :IT,
    Jamaica: :JM,
    Japan: :JP,
    Kenya: :KE,
    Kuwait: :KW,
    Latvia: :LV,
    Liechtenstein: :LI,
    Lithuania: :LT,
    Luxembourg: :LU,
    Malta: :MT,
    Mauritius: :MU,
    Mexico: :MX,
    Monaco: :MC,
    Morocco: :MA,
    Namibia: :NA,
    Netherlands: :NL,
    "New Zealand": :NZ,
    Norway: :NO,
    Paraguay: :PY,
    Peru: :PE,
    Philippines: :PH,
    Poland: :PL,
    Portugal: :PT,
    Romania: :RO,
    "San Marino": :SM,
    "Saudi Arabia": :SA,
    Senegal: :SN,
    Serbia: :RS,
    Singapore: :SG,
    Slovakia: :SK,
    Slovenia: :SI,
    "South Africa": :ZA,
    "South Korea": :KR,
    Spain: :ES,
    "St. Lucia": :LC,
    Sweden: :SE,
    Switzerland: :CH,
    Thailand: :TH,
    "Trinidad and Tobago": :TT,
    Tunisia: :TN,
    Turkey: :TR,
    "United Arab Emirates": :AE,
    "United Kingdom": :GB,
    "United States": :US,
    Uruguay: :UY,
    Vietnam: :VN
  ]

  @doc """
  This returns a Keyword list of supported countries, based on Stripe's
  currently supported list of cross-border payout countries. They key in each
  entry is the full country name, and the value is the 2-letter country code.

  See https://stripe.com/docs/connect/cross-border-payouts#supported-countries
  """
  def supported_countries do
    @supported_countries
  end

  @doc """
  Returns the atom for the configured platform currency.
  """
  def platform_currency, do: Application.fetch_env!(:banchan, :platform_currency)

  ## Misc utilities

  @doc """
  Formats money with improved semantics over the default Money.to_string/2.
  For example, differentiating between different kinds of dollars that would
  usually just use `$` as a symbol.
  """
  def print_money(%Money{} = money, symbol \\ true) do
    if symbol do
      case Money.Currency.symbol(money) do
        "$" -> currency_symbol(money.currency) <> Money.to_string(money, symbol: false)
        "" -> currency_symbol(money.currency) <> " " <> Money.to_string(money, symbol: false)
        " " -> currency_symbol(money.currency) <> " " <> Money.to_string(money, symbol: false)
        _ -> Money.to_string(money, symbol: true)
      end
    else
      Money.to_string(money, symbol: false)
    end
  end

  def currency_symbol(%Money{currency: currency}) do
    currency_symbol(currency)
  end

  def currency_symbol(currency) when is_atom(currency) do
    case Money.Currency.symbol(currency) do
      "$" -> dollar_prefix(currency) <> "$"
      "¥" when currency == :CNY -> "RMB"
      "kr" when currency == :NOK -> "NKr"
      _ when currency == :KMF -> "FC"
      "" -> blank_prefix(currency)
      " " -> blank_prefix(currency)
      other -> other
    end
  end

  defp dollar_prefix(:USD), do: ""
  defp dollar_prefix(:AUD), do: "AU"
  defp dollar_prefix(:ARS), do: "Arg"
  defp dollar_prefix(:BBD), do: "BB"
  defp dollar_prefix(:BMD), do: "BD"
  defp dollar_prefix(:BND), do: "B"
  defp dollar_prefix(:BSD), do: "B"
  defp dollar_prefix(:CVE), do: "Esc"
  defp dollar_prefix(:KYD), do: "KY"
  defp dollar_prefix(:CLP), do: "CLP"
  defp dollar_prefix(:COP), do: "COP"
  defp dollar_prefix(:XCD), do: "EC"
  defp dollar_prefix(:FJD), do: "FJ"
  defp dollar_prefix(:GYD), do: "GY"
  defp dollar_prefix(:HKD), do: "HK"
  defp dollar_prefix(:LRD), do: "LD"
  defp dollar_prefix(:MXN), do: "Mex"
  defp dollar_prefix(:NZD), do: "NZ"
  defp dollar_prefix(:NAD), do: "N"
  defp dollar_prefix(:SBD), do: "SI"
  defp dollar_prefix(:SRD), do: "Sr"
  defp dollar_prefix(_), do: ""

  defp blank_prefix(:XOF), do: "F.CFA"
  defp blank_prefix(:XPF), do: "F.CFP"
  defp blank_prefix(:HTG), do: "G"
  defp blank_prefix(:LSL), do: "R"
  defp blank_prefix(:RWF), do: "R₣‎"
  defp blank_prefix(:TJS), do: "SM"
  defp blank_prefix(_), do: ""

  def currency_name(%Money{currency: currency}) do
    currency_symbol(currency)
  end

  def currency_name(currency) when is_atom(currency) do
    case currency do
      :VNĐ -> "Vietnamese Dong"
      other -> other
    end
  end
end
