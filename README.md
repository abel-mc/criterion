# Criterion

A library to write ExUnit tests BDD style

## Installation

The package can be installed
by adding `criterion` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:criterion, "~> 0.1.0", only: [:test]}
  ]
end
```

## Usage

### Shared steps

```elixir
defmodule Criterion.SharedSteps do
  import Criterion

  step "Given a number", _context do
    %{number: :rand.uniform(100)}
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
      step("Given a number", SharedSteps)

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
- `--output` - specify the directory to generate the test files in. default is `test`
