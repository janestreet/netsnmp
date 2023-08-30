module With_thread_id = struct
  type 'result t =
    { result : 'result
    ; thread_id : int
    }
  [@@deriving fields ~iterators:create]

  let create = Fields.create
end

module type S = sig
  type 'a t

  val wrap_main_thread : ('a -> 'b) -> 'a -> 'b t
  val wrap_new_thread : ('a -> 'b With_thread_id.t) -> 'a -> 'b t
  val wrap : thread_id:int -> ('a -> 'b) -> 'a -> 'b t
  val wrap_mt : ('a -> 'b) -> 'a -> 'b t
  val bind : 'a t -> f:('a -> 'b t) -> 'b t
  val map : 'a t -> f:('a -> 'b) -> 'b t
  val return : 'a -> 'a t
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val ( >>| ) : 'a t -> ('a -> 'b) -> 'b t
  val gc_finalise : ('a -> unit t) -> 'a -> unit
end
