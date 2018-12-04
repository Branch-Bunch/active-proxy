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
    {:ok, pid} =
      Task.Supervisor.start_child(ActiveProxy.TaskSupervisor, fn ->
        # TODO: make the host configurable
        {:ok, upstream_socket} =
          :gen_tcp.connect(
            '159.203.44.11',
            4000,
            [
              :binary,
              packet: :line,
              active: false,
              reuseaddr: true
            ],
            1000
          )

        serve(socket, upstream_socket)
      end)

    :ok = :gen_tcp.controlling_process(socket, pid)
  end

  defp serve(socket, upstream_socket) do
    timeout = 10
    {ok, packet} = read(socket)

    if {ok, packet} == {:error, :closed} do
      # If reading from socket closed exit serve loop
      # TODO:
      # Should probably log error
      #
      #
      # Also handle other types of errors other than :closed
    else
      # TODO: Handle failure to write to application
      write(upstream_socket, packet)

      {status, payload} = read(upstream_socket, timeout)

      if status == :ok do
        write(socket, payload)
      end

      serve(socket, upstream_socket)
    end
  end

  defp read(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp read(socket, timeout) do
    case :gen_tcp.recv(socket, 0, timeout) do
      {:ok, packet} ->
        {:ok, packet}

      {:error, reason} ->
        # shutdown writes to signal that no more data is to be sent and wait for the read side of the socket to be closed
        :gen_tcp.shutdown(socket, :write)
        {:error, reason}
    end
  end

  defp write(socket, packet) do
    :gen_tcp.send(socket, packet)
  end
end
