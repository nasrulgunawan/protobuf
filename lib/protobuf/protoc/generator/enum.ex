defmodule Protobuf.Protoc.Generator.Enum do
  @moduledoc false

  alias Protobuf.Protoc.Context
  alias Protobuf.Protoc.Generator.Util

  require EEx

  EEx.function_from_file(
    :defp,
    :enum_template,
    Path.expand("./templates/enum.ex.eex", :code.priv_dir(:protobuf)),
    [:name, :use_options, :fields, :descriptor_fun_body],
    trim: true
  )

  @spec generate_list(Context.t(), [Google.Protobuf.EnumDescriptorProto.t()]) :: [String.t()]
  def generate_list(%Context{} = ctx, descs) when is_list(descs) do
    Enum.map(descs, &generate(ctx, &1))
  end

  @spec generate(Context.t(), Google.Protobuf.EnumDescriptorProto.t()) :: String.t()
  def generate(%Context{namespace: ns} = ctx, %Google.Protobuf.EnumDescriptorProto{} = desc) do
    msg_name = Util.mod_name(ctx, ns ++ [Macro.camelize(desc.name)])
    use_options = Util.options_to_str(%{syntax: ctx.syntax, enum: true})

    descriptor_fun_body =
      if ctx.gen_descriptors? do
        descriptor_fun_body(desc)
      else
        nil
      end

    enum_template(msg_name, use_options, _fields = desc.value, descriptor_fun_body)
  end

  defp descriptor_fun_body(%mod{} = desc) do
    desc
    |> Map.from_struct()
    |> Enum.filter(fn {_key, val} -> not is_nil(val) end)
    |> mod.new()
    |> mod.encode()
    |> mod.decode()
    |> inspect(limit: :infinity)
  end
end
