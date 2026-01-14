open Netsnmp_raw_monad

let option_default ~default v =
  match v with
  | Some v -> v
  | None -> default
;;

module type IO = Io_intf.S

module Netsnmp (IO : IO) : Netsnmp_intf.S with module IO := IO = struct
  open IO
  module ASN1_value = ASN1_value
  include Netsnmp_types
  module Mib = Mib_monad.Mib (IO)
  module Session = Session_monad.Session (IO)
  module Pdu = Pdu_monad.Pdu (IO)

  let list_iter ~f l =
    let rec loop = function
      | [] -> return ()
      | hd :: tl -> f hd >>= fun () -> loop tl
    in
    loop l
  ;;

  let list_fold ~init ~f l =
    let rec loop a = function
      | [] -> return a
      | hd :: tl -> f a hd >>= fun a -> loop a tl
    in
    loop init l
  ;;

  module Oid = struct
    include Oid

    (** Track the mibs that have been loaded *)
    let loaded_mibs = ref []

    let initialised = ref None

    let check_init () =
      match !initialised with
      | Some io -> io
      | None ->
        let io = Mib.netsnmp_init_mib () in
        initialised := Some io;
        io
    ;;

    let oid_module =
      let re = Re.(compile (rep1 (char ':'))) in
      fun oidstr ->
        match Re.split re oidstr with
        | oidm :: _ :: _ -> Some oidm
        | _ -> None
    ;;

    let of_string oidstr =
      check_init ()
      >>= fun () ->
      match oid_module oidstr with
      | Some oidm ->
        (if not (List.exists (String.equal oidm) !loaded_mibs)
         then (
           Mib.netsnmp_read_module oidm
           >>= fun () ->
           loaded_mibs := oidm :: !loaded_mibs;
           return ())
         else return ())
        >>= fun () -> Mib.get_node oidstr
      | None -> Mib.get_node oidstr
    ;;

    let to_string oidval = check_init () >>= fun () -> Mib.snprint_objid oidval
  end

  module Connection = struct
    type t =
      { session : Netsnmp_raw.Session.t
      ; mutable closed : bool
      }

    let close sess =
      (if not sess.closed then Session.snmp_sess_close sess.session else return ())
      >>= fun () ->
      sess.closed <- true;
      return ()
    ;;

    let connect (cinfo : Connection_info.t) =
      Oid.check_init ()
      >>= fun () ->
      let retries = option_default ~default:3 cinfo.retries in
      let timeout = option_default ~default:3_000_000 cinfo.timeout in
      let peername = cinfo.peername in
      let localname = option_default ~default:"" cinfo.localname in
      let local_port = option_default ~default:0 cinfo.local_port in
      let ( version
          , `Community community
          , `Security_name securityName
          , securityLevel
          , securityAuthProto
          , `Security_auth_password securityAuthPassword )
        =
        match cinfo.version_auth with
        | Snmp_version_auth.Version_1 { community } ->
          ( Session.Snmp_version.Version_1
          , `Community community
          , `Security_name ""
          , Session.Snmp_security_level.NoAuthNoPriv
          , Session.Snmp_sec_auth_proto.Ignore
          , `Security_auth_password "" )
        | Version_2c { community } ->
          ( Session.Snmp_version.Version_2c
          , `Community community
          , `Security_name ""
          , Session.Snmp_security_level.NoAuthNoPriv
          , Session.Snmp_sec_auth_proto.Ignore
          , `Security_auth_password "" )
        | Version_3 { security_name; auth_protocol = Ignore } ->
          ( Session.Snmp_version.Version_3
          , `Community ""
          , `Security_name security_name
          , Session.Snmp_security_level.NoAuthNoPriv
          , Session.Snmp_sec_auth_proto.Ignore
          , `Security_auth_password "" )
        | Version_3 { security_name; auth_protocol = MD5 { password } } ->
          ( Session.Snmp_version.Version_3
          , `Community ""
          , `Security_name security_name
          , Session.Snmp_security_level.AuthNoPriv
          , Session.Snmp_sec_auth_proto.UsmHMACMD5AuthProtocol
          , `Security_auth_password password )
      in
      Session.snmp_sess_open
        ~version
        ~retries
        ~timeout
        ~peername
        ~localname
        ~local_port
        ~community
        ~securityName
        ~securityLevel
        ~securityAuthProto
        ~securityAuthPassword
        ()
      >>= fun session ->
      let t = { session; closed = false } in
      let () = IO.gc_finalise (fun t -> close t) t in
      return t
    ;;

    let with_connection cinfo ~f =
      connect cinfo
      >>= fun sess ->
      match f sess with
      | exception e -> close sess >>= fun () -> raise e
      | _ as res -> close sess >>= fun () -> return res
    ;;
  end

  let add_mibdir p =
    Oid.check_init ()
    >>= fun () ->
    Mib.add_mibdir p
    >>= function
    | i when i < 0 -> raise (Failure ("add_mibdir failed: " ^ p))
    | _ -> return ()
  ;;

  let add_mib_paths paths = list_iter ~f:add_mibdir paths

  let check_sess (sess : Connection.t) =
    match sess.closed with
    | true -> raise (Failure "session has been closed")
    | _ -> ()
  ;;

  let get_s (sess : Connection.t) oids =
    let () = check_sess sess in
    let add_oid oid pdu = Oid.of_string oid >>= Pdu.snmp_add_null_var pdu in
    Pdu.snmp_pdu_create Pdu.Pdu_type.Get
    >>= fun pdu ->
    list_fold ~init:pdu ~f:(fun pdu oid -> add_oid oid pdu) oids
    >>= fun pdu -> Session.snmp_sess_synch_response sess.session pdu
  ;;

  let get (sess : Connection.t) oids =
    let () = check_sess sess in
    let add_oid oid pdu = Pdu.snmp_add_null_var pdu oid in
    Pdu.snmp_pdu_create Pdu.Pdu_type.Get
    >>= fun pdu ->
    list_fold ~init:pdu ~f:(fun pdu oid -> add_oid oid pdu) oids
    >>= fun pdu -> Session.snmp_sess_synch_response sess.session pdu
  ;;

  let get_next (sess : Connection.t) oid =
    let () = check_sess sess in
    Pdu.snmp_pdu_create Pdu.Pdu_type.Getnext
    >>= fun pdu ->
    Pdu.snmp_add_null_var pdu oid
    >>= fun pdu -> Session.snmp_sess_synch_response sess.session pdu
  ;;

  module Raw = struct
    module Oid = Oid
    module Pdu = Pdu_monad.Pdu (IO)
    module Mib = Mib_monad.Mib (IO)
    module Session = Session_monad.Session (IO)
  end
end
