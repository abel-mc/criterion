defmodule Criterion do
  require Logger

  @moduledoc """
  A frame work to write unit tests as a list of steps. It can be used to write tests BDD style.

  ## Usage

  1. Define a feature using `feature/2` macro
  2. Define scenarios under the feature using the `scenario/3` macro.
  2. Inside each scenario, define steps using the `step/3` macro.
  3. Steps can be either plain steps, steps with context variables or shared step
  4. Shared steps can be defined using `defstep/4` macro

  ## Example

  ### Shared steps

  ```elixir
  defmodule Criterion.SharedSteps do
    import Criterion

    defstep "Given a number", _context, args do
      min = args[:min] || 0
      %{number: min + :rand.uniform(100)}
    end
  end
  ```

  ### Test

  ```elixir
  defmodule CriterionTest do
    use ExUnit.Case
    import Criterion
    alias Criterion.SharedSteps

    feature "Math" do
      scenario "Square" do
        step "Given a number", from: SharedSteps, where: [min: 2]

        step "When the number is multiplied by it self", %{number: number} do
          result = number * number
          %{result: result}
        end

        step "Then the result is greater than the number", %{result: result, number: number} do
          assert result > number
        end
      end
    end
  end
  ```
  """

  defmacro feature(description, do: block) do
    quote do
      describe unquote(description) do
        unquote(block)
      end
    end
  end

  defmacro scenario(description, test_vars \\ Macro.escape(%{}), do: block) do
    steps = extract_steps(block, description)

    quote do
      test unquote(description), unquote(test_vars) do
        require Logger

        unquote(steps)
        :ok
      end
    end
  end

  defmacro defstep(description, step_var, where_var, do: block) do
    quote do
      def step(unquote(description), unquote(step_var), unquote(where_var)) do
        unquote(block)
      end
    end
  end

  defp extract_steps({:__block__, _, steps}, scenario_description) do
    Enum.reduce(steps, quote(do: %{}), fn step, acc ->
      step_code = extract_step(step, scenario_description)

      quote do
        context = unquote(acc)
        result = unquote(step_code).(context)

        if is_map(result) do
          Map.merge(context, result)
        else
          context
        end
      end
    end)
  end

  defp extract_step(
         {:step, _line, [step_description, [do: block]]},
         scenario_description
       ) do
    quote do
      fn context ->
        try do
          unquote(block)
        rescue
          e ->
            Logger.error(
              "Test failed for Scenario: #{unquote(scenario_description)}, Step: #{unquote(step_description)}"
            )

            raise e
        end
      end
    end
  end

  defp extract_step(
         {:step, _line, [step_description, context_var, [do: block]]},
         scenario_description
       ) do
    quote do
      fn context ->
        try do
          unquote(context_var) = context
          unquote(block)
        rescue
          e ->
            Logger.error(
              "Test failed for Scenario: #{unquote(scenario_description)}, Step: #{unquote(step_description)}"
            )

            raise e
        end
      end
    end
  end

  defp extract_step(
         {:step, _line, [step_description | opts]},
         _scenario_description
       ) do
    opts = List.flatten(opts)
    from = opts[:from]
    where = opts[:where]

    if from do
      quote do
        fn context -> unquote(from).step(unquote(step_description), context, unquote(where)) end
      end
    else
      quote do
        fn context -> step(unquote(step_description), context, unquote(where)) end
      end
    end
  end
end
