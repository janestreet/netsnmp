open! Core
open Netsnmp_raw_monad

let run hostname version_auth =
  let add_oid oids pdu = Mib.get_node oids |> Pdu.snmp_add_null_var pdu in
  Session.netsnmp_init ();
  let cinfo =
    Netsnmp.Netsnmp_types.Connection_info.create
      ~version_auth
      ~retries:Netsnmp_test_common.Session_defaults.retries
      ~timeout:Netsnmp_test_common.Session_defaults.timeout_usec
      ~peername:hostname
      ~localname:""
      ~local_port:0
      ()
  in
  let sess =
    Netsnmp_test_common.open_session_from_connection_info_with
      ~snmp_sess_open:Session.snmp_sess_open
      cinfo
  in
  Mib.netsnmp_init_mib ();
  let pdu =
    Pdu.snmp_pdu_create Pdu.Pdu_type.Get
    |> add_oid "sysDescr.0"
    |> add_oid "sysDescr.1"
    |> add_oid "SNMPv2-SMI::enterprises.21239.5.2.1.1.0"
    |> add_oid "tcpRtoAlgorithm.0"
    |> add_oid "SNMPv2-MIB::sysORID.1"
  in
  print_endline "start list";
  Session.snmp_sess_synch_response sess pdu
  |> List.iter ~f:(fun (oid, value) ->
    printf
      "snmp_sess_synch_response: %s -> [%s(%s)]\n"
      (Mib.snprint_objid oid)
      (Netsnmp_raw.ASN1_value.type_to_string value)
      (Netsnmp_raw.ASN1_value.to_string value));
  print_endline "end list"
;;

let () =
  Command.basic
    ~summary:"test session access"
    (let%map_open.Command { Netsnmp_test_common.Snmp_connection_params.hostname
                          ; version_auth
                          }
       =
       Netsnmp_test_common.Snmp_connection_params.param
     in
     fun () -> run hostname version_auth)
  |> Command_unix.run
;;
