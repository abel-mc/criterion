defmodule Criterion.Reporter do
  alias Criterion.Reporter.Store
  use GenServer

  @impl true
  def init(_opts) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:suite_finished, _config}, state) do
    steps = Store.get_steps()
    generate_html_report(steps)
    {:noreply, state}
  end

  @impl true
  def handle_cast(_, config), do: {:noreply, config}

  defp generate_html_report(steps) do
    features =
      steps
      |> Enum.group_by(fn {feature, _scenario, _step, _status} -> feature end)
      |> Enum.map(fn {group, feature_steps} ->
        {group,
         Enum.group_by(
           feature_steps,
           fn {_feature, scenario, _step, _status} -> scenario end,
           fn {_feature, _scenario, step, status} -> {step, status} end
         )}
      end)

    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Test Report</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          background-color: #f8f9fa;
          margin: 20px;
        }

        h1 {
          color: #333;
          border-bottom: 2px solid #ddd;
          padding-bottom: 5px;
        }

        h2 {
          color: #666;
          margin-top: 20px;
        }

        h3 {
          color: #888;
          margin-top: 15px;
        }

        .scenario {
          padding-left: 20px;
        }

        .step.pass {
          color: green;
          font-weight: bold;
        }

        .step.fail {
          color: red;
          font-weight: bold;
        }

        .step.not_reached {
          color: gray;
          font-style: italic;
        }

        .feature-container {
          margin-bottom: 30px;
        }

        ul {
          list-style-type: none;
          padding-left: 0;
        }

        li {
          margin-bottom: 8px;
        }

        .step-container {
          margin-left: 30px;
        }
      </style>
    </head>
    <body>
      <h1>Test Report</h1>

      #{Enum.map_join(features, "\n", &format_feature/1)}

    </body>
    </html>
    """

    File.mkdir("cover")
    File.write!("cover/criterion.html", html_content)
  end

  defp format_feature({feature_name, scenarios}) do
    """
    <div class="feature-container">
      <h2>Feature: #{feature_name}</h2>
      #{Enum.map_join(scenarios, "\n", &format_scenario/1)}
    </div>
    """
  end

  defp format_scenario({scenario_name, steps}) do
    """
    <div class="scenario">
      <h3>Scenario: #{scenario_name}</h3>
      <ul class="step-container">
        #{Enum.map_join(steps, "\n", &format_step/1)}
      </ul>
    </div>
    """
  end

  defp format_step({description, status}) do
    step_class =
      case status do
        :passed -> "pass"
        :failed -> "fail"
        :not_reached -> "not_reached"
      end

    "<li class=\"step #{step_class}\">#{description}</li>"
  end
end
