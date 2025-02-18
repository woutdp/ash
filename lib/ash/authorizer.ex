defmodule Ash.Authorizer do
  @moduledoc """
  The interface for an ash authorizer

  These will typically be implemented by an extension, but a custom
  one can be implemented by defining an extension that also adopts this behaviour.

  Then you can extend a resource with `authorizers: [YourAuthorizer]`
  """
  @type state :: map
  @type context :: map
  @callback initial_state(
              Ash.Resource.t(),
              Ash.Resource.record(),
              Ash.Resource.Actions.action(),
              boolean
            ) :: state
  @callback strict_check_context(state) :: [atom]
  @callback strict_check(state, context) ::
              {:authorized, state}
              | {:continue, state}
              | {:filter, Keyword.t()}
              | {:filter, Keyword.t(), state}
              | {:filter_and_continue, Keyword.t(), state}
              | {:error, term}
  @callback check_context(state) :: [atom]
  @callback check(state, context) ::
              :authorized | {:data, list(Ash.Resource.record())} | {:error, term}
  @callback exception(atom, state) :: no_return

  @optional_callbacks [exception: 2]

  def initial_state(module, actor, resource, action, verbose?) do
    module.initial_state(actor, resource, action, verbose?)
  end

  def exception(module, reason, state) do
    if function_exported?(module, :exception, 2) do
      module.exception(reason, state)
    else
      if reason == :must_pass_strict_check do
        Ash.Error.Forbidden.MustPassStrictCheck.exception([])
      else
        Ash.Error.Forbidden.exception([])
      end
    end
  end

  def strict_check_context(module, state) do
    module.strict_check_context(state)
  end

  def strict_check(module, state, context) do
    module.strict_check(state, context)
  end

  def check_context(module, state) do
    module.check_context(state)
  end

  def check(module, state, context) do
    module.check(state, context)
  end
end
