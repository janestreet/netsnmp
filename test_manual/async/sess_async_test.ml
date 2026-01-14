open! Core
open Async
open Netsnmp_async

let run hostname version_auth =
  let add_oid oids pdu = Mib.get_node oids >>= Raw.Pdu.snmp_add_null_var pdu in
  let%bind () = Mib.netsnmp_init_mib () in
  Raw.Session.netsnmp_init ();
  let cinfo =
    Netsnmp.Netsnmp_types.Connection_info.create
      ~version_auth
      ~peername:hostname
      ~retries:Netsnmp_test_common.Session_defaults.retries
      ~timeout:Netsnmp_test_common.Session_defaults.timeout_usec
      ~localname:""
      ~local_port:0
      ()
  in
  let%bind sess =
    Netsnmp_test_common.open_session_from_connection_info_with
      ~snmp_sess_open:Raw.Session.snmp_sess_open
      cinfo
  in
  let%bind pdu =
    Raw.Pdu.snmp_pdu_create Raw.Pdu.Pdu_type.Get
    >>= add_oid "sysDescr.0"
    >>= add_oid "sysDescr.1"
    >>= add_oid "tcpRtoAlgorithm.0"
    >>= add_oid "SNMPv2-MIB::sysORID.1"
  in
  print_endline "start list";
  let%bind () =
    Raw.Session.snmp_sess_synch_response sess pdu
    >>= Deferred.List.iter ~how:`Sequential ~f:(fun (oid, value) ->
      let%map oid_s = Mib.snprint_objid oid in
      printf
        "snmp_sess_synch_response: %s -> [%s(%s)]\n"
        oid_s
        (Netsnmp_raw.ASN1_value.type_to_string value)
        (Netsnmp_raw.ASN1_value.to_string value))
  in
  print_endline "end list";
  Deferred.unit
;;

let () =
  Command.async
    ~summary:"session access"
    ~behave_nicely_in_pipeline:false
    (let%map_open.Command { Netsnmp_test_common.Snmp_connection_params.hostname
                          ; version_auth
                          }
       =
       Netsnmp_test_common.Snmp_connection_params.param
     in
     fun () -> run hostname version_auth)
  |> Command_unix.run
;;
