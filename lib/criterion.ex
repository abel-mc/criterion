defmodule Criterion do
  @moduledoc """
  A framework to write unit tests as a list of steps. It can be used to write tests in a BDD style.

  ## Usage

  - Define a feature using `feature/2` macro
  - Define scenarios under the feature using the `scenario/2` macro.
  - Inside each scenario, define steps using `step/2` block.
  - Steps can have either inline or external implementation.
  - External implementations allows reusability and can be defined using `defstep/2` macro.

  ## Example

  ```elixir
  defmodule CriterionTest do
    use ExUnit.Case
    import Criterion

    feature "Math" do
      setup do
        {:ok, pi: 3.14}
      end

      scenario "Square" do
        # Step with external implementation
        step("Given a number greater than 5",
          via: &random_number/2,
          where: [min: 2] # Options passed as second argument to the function
        )

        # Step with inline implementation
        step "When the number is multiplied by it self", %{number: number} do
          result = number * number
          %{result: result} # will be merged to the test context
        end

        step "Then the result is greater than the number", %{result: result, number: number} do
          assert result > number
        end

        # You can access data from the initial context of the test
        step "And pi is a constant", %{pi: pi} do
          assert pi == 3.14
        end
      end

      # External step implementation
      defstep random_number(_context, args) do
        min = args[:min] || 0
        %{number: min + Enum.random(0..100)}
      end
    end
  end
  ```
  """
  alias Criterion.Reporter.Store

  require Logger

  @context_var quote(do: context)

  defmacro feature(description, do: block) do
    quote do
      describe unquote(description) do
        unquote(block)
      end
    end
  end

  defmacro scenario(description, do: block) do
    steps = extract_steps(block, description)

    quote do
      test unquote(description), unquote(@context_var) do
        require Logger

        unquote(steps)
        |> case do
          {:error, e, _} ->
            raise e

          _ ->
            :ok
        end
      end
    end
  end

  defmacro defstep({_fn_name, _line, [_context, _args]} = func, do: block) do
    quote do
      def unquote(func) do
        unquote(block)
      end
    end
  end

  defp extract_steps({:__block__, _, steps}, scenario_description) do
    steps
    |> Enum.reduce(
      @context_var,
      fn
        {:step, _line, [step_description | _]} = step, acc ->
          step_code = extract_step(step, scenario_description)

          quote do
            case unquote(acc) do
              {:error, e, context} ->
                Store.add_step(
                  {context.describe, unquote(scenario_description), unquote(step_description),
                   :not_reached}
                )

                {:error, e, context}

              context ->
                try do
                  result = unquote(step_code).(context)

                  Store.add_step(
                    {context.describe, unquote(scenario_description), unquote(step_description),
                     :passed}
                  )

                  if is_map(result) do
                    Map.merge(context, result)
                  else
                    context
                  end
                rescue
                  e ->
                    Logger.error(
                      "Test failed for \nScenario: #{unquote(scenario_description)}, \nStep: #{unquote(step_description)} \nException: #{Exception.format(:error, e, __STACKTRACE__)}"
                    )

                    Store.add_step(
                      {context.describe, unquote(scenario_description), unquote(step_description),
                       :failed}
                    )

                    {:error, e, context}
                end
            end
          end
      end
    )
  end

  defp extract_step(
         {:step, _line, [_step_description, [do: block]]},
         _scenario_description
       ) do
    quote do
      fn context ->
        unquote(block)
      end
    end
  end

  defp extract_step(
         {:step, _line, [_step_description, context_var, [do: block]]},
         _scenario_description
       ) do
    quote do
      fn context ->
        unquote(context_var) = context
        unquote(block)
      end
    end
  end

  defp extract_step(
         {:step, _line, [_step_description | opts]},
         _scenario_description
       ) do
    opts = List.flatten(opts)

    via = opts[:via]
    where = opts[:where]

    cond do
      match?({:&, _, _}, via) ->
        quote do
          fn context ->
            unquote(via).(context, unquote(where))
          end
        end

      true ->
        quote do
          fn context ->
            context
          end
        end
    end
  end
end
