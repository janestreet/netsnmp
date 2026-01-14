open! Core
open Netsnmp

let run hostname version_auth =
  Netsnmp.Raw.Session.netsnmp_init ();
  let cinfo =
    { Netsnmp.Connection_info.version_auth
    ; peername = hostname
    ; localname = None
    ; local_port = None
    ; retries = None
    ; timeout = None
    }
  in
  let () = Netsnmp.add_mib_paths [ "." ] in
  let conn = Netsnmp.Connection.connect cinfo in
  let result =
    Netsnmp.get_s
      conn
      [ "sysDescr.0"
      ; "sysDescr.1"
      ; "tcpRtoAlgorithm.0"
      ; "SNMPv2-MIB::sysORID.1"
      ; "SNMPv2-SMI::enterprises.21239.5.2.1.1.0"
      ]
  in
  print_endline "start list";
  result
  |> List.iter ~f:(fun (oid, value) ->
    printf
      "snmp_sess_synch_response: %s -> [%s(%s)]\n"
      (Netsnmp.Mib.snprint_objid oid)
      (Netsnmp.ASN1_value.type_to_string value)
      (Netsnmp.ASN1_value.to_string value));
  print_endline "end list";
  Netsnmp.Connection.close conn
;;

let () =
  Command.basic
    ~summary:"test netsnmp connection"
    (let%map_open.Command { Netsnmp_test_common.Snmp_connection_params.hostname
                          ; version_auth
                          }
       =
       Netsnmp_test_common.Snmp_connection_params.param
     in
     fun () -> run hostname version_auth)
  |> Command_unix.run
;;
