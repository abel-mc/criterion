defmodule CriterionTest do
  use ExUnit.Case
  import Criterion
  alias Criterion.SharedSteps

  feature "Math" do
    setup do
      {:ok, pi: 2.7}
    end

    scenario "Square" do
      step("Given a number", from: SharedSteps, where: [min: 100])

      step "When the number is multiplied by it self", %{number: number} do
        result = number * number
        %{result: result}
      end

      step "Then the result is greater than the number", %{result: result, number: number, pi: pi} do
        assert pi == 2.7
        assert result > number
      end
    end

    scenario "Divide" do
      step("Given a number", from: SharedSteps)

      step "When the number divided by it self", %{number: number} do
        result = number / number
        %{result: result}
      end

      step "Then the result is 1", %{result: result} do
        assert result == 1
      end
    end
  end
end
