# Criterion

A library to write ExUnit tests BDD style

## Installation

The package can be installed
by adding `criterion` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:criterion, "~> 0.1.0", only: [:test, :dev]}
  ]
end
```

## Usage

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

### Generating feature files

```
mix criterion.gen.features
```

#### Options

- `--dir` - specify the directory to read test files from. default is `test`
- `--file` - to generate feature files for a list of test files
- `--output` - specify the directory to generate feature files in. default is `test/features`

### Generating test files

```
mix criterion.gen.tests
```

#### Options

- `--dir` - specify the directory to read feature files from. default is `test/features`
- `--file` - to generate test for a list of files
- `--output` - specify the directory to generate the test files in. default is `test/features`
