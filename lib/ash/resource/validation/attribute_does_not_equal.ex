defmodule Ash.Resource.Validation.AttributeDoesNotEqual do
  @moduledoc false

  use Ash.Resource.Validation

  alias Ash.Error.Changes.InvalidAttribute

  @opt_schema [
    attribute: [
      type: :atom,
      required: true,
      doc: "The attribute to check"
    ],
    value: [
      type: :any,
      required: true,
      doc: "The value the attribute must not equal"
    ]
  ]

  @impl true
  def init(opts) do
    case Spark.OptionsHelpers.validate(opts, @opt_schema) do
      {:ok, opts} ->
        {:ok, opts}

      {:error, error} ->
        {:error, Exception.message(error)}
    end
  end

  @impl true
  def validate(changeset, opts) do
    value = Ash.Changeset.get_attribute(changeset, opts[:attribute])

    if value == opts[:value] do
      {:error,
       InvalidAttribute.exception(
         field: opts[:attribute],
         value: value,
         message: "must not equal %{value}",
         vars: [field: opts[:attribute], value: opts[:value]]
       )}
    else
      :ok
    end
  end
end
