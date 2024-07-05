defmodule Exepted.ScenarioTest do
  use ExUnit.Case
  import Exepted.Scenario

  scenario "Acceptance" do
    step "Given a", context do
      a = 1 + 1
      Map.put(context, :a, a)
    end

    step "When b", context do
      b = context[:a] + 2
      Map.put(context, :b, b)
    end

    step "Then c", context do
      c = context[:b] + 2
      assert c == 9
      Map.put(context, :c, c)
    end
  end
end
