type 'a t = 'a

let return v = v
let bind a ~f = f a
let map a ~f = f a
let ( >>= ) a f = f a
let ( >>| ) a f = f a
let wrap_main_thread f = f
let wrap_new_thread f a = f a |> Io_intf.With_thread_id.result
let wrap ~thread_id:_ f = f
let wrap_mt f = f
let gc_finalise f t = Gc.finalise (fun t -> f t |> ignore) t
