defmodule CriterionTest do
  use ExUnit.Case
  import Criterion
  alias Criterion.SharedSteps

  feature "Math" do
    setup do
      {:ok, pi: 2.7}
    end

    scenario "Square" do
      step("Given a number greater than 1",
        from: SharedSteps,
        via: "Given a number",
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
        assert pi == 2.7
      end
    end

    scenario "Divide" do
      step("Given a number greater than 0",
        from: SharedSteps,
        via: "Given a number",
        where: [min: 1]
      )

      step "When the number divided by it self", %{number: number} do
        result = number / number
        %{result: result}
      end

      step "Then the result is 1", %{result: result} do
        assert result == 1
      end

      step "And pi is a constant", %{pi: pi} do
        assert pi == 2.7
      end
    end
  end
end
