(** Errors reported in the PDU response from the remote agent *)

type t =
  | SNMPERR_SUCCESS
  | SNMPERR_GENERR
  | SNMPERR_BAD_LOCPORT
  | SNMPERR_BAD_ADDRESS
  | SNMPERR_BAD_SESSION
  | SNMPERR_TOO_LONG
  | SNMPERR_NO_SOCKET
  | SNMPERR_V2_IN_V1
  | SNMPERR_V1_IN_V2
  | SNMPERR_BAD_REPEATERS
  | SNMPERR_BAD_REPETITIONS
  | SNMPERR_BAD_ASN1_BUILD
  | SNMPERR_BAD_SENDTO
  | SNMPERR_BAD_PARSE
  | SNMPERR_BAD_VERSION
  | SNMPERR_BAD_SRC_PARTY
  | SNMPERR_BAD_DST_PARTY
  | SNMPERR_BAD_CONTEXT
  | SNMPERR_BAD_COMMUNITY
  | SNMPERR_NOAUTH_DESPRIV
  | SNMPERR_BAD_ACL
  | SNMPERR_BAD_PARTY
  | SNMPERR_ABORT
  | SNMPERR_UNKNOWN_PDU
  | SNMPERR_TIMEOUT
  | SNMPERR_BAD_RECVFROM
  | SNMPERR_BAD_ENG_ID
  | SNMPERR_BAD_SEC_NAME
  | SNMPERR_BAD_SEC_LEVEL
  | SNMPERR_ASN_PARSE_ERR
  | SNMPERR_UNKNOWN_SEC_MODEL
  | SNMPERR_INVALID_MSG
  | SNMPERR_UNKNOWN_ENG_ID
  | SNMPERR_UNKNOWN_USER_NAME
  | SNMPERR_UNSUPPORTED_SEC_LEVEL
  | SNMPERR_AUTHENTICATION_FAILURE
  | SNMPERR_NOT_IN_TIME_WINDOW
  | SNMPERR_DECRYPTION_ERR
  | SNMPERR_SC_GENERAL_FAILURE
  | SNMPERR_SC_NOT_CONFIGURED
  | SNMPERR_KT_NOT_AVAILABLE
  | SNMPERR_UNKNOWN_REPORT
  | SNMPERR_USM_GENERICERROR
  | SNMPERR_USM_UNKNOWNSECURITYNAME
  | SNMPERR_USM_UNSUPPORTEDSECURITYLEVEL
  | SNMPERR_USM_ENCRYPTIONERROR
  | SNMPERR_USM_AUTHENTICATIONFAILURE
  | SNMPERR_USM_PARSEERROR
  | SNMPERR_USM_UNKNOWNENGINEID
  | SNMPERR_USM_NOTINTIMEWINDOW
  | SNMPERR_USM_DECRYPTIONERROR
  | SNMPERR_NOMIB
  | SNMPERR_RANGE
  | SNMPERR_MAX_SUBID
  | SNMPERR_BAD_SUBID
  | SNMPERR_LONG_OID
  | SNMPERR_BAD_NAME
  | SNMPERR_VALUE
  | SNMPERR_UNKNOWN_OBJID
  | SNMPERR_NULL_PDU
  | SNMPERR_NO_VARS
  | SNMPERR_VAR_TYPE
  | SNMPERR_MALLOC
  | SNMPERR_KRB5
  | SNMPERR_PROTOCOL
  | SNMPERR_OID_NONINCREASING
  | SNMPERR_JUST_A_CONTEXT_PROBE
[@@deriving sexp, enumerate]
