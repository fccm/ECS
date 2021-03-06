module MyECS = ECS.Make(ECS.IntKey)

(* Definition of 5 properties *)
module Name = struct
  type s = string
  include (val (MyECS.new_property ~default:"toto" ())
    : MyECS.PROPERTY with type t = s)
end

module Age = struct
  type s = int
  include (val (MyECS.new_property ~default:18 ())
    : MyECS.PROPERTY with type t = s)
end

module Genre = struct
  type s = Male | Female
  include (val (MyECS.new_property ())
    : MyECS.PROPERTY with type t = s)
end

module Position = struct
  type s = (float * float)
  include (val (MyECS.new_property ~default:(0.,0.) ())
    : MyECS.PROPERTY with type t = s)
end

module Speed = struct
  type s = (float * float)
  include (val (MyECS.new_property ~default:(0.,0.) ())
    : MyECS.PROPERTY with type t = s)
end

(* Definition of 3 components *)
module Living = struct
  include (val (MyECS.new_component 
    [(module Name );
     (module Age  );
     (module Genre)]
    []) : MyECS.COMPONENT)
end

module Movable = struct
  include (val (MyECS.new_component
    [(module Position);
     (module Speed   )]
    [(module Living  )]
  ) : MyECS.COMPONENT)
end

module Thing = struct
  include (val (MyECS.new_component
    [(module Name    );
     (module Position)]
    []) : MyECS.COMPONENT)
end

(* Definition of a system *)
module TestSystem = struct 
  let main e = 
    let norm (a,b) = sqrt (a *. a +. b *. b) in
    let genre = function |Genre.Male -> "man" |Genre.Female -> "woman" in
    Printf.printf "My name is %s, I am a %s of age %i; currently at (%f;%f) and I am currently walking at %f m/s\n"
    (Name.get e) (genre (Genre.get e)) (Age.get  e) 
    (fst (Position.get e)) (snd (Position.get e))
    (norm (Speed.get e))

  let run l = 
    List.iter main l
end

(* Test functions *)
let create_sbdy genre name age pos spe = 
  MyECS.next_id ()
  |> Living.b 
  |> Movable.b
  |> Genre.s genre
  |> Name.s name
  |> Age.s age
  |> Position.s pos
  |> Speed.s spe

let create_sbdy2 genre =
  MyECS.next_id ()
  |> Movable.b
  |> Genre.s genre

let create_sbdyfail () =
  MyECS.next_id ()
  |> Movable.b

let create_sbdy3 genre name age =
  MyECS.next_id ()
  |> Living.b
  |> Genre.s genre
  |> Name.s name
  |> Age.s age

let create_sbdy4 genre name age pos = 
  MyECS.next_id ()
  |> Living.b 
  |> Movable.b
  |> Genre.s genre
  |> Name.s name
  |> Age.s age
  |> Position.s pos

let test_system () =
  let l = [ 
    create_sbdy Genre.Male "tutu" 21 (3.,5.) (4.,0.);
    create_sbdy2 Genre.Female;
    create_sbdy3 Genre.Male "titi" 22;
    create_sbdy4 Genre.Female "tata" 25 (0.,1.)]
  in TestSystem.run (MyECS.filter_all [(module Living); (module Movable)]);
  List.iter MyECS.delete l

let test_exception () =
  let l = [create_sbdyfail ();
           create_sbdy2 Genre.Female]
  in try 
    TestSystem.run (MyECS.filter_all [(module Living); (module Movable)]);
  with |MyECS.Property_Error(_) -> print_endline "exception catched !";
  List.iter MyECS.delete l

let test_remove () =
  let l = [
    create_sbdy2 Genre.Female;
    create_sbdy Genre.Male "tutu" 21 (3.,4.) (0.,0.)]
  in
  TestSystem.run (MyECS.filter_all [(module Living); (module Movable)]);
  Printf.printf "Removing entity...\n";
  MyECS.delete (List.hd l);
  TestSystem.run (MyECS.filter_all [(module Living); (module Movable)]);
  MyECS.delete (List.hd (List.tl l))

let test_persistance () =
  let (e1,e2) = 
    create_sbdy Genre.Male "titi" 22 (0.,0.) (2.,3.),
    MyECS.next_id () |> Thing.b
  in 
  ignore (Thing.b e1
  |> Name.s "tititi");
  ignore (e2 
  |> Living.b
  |> Movable.b
  |> Genre.s Genre.Female);
  TestSystem.run (MyECS.filter_all [(module Living); (module Movable)]);
  MyECS.delete e1; MyECS.delete e2

let _ = 
  print_endline "Test 1 : System";
  test_system ();
  print_endline "";
  print_endline "Test 2 : Exceptions";
  test_exception ();
  print_endline "";
  print_endline "Test 3 : Removal";
  test_remove ();
  print_endline "";
  print_endline "Test 4 : Persistance";
  test_persistance ()

    
