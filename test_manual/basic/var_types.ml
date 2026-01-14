open! Core
open Netsnmp_raw_monad

let add_var oids pdu =
  let oid = Mib.read_objid oids in
  Pdu.snmp_add_null_var pdu oid
;;

let run hostname version_auth =
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
  let oid = Mib.get_node "sysDescr.0" in
  let pdu = Pdu.snmp_pdu_create Pdu.Pdu_type.Get in
  let pdu =
    Pdu.snmp_add_null_var pdu oid
    |> add_var "SNMPv2-SMI::enterprises.21239.5.2.1.1.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.1.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.2.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.3.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.4.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.5.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.6.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.7.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.8.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.9.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.10.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.11.0"
    (*=These are no longer supported on the client side
    |> add_var ".1.3.6.1.4.1.8072.2.99.12.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.13.0"
    *)
    |> add_var ".1.3.6.1.4.1.8072.2.99.14.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.15.0"
    |> add_var ".1.3.6.1.4.1.8072.2.99.16.0"
  in
  print_endline "start list";
  printf "sysDescr.0 objid_len = %d\n" (Netsnmp_raw.Oid.length oid);
  Session.snmp_sess_synch_response sess pdu
  |> List.iter ~f:(fun (oid, value) ->
    printf
      "snmp_sess_synch_response: %s -> [%s(%s)]\n"
      (Mib.snprint_objid oid)
      (Netsnmp_raw.ASN1_value.type_to_string value)
      (Netsnmp_raw.ASN1_value.to_string value));
  print_endline "end list";
  let pdu = Pdu.snmp_pdu_create Pdu.Pdu_type.Get in
  let (_ : Pdu.t) = add_var ".1.3.6.1.4.1.8072.2.99.4.0" pdu in
  Session.snmp_sess_synch_response sess pdu
  |> List.iter ~f:(fun (_oid, value) ->
    match value with
    | Netsnmp_raw.ASN1_value.ASN_Counter64 count ->
      printf "Counter64: %08x,%08x\n" count.high count.low
    | _ -> eprintf "Unexpected type: %s\n" (Netsnmp_raw.ASN1_value.type_to_string value))
;;

let () =
  Command.basic
    ~summary:"test variable types"
    (let%map_open.Command { Netsnmp_test_common.Snmp_connection_params.hostname
                          ; version_auth
                          }
       =
       Netsnmp_test_common.Snmp_connection_params.param
     in
     fun () -> run hostname version_auth)
  |> Command_unix.run
;;
