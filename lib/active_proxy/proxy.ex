defmodule ActiveProxy.Proxy do
  require Logger

  def listen(port) do
    # `:binary` - receives data as binaries (instead of lists)
    # `packet: :line` - receives data line by line
    # `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # `reuseaddr: true` - allows us to reuse the address if the listener crashes
    {:ok, listen_socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting TCP connections on port: #{port}")
    accept(listen_socket)
  end

  defp accept(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    start_serve_process(socket)
    Logger.info("Accepted new connection")

    accept(listen_socket)
  end

  defp start_serve_process(socket) do
    timeout = Application.get_env(:active_proxy, :timeout)
    application_address = Application.get_env(:active_proxy, :node1_address)
    Logger.info("Forwarding to application at #{application_address} with timout of #{timeout}ms")

    {:ok, pid} =
      Task.Supervisor.start_child(ActiveProxy.TaskSupervisor, fn ->
        # TODO: make the host configurable
        {:ok, upstream_socket} =
          :gen_tcp.connect(
            to_charlist(application_address),
            4000,
            [
              :binary,
              packet: :line,
              active: false,
              reuseaddr: true
            ],
            1000
          )

        serve(socket, upstream_socket, timeout)
      end)

    :ok = :gen_tcp.controlling_process(socket, pid)
  end

  defp serve(socket, upstream_socket, timeout) do
    read_from_client(socket, upstream_socket, timeout)
  end

  defp read_from_client(socket, upstream_socket, timeout) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, packet} ->
        packet |> forward_to_upstream(upstream_socket, socket, timeout)

      {:error, :closed} ->
        # In case of socket being closed exit serve loop
        nil

        # TODO: handle other types of read error to
    end
  end

  defp forward_to_upstream(packet, upstream_socket, socket, timeout) do
    # TODO: Handle failure to write to application
    write(packet, upstream_socket)

    case :gen_tcp.recv(upstream_socket, 0, timeout) do
      {:ok, packet} ->
        packet |> write_to_client(upstream_socket, socket, timeout)

      {:error, :timeout} ->
        # TODO: Consider failing over to different upstream node
        nil
    end
  end

  defp write_to_client(packet, upstream_socket, socket, timeout) do
    write(packet, socket)
    serve(socket, upstream_socket, timeout)
  end

  defp write(packet, socket) do
    :gen_tcp.send(socket, packet)
  end
end
