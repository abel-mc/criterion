# Criterion

A library to write ExUnit tests BDD style

## Installation

The package can be installed
by adding `criterion` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:criterion, "~> 0.1", only: [:test, :dev]}
  ]
end
```

## Usage

- Define a feature using `feature/2` macro
- Define scenarios under the feature using the `scenario/2` macro.
- Inside each scenario, define steps using `step/2` block.
- Steps can have either inline or external implementation.
- External implementations can be reused and can be defined using `defstep/2` macro.

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

### Generating feature files

```
mix criterion.gen.features
```

#### Options

- `--dir` - specify the directory to read test files from. default is `test`
- `--file` - to generate feature files for a list of test files
- `--output` - specify the directory to generate feature files in. default is `test/features`
  `test/features/Math.feature`

```feature
Feature: Math

  Scenario: Square
    Given a number greater than 1
    When the number is multiplied by it self
    Then the result is greater than the number
    And pi is a constant
```

### Generating test files

```
mix criterion.gen.tests
```

#### Options

- `--dir` - specify the directory to read feature files from. default is `test/features`
- `--file` - to generate test for a list of files
- `--output` - specify the directory to generate the test files in. default is `test/features`

`test/features/math_test.exs`

```elixir
defmodule MathTest do
  use ExUnit.Case
  import Criterion

  feature "Math" do
    scenario "Square" do
      step "Given a number greater than 1" do
      end

      step "When the number is multiplied by it self" do
      end

      step "Then the result is greater than the number" do
      end

      step "And pi is a constant" do
      end
    end
  end
end
```
