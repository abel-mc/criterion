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

  - `--dir` - specify the directory to read test files from. default is `test`
  - `--file` - to generate feature files for a list of test files
  - `--output` - specify the directory to generate feature files in. default is `test/features`

  The task will create the specified directory (default is `features`) and generate a `.feature` file for each test file
  in your project, converting the Criterion tests into Gherkin syntax.
  """

  @switches [dir: :string, file: :keep, output: :string]

  def run(args) do
    Mix.Task.run("app.start")

    {opts, _} = OptionParser.parse!(args, switches: @switches)

    test_dir = opts[:dir] || "test"
    output_dir = opts[:output] || "test/features"
    test_files = Keyword.get_values(opts, :file)

    File.mkdir_p!(output_dir)

    test_files =
      if length(test_files) > 0 do
        test_files
      else
        Path.wildcard("#{test_dir}/**/*_test.exs")
      end

    Enum.each(test_files, fn file ->
      generate_feature_file(file, output_dir)
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

  defp extract_features(_), do: []

  defp extract_scenarios(scenarios) do
    Enum.map(scenarios, fn
      {:scenario, _, [description, [do: {:__block__, _, steps}]]} ->
        {description, extract_steps(steps)}

      {:scenario, _, [description, _context, [do: {:__block__, _, steps}]]} ->
        {description, extract_steps(steps)}

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp extract_steps(steps) do
    Enum.map(steps, fn
      {:step, _, [description | _other]} when is_binary(description) ->
        {:step, description}

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp format_feature(feature_name, scenarios) do
    """
    Feature: #{capitalize(feature_name)}

    #{Enum.map_join(scenarios, "\n", &format_scenario/1)}
    """
  end

  defp format_scenario({scenario_name, steps}) do
    """
    \tScenario: #{capitalize(scenario_name)}
    #{Enum.map_join(steps, "\n", &format_step/1)}
    """
  end

  defp format_step({:step, description}) do
    "\t\t#{capitalize(description)}"
  end

  defp to_camel_case(string) do
    string
    |> String.split()
    |> Enum.map(&capitalize/1)
    |> Enum.join("")
  end

  defp capitalize(string) do
    [h | t] = String.graphemes(string)
    Enum.join([String.capitalize(h) | t])
  end
end
