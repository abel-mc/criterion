defmodule Criterion.SharedSteps do
  import Criterion

  defstep "Given a number", _context, args do
    min = args[:min] || 0
    %{number: min + :rand.uniform(100)}
  end
end
