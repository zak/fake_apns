require 'eventmachine'

module ApnsServer
  def post_init
    puts "#{Time.now} post_init"
    start_tls #:private_key_file => './server.key', :cert_chain_file => './server.crt', :verify_peer => false
  end

  def receive_data(data)
    #puts "#{Time.now} \e[32mreceive_data\e[0m: #{data.unpack('cNNnH64na*')}"
  end

  def unbind
    puts "#{Time.now} \e[31mclient disconnect\e[0m"
  end
end

EventMachine.run {
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server "0.0.0.0", 1337, ApnsServer
}
