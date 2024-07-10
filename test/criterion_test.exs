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

    scenario "Divide" do
      step("Given a number", SharedSteps)

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
