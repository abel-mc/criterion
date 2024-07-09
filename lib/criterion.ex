defmodule Criterion do
  require Logger

  @moduledoc """
  A frame work to write unit tests as a list of steps. It can be used to write tests BDD style.

  ## Usage

  1. Define scenarios using the `scenario/2` macro.
  2. Inside each scenario, define steps using the `step/2` macro.
  3. Steps can be either plain steps or steps with context variables.
  4. Shared steps can be defined external to the scenario

  ## Example



  ```elixir
  # Define a scenario
  step "Shared", context do
    context
  end

  scenario "Adding numbers" do
    # Use a shared step
    step "Shared"
    # Define a step
    step "Addition" do
      assert 1 + 1 == 2
    end



    # Define a step with context
    step "Addition with context", context do
      result = context[:a] + context[:b]
      assert result == 5
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

  defmacro step(description, step_var \\ Macro.escape(%{}), do: block) do
    quote do
      def step_(unquote(description), unquote(step_var)) do
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
         {:step, _line, [step_description]},
         _scenario_description
       ) do
    quote do
      fn context ->
        step_(unquote(step_description), context)
      end
    end
  end
end
