defmodule CloudfrontSigner.Policy do
  @moduledoc """
  Defines a cloudfront signature policy, and a string coercion method for it
  """
  defstruct [:resource, :expiry]

  @type t :: %__MODULE__{}

  def generate_signature_and_policy(%__MODULE__{} = policy, private_key) do
    policy_as_str =
      aws_policy(policy.resource, policy.expiry)
      |> Jason.encode!()

    signature =
      policy_as_str
      |> String.replace(~r/\s+/, "")
      |> :public_key.sign(:sha, private_key)
      |> Base.encode64()
      |> String.replace(["+", "=", "/"], fn
        "+" -> "-"
        "=" -> "_"
        "/" -> "~"
      end)

    {signature, Base.encode64(policy_as_str)}
  end

  defp aws_policy(resource, expiry) do
    %{
      "Statement" => [
        %{
          "Resource" => resource,
          "Condition" => %{
            "DateLessThan" => %{
              "AWS:EpochTime" => expiry
            }
          }
        }
      ]
    }
  end
end
