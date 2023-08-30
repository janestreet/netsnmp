type open_netsnmp_session

type t =
  { session : open_netsnmp_session
  ; session_id : int
  }
[@@deriving fields ~getters]

module Snmp_version = struct
  type t =
    | Version_1
    | Version_2c
    | Version_3
end

module Snmp_sec_auth_proto = struct
  type t =
    | Ignore
    | UsmHMACMD5AuthProtocol
end

type snmp_session =
  { version : Snmp_version.t
  ; retries : int
  ; timeout : int
  ; peername : string
  ; localname : string
  ; local_port : int
  ; community : string
  ; securityName : string
  ; securityAuthProto : Snmp_sec_auth_proto.t
  ; securityAuthPassword : string
  }

external snmp_sess_open_c : snmp_session -> open_netsnmp_session = "caml_snmp_sess_open"
external snmp_sess_close_c : open_netsnmp_session -> unit = "caml_snmp_sess_close"

external snmp_sess_synch_response_c
  :  open_netsnmp_session
  -> Pdu.t
  -> (Oid.t * ASN1_value.t) list
  = "caml_snmp_sess_synch_response"

let next_session_id =
  let next_session_id = ref Int.min_int in
  fun () ->
    if !next_session_id = Int.max_int
    then raise (Failure "Ran out of session ids")
    else (
      let ret = !next_session_id in
      incr next_session_id;
      ret)
;;

let snmp_sess_open
  ~version
  ~retries
  ~timeout
  ~peername
  ~localname
  ~local_port
  ~community
  ~securityName
  ~securityAuthProto
  ~securityAuthPassword
  ()
  =
  let snmp_session =
    { version
    ; retries
    ; timeout
    ; peername
    ; localname
    ; local_port
    ; community
    ; securityName
    ; securityAuthProto
    ; securityAuthPassword
    }
  in
  let session = snmp_sess_open_c snmp_session in
  { session; session_id = next_session_id () }
;;

let snmp_sess_close t = snmp_sess_close_c t.session
let snmp_sess_synch_response t pdu = snmp_sess_synch_response_c t.session pdu |> List.rev
