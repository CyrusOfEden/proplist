defmodule Proplist.Mixfile do
  use Mix.Project

  def project do
    [app: :proplist,
     description: "Proplist provides the complete Keyword API, but for Proplists.",
     version: "1.1.0",
     elixir: "~> 1.1",
     name: "Proplist",
     source_url: "https://github.com/knrz/proplist",
     homepage_url: "https://github.com/knrz/proplist",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: [contributors: ["Kash Nouroozi"],
               licenses: ["MIT"],
               links: %{"GitHub" => "https://github.com/knrz/proplist"}
    ]]
  end

  def application do
    []
  end

  defp deps do
    [{:inch_ex, only: :dev},
     {:ex_doc, only: :dev},
     {:earmark, only: :dev}]
  end
end
