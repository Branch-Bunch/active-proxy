defmodule ActiveProxy.Proxy do
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
      Task.Supervisor.start_child(ExTcp.TaskSupervisor, fn ->
        serve(socket)
      end)

    :ok = :gen_tcp.controlling_process(socket, pid)
  end

  defp serve(socket) do
    packet = read(socket)
    # TODO: Forward packets
    write(socket, "echoing: #{packet}")

    serve(socket)
  end

  defp read(socket) do
    {:ok, packet} = :gen_tcp.recv(socket, 0)
    packet
  end

  defp write(socket, packet) do
    :ok = :gen_tcp.send(socket, packet)
  end
end
