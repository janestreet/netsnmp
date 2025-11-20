open! Core
open Netsnmp

module Version_selector = struct
  type t =
    | V1
    | V2c
    | V3
  [@@deriving sexp_of, enumerate]
end

let version_auth_param =
  let%map_open.Command version =
    flag
      "-snmp-version"
      (optional_with_default
         Version_selector.V2c
         (Arg_type.create (fun s ->
            match String.lowercase s with
            | "v1" -> Version_selector.V1
            | "v2c" -> V2c
            | "v3" -> V3
            | _ -> failwith "Invalid version, must be one of: v1, v2c, v3")))
      ~doc:"VERSION SNMP version (v1|v2c|v3, default: v2c)"
  and community = flag "-c" (optional string) ~doc:"COMMUNITY SNMP community (for v1/v2c)"
  and security_name =
    flag "-security-name" (optional string) ~doc:"NAME Security name (for v3)"
  and auth_password =
    flag
      "-auth-password"
      (optional string)
      ~doc:"PASSWORD Auth password (for v3, omit for noAuthNoPriv)"
  in
  match (version : Version_selector.t) with
  | V1 ->
    let community = Option.value_exn community ~message:"-c is required for SNMP v1" in
    Netsnmp.Snmp_version_auth.create_v1 community
  | V2c ->
    let community = Option.value_exn community ~message:"-c is required for SNMP v2c" in
    Netsnmp.Snmp_version_auth.create_v2c community
  | V3 ->
    let security_name =
      Option.value_exn security_name ~message:"-security-name is required for SNMP v3"
    in
    let auth_protocol =
      match auth_password with
      | None -> Netsnmp.Auth_protocol.Ignore
      | Some password -> Netsnmp.Auth_protocol.MD5 { password }
    in
    Netsnmp.Snmp_version_auth.create_v3 ~security_name ~auth_protocol
;;

module Snmp_connection_params = struct
  type t =
    { hostname : string
    ; version_auth : Netsnmp.Snmp_version_auth.t
    }

  let param =
    let%map_open.Command hostname = anon ("hostname" %: string)
    and version_auth = version_auth_param in
    { hostname; version_auth }
  ;;
end

(* Default session parameters that apply across SNMP versions *)
module Session_defaults = struct
  let retries = 3
  let timeout_usec = 3_000_000 (* 3 seconds in microseconds *)
end

let open_session_from_connection_info_with
  ~snmp_sess_open
  { Netsnmp_types.Connection_info.version_auth
  ; peername
  ; localname
  ; local_port
  ; retries
  ; timeout
  }
  =
  let module Session = Netsnmp_raw.Session in
  let retries = Option.value retries ~default:Session_defaults.retries in
  let timeout = Option.value timeout ~default:Session_defaults.timeout_usec in
  let peername = peername in
  let localname = Option.value localname ~default:"" in
  let local_port = Option.value local_port ~default:0 in
  let ( version
      , community
      , securityName
      , securityLevel
      , securityAuthProto
      , securityAuthPassword )
    =
    match version_auth with
    | Netsnmp.Snmp_version_auth.Version_1 { community } ->
      ( Session.Snmp_version.Version_1
      , community
      , ""
      , Session.Snmp_security_level.NoAuthNoPriv
      , Session.Snmp_sec_auth_proto.Ignore
      , "" )
    | Version_2c { community } ->
      ( Session.Snmp_version.Version_2c
      , community
      , ""
      , Session.Snmp_security_level.NoAuthNoPriv
      , Session.Snmp_sec_auth_proto.Ignore
      , "" )
    | Version_3 { security_name; auth_protocol } ->
      let securityLevel, securityAuthProto, securityAuthPassword =
        match auth_protocol with
        | Netsnmp.Auth_protocol.Ignore ->
          Session.Snmp_security_level.NoAuthNoPriv, Session.Snmp_sec_auth_proto.Ignore, ""
        | MD5 { password } ->
          ( Session.Snmp_security_level.AuthNoPriv
          , Session.Snmp_sec_auth_proto.UsmHMACMD5AuthProtocol
          , password )
      in
      ( Session.Snmp_version.Version_3
      , ""
      , security_name
      , securityLevel
      , securityAuthProto
      , securityAuthPassword )
  in
  snmp_sess_open
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
;;
