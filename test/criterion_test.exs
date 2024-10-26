defmodule CriterionTest do
  use ExUnit.Case
  import Criterion

  feature "Math" do
    setup do
      {:ok, pi: 3.14}
    end

    scenario "Square" do
      step("Given a number greater than 1",
        via: &random_number/2,
        where: [min: 2]
      )

      step "When the number is multiplied by it self", %{number: number} do
        result = number * number
        %{result: result}
      end

      step "Then the result is greater than the number", %{result: result, number: number} do
        assert result > number
      end

      step "And pi is a constant", %{pi: pi} do
        assert pi == 3.14
      end
    end

    defstep random_number(_context, args) do
      min = args[:min] || 0
      %{number: min + Enum.random(0..100)}
    end
  end
end
