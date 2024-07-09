defmodule Mix.Tasks.Criterion.Gen.Features do
  use Mix.Task

  @shortdoc "Generates Gherkin feature files from Criterion tests"

  @moduledoc """
  This Mix task scans the project for tests written using the `Criterion` module and generates
  corresponding feature files in *Gherkin* syntax.

  ## Usage

  ```
  mix criterion.gen.features --dir <directory>
  ```

  ### Options

  - `--output` - specify the directory to generate feature files in. default is `test/features`

  The task will create the specified directory (default is `features`) and generate a `.feature` file for each test file
  in your project, converting the Criterion tests into Gherkin syntax.
  """

  @switches [output: :string]

  def run(args) do
    Mix.Task.run("app.start")

    {opts, _} = OptionParser.parse!(args, switches: @switches)

    # Define the directory where the feature files will be saved
    feature_dir = opts[:output] || "test/features"
    File.mkdir_p!(feature_dir)

    # Get all test files in the project
    test_files = Path.wildcard("test/**/*_test.exs")

    Enum.each(test_files, fn file ->
      generate_feature_file(file, feature_dir)
    end)
  end

  defp generate_feature_file(file, feature_dir) do
    file
    |> File.read!()
    |> Code.string_to_quoted!()
    |> extract_features()
    |> Enum.each(fn {feature_name, scenarios} ->
      camel_case_name = to_camel_case(feature_name)
      feature_file = Path.join(feature_dir, "#{camel_case_name}.feature")
      File.write!(feature_file, format_feature(feature_name, scenarios))
    end)
  end

  defp extract_features({:defmodule, _, [_, [do: {:__block__, _, body}]]}) do
    Enum.flat_map(body, fn
      {:feature, _, [description, [do: {:__block__, _, scenarios}]]} ->
        [{description, extract_scenarios(scenarios)}]

      {:feature, _, [description, [do: scenario]]} ->
        [{description, extract_scenarios([scenario])}]

      _ ->
        []
    end)
  end

  defp extract_scenarios(scenarios) do
    Enum.map(scenarios, fn
      {:scenario, _, [description, [do: {:__block__, _, steps}]]} ->
        {description, extract_steps(steps)}

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp extract_steps(steps) do
    Enum.map(steps, fn
      {:step, _, [description, [do: _]]} ->
        {:step, description}

      {:step, _, [description, _context, [do: _]]} ->
        {:step, description}

      {:step, _, [description]} ->
        {:step, description}

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp format_feature(feature_name, scenarios) do
    """
    Feature: #{String.capitalize(feature_name)}

    #{Enum.map_join(scenarios, "\n", &format_scenario/1)}
    """
  end

  defp format_scenario({scenario_name, steps}) do
    """
    \tScenario: #{String.capitalize(scenario_name)}
    #{Enum.map_join(steps, "\n", &format_step/1)}
    """
  end

  defp format_step({:step, description}) do
    "\t\t#{String.capitalize(description)}"
  end

  defp to_camel_case(string) do
    string
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("")
  end
end
