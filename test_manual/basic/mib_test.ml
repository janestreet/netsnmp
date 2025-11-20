open! Core
open Netsnmp_raw_monad

let add_mib_paths paths =
  paths
  |> List.iter ~f:(fun path ->
    let num = Mib.add_mibdir path in
    printf "mibs(%s) = %d\n" path num)
;;

let oid_module oidstr =
  let re = Re.(compile (rep1 (char ':'))) in
  match Re.split re oidstr with
  | oidm :: _ :: _ -> Some oidm
  | _ -> None
;;

let get_oid f oidstr errmsg =
  try Some (f oidstr) with
  | Netsnmp_exceptions.Not_found err ->
    eprintf "%s failed (%s): %s\n" errmsg oidstr err;
    None
;;

let display_oid oidstr =
  printf "\n--- OID: %s ---\n" oidstr;
  let oid =
    match oid_module oidstr with
    | Some oidm ->
      (try
         Mib.netsnmp_read_module oidm;
         get_oid Mib.read_objid oidstr "read_objid"
       with
       | Netsnmp_exceptions.Not_found err ->
         eprintf "Module not found: %s (%s)\n" oidm err;
         None)
    | None -> get_oid Mib.get_node oidstr "get_node"
  in
  match oid with
  | Some oid ->
    printf "%s objid_len = %d\n" oidstr (Netsnmp_raw.Oid.length oid);
    print_string "fprint_objid:";
    Mib.fprint_objid ~fd:1 oid;
    let str = Mib.snprint_objid oid in
    printf "snprint_objid:%s\n" str;
    let str = Mib.snprint_description oid in
    printf "snprint_description:\n%s\n" str
  | None -> eprintf "%s not found\n" oidstr
;;

let run save_descr mib_paths oids =
  if save_descr then Mib.snmp_set_save_descriptions true;
  Mib.netsnmp_init_mib ();
  add_mib_paths mib_paths;
  let oids = [ "sysDescr.0"; "SNMPv2-MIB::sysDescr.0" ] @ oids in
  List.iter ~f:display_oid oids
;;

let () =
  Command.basic
    ~summary:"test mib access"
    (let%map_open.Command save_descr =
       flag "-save-descr" no_arg ~doc:" set mib save_description"
     and mib_paths =
       flag "-mib-path" (listed string) ~doc:"PATH directory to search for mibs"
     and oids = anon (sequence ("oid" %: string)) in
     fun () -> run save_descr mib_paths oids)
  |> Command_unix.run
;;
