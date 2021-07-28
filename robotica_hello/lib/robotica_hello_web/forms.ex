defmodule RoboticaHelloWeb.Forms do
  @moduledoc "Form field help functions"
  use Phoenix.HTML

  def field_class(form, field, class) do
    errors = form.errors[field]

    case errors do
      nil -> class
      _ -> "#{class} is-invalid"
    end
  end

  defmacro text_input_field(form, field, _opts \\ []) do
    quote do
      field_class = field_class(unquote(form), unquote(field), "form-control")

      content_tag :div, class: "form-group" do
        [
          label(unquote(form), unquote(field), class: "control-label"),
          text_input(unquote(form), unquote(field), class: field_class),
          error_tag(unquote(form), unquote(field))
        ]
      end
    end
  end

  defmacro number_input_field(form, field, _opts \\ []) do
    quote do
      field_class = field_class(unquote(form), unquote(field), "form-control")

      content_tag :div, class: "form-group" do
        [
          label(unquote(form), unquote(field), class: "control-label"),
          number_input(unquote(form), unquote(field), class: field_class),
          error_tag(unquote(form), unquote(field))
        ]
      end
    end
  end

  defmacro select_field(form, field, options, _opts \\ []) do
    quote do
      field_class = field_class(unquote(form), unquote(field), "form-control")

      content_tag :div, class: "form-group" do
        [
          label(unquote(form), unquote(field), class: "control-label"),
          select(unquote(form), unquote(field), unquote(options), class: field_class),
          error_tag(unquote(form), unquote(field))
        ]
      end
    end
  end

  defmacro password_input_field(form, field, _opts \\ []) do
    quote do
      field_class = field_class(unquote(form), unquote(field), "form-control")

      content_tag :div, class: "form-group" do
        [
          label(unquote(form), unquote(field), class: "control-label"),
          password_input(unquote(form), unquote(field), class: field_class),
          error_tag(unquote(form), unquote(field))
        ]
      end
    end
  end

  defmacro checkbox_field(form, field, _opts \\ []) do
    quote do
      field_class = field_class(unquote(form), unquote(field), "form-check-input")

      content_tag :div, class: "form-group form-check" do
        [
          checkbox(unquote(form), unquote(field), class: field_class),
          label(unquote(form), unquote(field), class: "control-label"),
          error_tag(unquote(form), unquote(field))
        ]
      end
    end
  end
end
