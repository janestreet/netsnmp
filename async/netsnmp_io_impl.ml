open! Core
open! Async

type 'a t = 'a Deferred.t

let return = Deferred.return
let bind = Deferred.bind
let map = Deferred.map
let ( >>= ) = Deferred.( >>= )
let ( >>| ) = Deferred.( >>| )
let wrap_main_thread f v = Deferred.return (f v)

let num_threads =
  let max_num_threads = Async_config.(Max_num_threads.raw max_num_threads) in
  if max_num_threads <= 1
  then raise_s [%message "Async max_num_threads too low; must be > 1"]
  else (
    let float_num_threads =
      Float.of_int Async_config.(Max_num_threads.raw max_num_threads)
    in
    let ten_percent = 0.1 *. float_num_threads in
    Float.to_int ten_percent)
;;

let next_thread =
  Lazy_deferred.create (fun () ->
    Deferred.Array.init ~how:`Sequential num_threads ~f:(fun i ->
      In_thread.Helper_thread.create ~name:(sprintf "netsnmp thread %i" i) ())
    >>| fun threads ->
    let next_thread = ref 0 in
    fun () ->
      let ret = threads.(!next_thread) in
      next_thread := (!next_thread + 1) % num_threads;
      ret)
;;

let thread_table : In_thread.Helper_thread.t Int.Table.t = Int.Table.create ()

let wrap_new_thread f v =
  Lazy_deferred.force_exn next_thread
  >>= fun next_thread ->
  let thread = next_thread () in
  In_thread.run ~thread (fun () -> f v)
  >>| fun result_with_thread_id ->
  let thread_id =
    Netsnmp_raw_monad.Io_intf.With_thread_id.thread_id result_with_thread_id
  in
  Hashtbl.add_exn thread_table ~key:thread_id ~data:thread;
  Netsnmp_raw_monad.Io_intf.With_thread_id.result result_with_thread_id
;;

let wrap ~thread_id f v =
  let thread = Hashtbl.find_exn thread_table thread_id in
  In_thread.run ~thread (fun () -> f v)
;;

let wrap_mt f v = In_thread.run (fun () -> f v)
let gc_finalise f t = Gc.add_finalizer_exn t (fun t -> f t |> don't_wait_for)
