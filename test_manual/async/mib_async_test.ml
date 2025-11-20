open! Core
open Async
open Netsnmp_async

let mibdirs paths =
  Deferred.List.iter ~how:`Sequential paths ~f:(fun p ->
    let%map num = Raw.Mib.add_mibdir p in
    printf "mibs(%s) = %d\n%!" p num)
;;

let test paths save_descr =
  let%bind () =
    if save_descr then Raw.Mib.snmp_set_save_descriptions true else Deferred.unit
  in
  let%bind () = Raw.Mib.netsnmp_init_mib () in
  mibdirs paths
;;

let () =
  Command.async
    ~summary:"test mib access"
    ~behave_nicely_in_pipeline:false
    (let%map_open.Command path =
       flag "-mib-path" (listed string) ~doc:"PATH location of additional mib files"
     and save_descr = flag "-save-descr" no_arg ~doc:" include MIB descriptions" in
     fun () -> test path save_descr)
  |> Command_unix.run
;;
