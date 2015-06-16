require 'eventmachine'

module ApnsServer
  def post_init
    puts "#{Time.now} post_init"
    start_tls #:private_key_file => './server.key', :cert_chain_file => './server.crt', :verify_peer => false
  end

  def receive_data(data)
    #[1, identifier, expiry, 32, push_id, payload.bytesize, payload].pack('cNNnH*na*')
    (_, identifier, _, _, push_id, _, payload) = data.unpack('cNNnH64na*')
    puts "[#{identifier.to_s.rjust(5)}] push_id: #{push_id}"

    unless @resp
      invalid_push_ids = payload.scan(/er:([\d,]+)/)[0][0].split(',') rescue nil
      if invalid_push_ids
        #puts "inv pids: #{invalid_push_ids.inspect}" if !invalid_push_ids.empty?
        inv_push_id = push_id.scan(/^(#{invalid_push_ids.join('a|')}a)/)
        if !inv_push_id.empty?
          puts "\e[34m[#{identifier.to_s.rjust(5)}] push_id:\e[0m #{push_id} | #{inv_push_id} | #{invalid_push_ids.inspect}"
          @resp = true
          close #_connection
          #EM.next_tick { resp(identifier) }
        end
      end
    end
  end

  def resp(id)
    puts "\e[31msend\e[0m [8, 8, #{id}]"
    send_data([8,8,id].pack('ccN'))
  end

  def unbind
    puts "#{Time.now} \e[31mclient disconnect\e[0m"
  end
end

EventMachine.run {
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server "95.85.46.204", 2195, ApnsServer
}
