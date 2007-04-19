(* Ocsigen
 * http://www.ocsigen.org
 * Module eliomexamples.ml
 * Copyright (C) 2007 Vincent Balat
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception; 
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)


(* Other examples for Eliom, and various tests *)

open Tutoeliom
open XHTML.M
open Eliom.Xhtml
open Eliom
open Lwt

(* menu with preapplied services *)

let preappl = preapply coucou_params (3,(4,"cinq"))
let preappl2 = preapply uasuffix "plop"

let mymenu current sp =
  Eliomboxes.menu ~classe:["menuprincipal"]
    (coucou, <:xmllist< coucou >>)
    [
     (preappl, <:xmllist< params >>);
     (preappl2, <:xmllist< params and suffix >>);
   ] current sp

let _ = 
  register_new_service 
    ~url:["menu"]
    ~get_params:unit
    (fun sp () () -> 
      return 
        (html
          (head (title (pcdata "")) [])
          (body [h1 [pcdata "Hallo"];
               mymenu coucou sp ])))

(* GET Non-attached coservice *)
let nonatt = new_coservice' ~get_params:(string "e") ()

(* GET coservice with preapplied fallback *)
(* + Non-attached coservice on a pre-applied coservice *)
(* + Non-attached coservice on a non-attached coservice *)
let f sp s =
  (html
     (head (title (pcdata "")) [])
     (body [h1 [pcdata s];
            p [a nonatt sp [pcdata "clic"] "nonon"];
            get_form nonatt sp 
              (fun string_name ->
                [p [pcdata "Non attached coservice: ";
                    string_input string_name;
                    submit_input "Click"]])
          ]))

let getco = register_new_coservice
    ~fallback:preappl
    ~get_params:(int "i" ** string "s")
    (fun sp (i,s) () -> return (f sp s))

let _ = register nonatt (fun sp s () -> return (f sp s))

let _ = 
  register_new_service 
    ~url:["getco"]
    ~get_params:unit
    (fun sp () () -> 
      return 
        (html
          (head (title (pcdata "")) [])
          (body [p [a getco sp [pcdata "clic"] (22,"eee") ];
                 get_form getco sp 
                   (fun (number_name,string_name) ->
                     [p [pcdata "Write an int: ";
                         int_input number_name;
                         pcdata "Write a string: ";
                         string_input string_name;
                         submit_input "Click"]])
               ])))


(* POST service with preapplied fallback are not possible: *)
(*
let my_service_with_post_params = 
  register_new_post_service
    ~fallback:preappl
    ~post_params:(string "value")
    (fun _ () value ->  return
      (html
         (head (title (pcdata "")) [])
         (body [h1 [pcdata value]])))
*)

(* GET coservice with coservice fallback: not possible *)
(*
let preappl3 = preapply getco (777,"ooo")

let getco2 = 
  register_new_coservice
    ~fallback:preappl3
    ~get_params:(int "i2" ** string "s2")
    (fun sp (i,s) () -> 
      return 
        (html
          (head (title (pcdata "")) [])
          (body [h1 [pcdata s]])))

*)


(* POST service with coservice fallback *)
let my_service_with_post_params = 
  register_new_post_service
    ~fallback:getco
    ~post_params:(string "value")
    (fun _ (i,s) value ->  return
      (html
         (head (title (pcdata "")) [])
         (body [h1 [pcdata (s^" "^value)]])))

let form2 = register_new_service ["postco"] unit
  (fun sp () () -> 
     let f =
       (post_form my_service_with_post_params sp
          (fun chaine -> 
            [p [pcdata "Write a string: ";
                string_input chaine]]) (222,"ooo")) in
     return
       (html
         (head (title (pcdata "form")) [])
         (body [f])))


(* Many cookies *)
let cookiename = "c"

let cookies = new_service ["c";""] unit ()

let _ = Cookies.register cookies
    (fun sp () () ->  return
      ((html
        (head (title (pcdata "")) [])
        (body [p 
                 (List.fold_left
                    (fun l (n,v) ->
                      (pcdata (n^"="^v))::
                      (br ())::l
                    )
                    [a cookies sp [pcdata "send other cookies"] ()]
                    (get_cookies sp))])),
       let cookies =
         [Extensions.Set (Some [], Some (Unix.time () +. 30.), 
                          [((cookiename^"6"),(string_of_int (Random.int 100)));
                           ((cookiename^"7"),(string_of_int (Random.int 100)))]);
          Extensions.Set (Some ["plop"], None, 
                          [((cookiename^"8"),(string_of_int (Random.int 100)));
                           ((cookiename^"9"),(string_of_int (Random.int 100)));
                           ((cookiename^"10"),(string_of_int (Random.int 100)));
                           ((cookiename^"11"),(string_of_int (Random.int 100)));
                           ((cookiename^"12"),(string_of_int (Random.int 100)))]);
        ]
       in if List.mem_assoc (cookiename^"1") (get_cookies sp)
       then 
         (Extensions.Unset (None, 
                            [(cookiename^"1");(cookiename^"2")]))::cookies
       else 
         (Extensions.Set (None, None,
                          [((cookiename^"1"),(string_of_int (Random.int 100)));
                           ((cookiename^"2"),(string_of_int (Random.int 100)));
                           ((cookiename^"3"),(string_of_int (Random.int 100)))]))
         ::cookies
      ))


