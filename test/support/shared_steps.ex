defmodule Criterion.SharedSteps do
  import Criterion

  step "Given a number", _context do
    %{number: :rand.uniform(100)}
  end
end
