open Migrate_parsetree
module M = Ppx_tyxml_register (* dirty way to force link *)
let () = Driver.run_as_ppx_rewriter ()
