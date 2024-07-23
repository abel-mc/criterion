defmodule Criterion do
  @moduledoc """
  A frame work to write unit tests as a list of steps. It can be used to write tests BDD style.

  ## Usage

  1. Define a feature using `feature/2` macro
  2. Define scenarios under the feature using the `scenario/2` macro.
  3. Inside each scenario, define steps using `step/2` block.
  4. Steps can be either plain steps, steps with context variables or shared step
  5. Shared steps can be defined using `defstep/4` macro

  ## Example

  ### Shared steps

  ```elixir
  defmodule Criterion.SharedSteps do
    import Criterion

    defstep "Given a number", _context, args do
      min = args[:min] || 0
      %{number: min + Enum.random(0..100)}
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
      setup do
        {:ok, pi: 3.14}
      end

      scenario "Square" do
        step("Given a number greater than 5",
          from: SharedSteps, # use only if the reusable step is in another module
          via: "Given a number" # use only if the reusable step has a different step name,
          where: [min: 5] # use only when you want to pass arguments to the reusable step,
        )

        step "When the number is multiplied by it self", %{number: number} do
          result = number * number
          %{result: result} # will be merged to the test context
        end

        step "Then the result is greater than the number", %{result: result, number: number} do
          assert result > number
        end

        # you can access data from the initial context of the test
        step "And pi is a constant", %{pi: pi} do
          assert pi == 3.14
        end
      end
    end
  end
  ```
  """

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
    Enum.reduce(steps, @context_var, fn step, acc ->
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
    via = opts[:via]
    step_description = via || step_description

    if from do
      quote do
        fn context ->
          unquote(from).step(unquote(step_description), context, unquote(where))
        end
      end
    else
      quote do
        fn context -> step(unquote(step_description), context, unquote(where)) end
      end
    end
  end
end
