open! Import

module Pdu (IO : Io_intf.S) : Pdu_intf.S with module IO := IO = struct
  include Pdu

  let snmp_pdu_create pdu_type = IO.wrap_mt Pdu.snmp_pdu_create pdu_type
  let snmp_add_null_var t oid = IO.wrap_mt (Pdu.snmp_add_null_var t) oid
  let snmp_add_variable t oid value = IO.wrap_mt (Pdu.snmp_add_variable t oid) value
end
