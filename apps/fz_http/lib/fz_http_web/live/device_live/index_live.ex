defmodule FzHttpWeb.DeviceLive.Index do
  @moduledoc """
  Handles Device LiveViews.
  """
  use FzHttpWeb, :live_view

  alias FzHttp.Devices

  def mount(params, session, socket) do
    {:ok,
     socket
     |> assign_defaults(params, session, &load_data/2)
     |> assign(:page_title, "Devices")}
  end

  def handle_event("create_device", _params, socket) do
    # XXX: Remove device from WireGuard if create isn't successful
    {:ok, privkey, pubkey, server_pubkey} = @events_module.create_device()

    device_attrs = %{
      private_key: privkey,
      public_key: pubkey,
      server_public_key: server_pubkey
    }

    attributes =
      Map.merge(
        %{
          user_id: socket.assigns.current_user.id,
          name: Devices.rand_name()
        },
        device_attrs
      )

    case Devices.create_device(attributes) do
      {:ok, device} ->
        @events_module.device_created(
          device.public_key,
          "10.3.2.#{device.octet_sequence}"
        )

        {:noreply,
         socket
         |> put_flash(:info, "Device added successfully.")
         |> redirect(to: Routes.device_show_path(socket, :show, device))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error creating device.")}
    end
  end

  defp load_data(_params, socket) do
    assign(socket, :devices, Devices.list_devices(socket.assigns.current_user.id))
  end
end
