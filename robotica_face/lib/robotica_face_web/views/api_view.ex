defmodule RoboticaFaceWeb.ApiView do
  use RoboticaFaceWeb, :view

  def render("index.json", %{fulfillmentMessages: fulfillmentMessages}) do
    %{
      fulfillmentMessages: fulfillmentMessages
    }
  end

  def render("index.json", %{fulfillmentText: fulfillmentText}) do
    %{
      fulfillmentText: fulfillmentText
    }
  end
end
