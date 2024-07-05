defmodule Exepted.Scenario do
  require Logger

  defmacro scenario(description, do: block) do
    steps = extract_steps(block, description)

    quote do
      test unquote(description) do
        require Logger
        context = %{}

        context = unquote(steps).(context)
        :ok
      end
    end
  end

  defmacro step(description, do: block) do
    quote do
      fn context ->
        require Logger
        Logger.info("Step: #{inspect(unquote(description))}")
        unquote(block).(context)
      end
    end
  end

  defp extract_steps({:__block__, _, steps}, scenario_description) do
    Enum.reduce(steps, quote(do: context), fn step, acc ->
      step_code = extract_step(step, scenario_description)

      quote do
        context = unquote(acc)
        context = unquote(step_code).(context)
      end
    end)
  end

  defp extract_step({:step, _line, [step_description, [do: block]]}, scenario_description) do
    quote do
      fn context ->
        try do
          unquote(block).(context)
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
end