(* Cookies or not cookies with Any *)
let sendany = 
  Any.register_new_service 
    ~url:["sendany2"]
    ~get_params:(string "type")
   (fun sp s () -> 
     if s = "nocookie"
     then
       return
         (Xhtml.send
            sp
           (html
             (head (title (pcdata "")) [])
             (body [p [pcdata "This page does not set cookies"]])))
     else 
       return
         (Xhtml.Cookies.send
            sp
            ((html
                (head (title (pcdata "")) [])
                (body [p [pcdata "This page does set a cookie"]])),
             [Extensions.Set (None, None, 
                              [(("arf"),(string_of_int (Random.int 100)))])]))
   )


(* Send file *)
let _ = 
  register_new_service 
    ~url:["files";""]
    ~get_params:unit
    (fun _ () () -> 
      return 
        (html
          (head (title (pcdata "")) [])
          (body [h1 [pcdata "With a suffix, that page will send a file"]])))

let sendfile2 = 
  Files.register_new_service 
    ~url:["files";""]
    ~get_params:(suffix (all_suffix "filename"))
    (fun _ s () -> 
      return ("/var/www/ocsigen/"^(string_of_url_path s)))

let _ = 
  register_new_service 
    ~url:["files";"exception"]
    ~get_params:unit
    (fun _ () () -> 
      return 
        (html
          (head (title (pcdata "")) [])
          (body [h1 [pcdata "With another suffix, that page will send a file"]])))


(* Complex suffixes *)
let suffix2 = 
  register_new_service 
    ~url:["suffix2";""]
    ~get_params:(suffix (string "suff1" ** int "ii" ** all_suffix "ee"))
    (fun sp (suf1,(ii,ee)) () ->  
      return
        (html
           (head (title (pcdata "")) [])
           (body
              [p [pcdata "The suffix of the url is ";
                  strong [pcdata (suf1^", "^(string_of_int ii)^", "^
                                  (string_of_url_path ee))]]])))

let suffix3 = 
  register_new_service 
    ~url:["suffix3";""]
    ~get_params:(suffix_prod (string "suff1" ** int "ii" ** all_suffix_user int_of_string string_of_int "ee") (string "a" ** int "b"))
    (fun sp ((suf1, (ii, ee)), (a, b)) () ->  
      return
        (html
           (head (title (pcdata "")) [])
           (body
              [p [pcdata "The parameters in the url are ";
                  strong [pcdata (suf1^", "^(string_of_int ii)^", "^
                                  (string_of_int ee)^", "^
                                  a^", "^(string_of_int b))]]])))

let create_suffixform2 (suf1,(ii,ee)) =
    <:xmllist< <p>Write a string: 
      $string_input suf1$ <br/>
      Write an int: $int_input ii$ <br/>
      Write a string: $user_type_input string_of_url_path ee$ <br/>
      $submit_input "Click"$</p> >>

let suffixform2 = register_new_service ["suffixform2"] unit
  (fun sp () () -> 
     let f = get_form suffix2 sp create_suffixform2 in
     return
       (html
          (head (title (pcdata "")) [])
          (body [h1 [pcdata "Hallo"];
                 f ])))

let create_suffixform3 ((suf1, (ii, ee)), (a, b)) =
    <:xmllist< <p>Write a string: 
      $string_input suf1$ <br/>
      Write an int: $int_input ii$ <br/>
      Write an int: $int_input ee$ <br/>
      Write a string: $string_input a$ <br/>
      Write an int: $int_input b$ <br/> 
      $submit_input "Click"$</p> >>

let suffixform3 = register_new_service ["suffixform3"] unit
  (fun sp () () -> 
     let f = get_form suffix3 sp create_suffixform3 in
     return
        (html
          (head (title (pcdata "")) [])
          (body [h1 [pcdata "Hallo"];
                 f ])))


(* Send file with regexp *)
let _ = 
  register_new_service 
    ~url:["files2";""]
    ~get_params:unit
    (fun _ () () -> 
      return 
        (html
          (head (title (pcdata "")) [])
          (body [h1 [pcdata "With a suffix, that page will send a file"]])))

let r = Str.regexp "~\\([^/]*\\)\\(.*\\)"

let sendfile2 = 
  Files.register_new_service 
    ~url:["files2";""]
    ~get_params:(regexp r "/home/\\1/public_html\\2" "filename")
    (fun _ s () -> return s)

let sendfile2 = 
  Files.register_new_service 
    ~url:["files2";""]
    ~get_params:(suffix (all_suffix_regexp r "/home/\\1/public_html\\2" "filename"))
    (fun _ s () -> return s)

let create_suffixform4 n =
    <:xmllist< <p>Write the name of the file: 
      $string_input n$ 
      $submit_input "Click"$</p> >>

let suffixform4 = register_new_service ["suffixform4"] unit
  (fun sp () () -> 
     let f = get_form sendfile2 sp create_suffixform4 in
     return
        (html
          (head (title (pcdata "")) [])
          (body [h1 [pcdata "Hallo"];
                 f ])))
