open! Import

module Session (IO : Io_intf.S) : Session_intf.S with module IO := IO = struct
  include Session

  (** [snmp_sess_open] and [snmp_sess_close] may be called from a thread, but must be
      called from the same thread for some session. [snmp_sess_synch_response] is
      threadsafe. *)

  let snmp_sess_open
    ~version
    ~retries
    ~timeout
    ~peername
    ~localname
    ~local_port
    ~community
    ~securityName
    ~securityLevel
    ~securityAuthProto
    ~securityAuthPassword
    ()
    =
    IO.wrap_new_thread
      (fun () ->
        let result =
          Session.snmp_sess_open
            ~version
            ~retries
            ~timeout
            ~peername
            ~localname
            ~local_port
            ~community
            ~securityName
            ~securityLevel
            ~securityAuthProto
            ~securityAuthPassword
            ()
        in
        Io_intf.With_thread_id.create ~result ~thread_id:(Session.session_id result))
      ()
  ;;

  let snmp_sess_close session =
    IO.wrap ~thread_id:(Session.session_id session) Session.snmp_sess_close session
  ;;

  let snmp_sess_synch_response handle pdu =
    IO.wrap_mt (Session.snmp_sess_synch_response handle) pdu
  ;;
end
