defmodule Criterion.SharedSteps do
  import Criterion

  defstep "Given a number", _context, args do
    min = args[:min] || 0
    %{number: min + Enum.random(0..100)}
  end
end
