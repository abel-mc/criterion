defmodule Mix.Tasks.Criterion.Gen.Tests do
  use Mix.Task

  @shortdoc "Generates Criterion tests from Gherkin feature files"

  @moduledoc """
  This Mix task reads Gherkin feature files and generates corresponding test files using the Criterion module.

  ## Usage

  ```
  mix criterion.gen.tests
  ```

  ### Options

  - `--dir` - specify the directory to read feature files from. default is `test/features`
  - `--file` - to generate test for a list of files
  - `--output` - specify the directory to generate the test files in. default is `test/features`
  """

  @switches [dir: :string, file: :keep, output: :string]
  def run(args) do
    {opts, _} = OptionParser.parse!(args, switches: @switches)

    feature_dir = opts[:dir] || "test/features"
    output_dir = opts[:output] || "test/features"
    feature_files = Keyword.get_values(opts, :file)

    feature_files =
      if length(feature_files) > 0 do
        feature_files
      else
        Path.wildcard("#{feature_dir}/**/*.feature")
      end

    Mix.Task.run("app.start")

    Enum.each(feature_files, fn file -> generate_test_file(file, output_dir) end)
  end

  defp generate_test_file(file, output_dir) do
    file
    |> File.read!()
    |> parse_feature_file()
    |> Enum.each(fn {feature_name, scenarios} ->
      test_file = Path.join(output_dir, "#{to_snake_case(feature_name)}_test.exs")
      test_content = format_test_file(feature_name, scenarios)
      File.write(test_file, test_content)
    end)
  end

  defp parse_feature_file(content) do
    [feature_line | scenario_lines] = String.split(content, "\n", trim: true)
    feature_name = String.trim_leading(feature_line, "Feature: ")

    scenarios =
      Enum.chunk_by(scenario_lines, &String.starts_with?(&1, "Scenario: "))
      |> Enum.map(fn [scenario_line | step_lines] ->
        scenario_name = String.trim_leading(scenario_line, "Scenario: ")
        steps = Enum.map(step_lines, &String.trim(&1))
        {scenario_name, steps}
      end)

    [{feature_name, scenarios}]
  end

  defp format_test_file(feature_name, scenarios) do
    """
    defmodule #{to_camel_case(feature_name)}Test do
    \tuse ExUnit.Case
    \timport Criterion

    \tfeature "#{feature_name}" do
    #{scenarios |> Enum.map_join("\n", &format_scenario/1) |> String.trim_trailing()}
    \tend
    end
    """
  end

  defp format_scenario({scenario_name, steps}) do
    """
    \t\tscenario "#{scenario_name}" do
    #{steps |> Enum.map_join("\n", &format_step/1) |> String.trim_trailing()}
    \t\tend
    """
  end

  defp format_step(step) do
    """
    \t\t\tstep \"#{step}\" do
    \t\t\tend
    """
  end

  defp to_camel_case(string) do
    string
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("")
  end

  defp to_snake_case(string) do
    string
    |> String.split()
    |> Enum.map(&String.downcase/1)
    |> Enum.join("_")
  end
end
