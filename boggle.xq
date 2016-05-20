xquery version "3.1";

declare namespace java="java";

(:["lrytte"  "vthrwe"  "eghwne"  "seotis"]
["anaeeg"  "idsytt"  "oattow"  "mtoicu"]
["afpkfs"  "xlderi"  "hcpoas"  "ensieu"]
["yldevr"  "znrnhl"  "nmiqhu"  "obbaoj"]  :)

declare variable $in1 := doc('dictEnglishBig.xml')//w/string();

declare variable $in := $in1;
(: combinations :) (: let $F := function($n){ fold-left( (1 to $n ), 1, function($l, $r){$l * $r}) } return let $C := function( $n, $k ){ $F( $n ) div ( $F( $n - $k ) * $F( $k ) ) } return (  for $i in ( 3 to 16 ) return $C( 16, $i ) ) :)

declare variable $orig-dice := (
"lrytte",  "vthrwe",  "eghwne",  "seotis",
"anaeeg",  "idsytt",  "oattow",  "mtoicu",
"afpkfs",  "xlderi",  "hcpoas",  "ensieu",
"yldevr",  "znrnhl",  "nmiqhu",  "obbaoj" );

declare variable $GenerateDice := function( $seed ){ fold-left( 
	$orig-dice, 
	random-number-generator( $seed ), 
	function( $res, $str ){ 
		head($res)?next(),
		tail($res),
		(:trace:)((head($res)?permute( local:tolower-and-split( $str ) ))[1])
	}
 )=>tail() };
 
declare variable $SerializeDice := function( $dice ){ string-join( 
	 for $i  in ( 1 to $h ) return ( for $j in ( 1 to $w ) return $dice[ ($i - 1) * $w + $j ], '&#x0A;' )
, ' ' ) };

declare variable $Dict := fold-right( $in, map{}, function( $i, $map ){ local:add-chars($map, local:tolower-and-split($i)) } ); (:=> serialize(map{'method':'adaptive'}), :)

declare function local:tolower-and-split($i as xs:string) (:as xs:string*:)
{
	string-to-codepoints(lower-case($i))!codepoints-to-string(.)(:5sec:)
	(:let $l := lower-case($i) return for $k in ( 1 to string-length($l) ) return substring( $l, $k, 1 ) :)(:9sec:)
	(:analyze-string(lower-case($i), '.')//text()/string():)(:29sec:)
	(:java:java.lang.String.toCharArray( lower-case($i) ):)(:4.7sec:)
	
};

declare function local:add-chars( $map, $ch )
{
	if ( empty( $ch ) ) then
		map:put( $map, "#", true() )
	else 
		let $head := head( $ch ) 
		let $oldmap := $map($head) return
			if ( exists($oldmap) ) then 
				map:put( $map, $head, local:add-chars( $oldmap, tail( $ch ) ) )
			else
				map:put( $map, $head, local:add-chars( map{}, tail( $ch ) ) )
};

declare variable $w := 4;
declare variable $h := 4;
declare function local:for-each( $f ){ for $i in ( 1 to $h *$w ) return $f( $i ) };
declare variable $M := map:merge( local:for-each( function($i){ map:entry($i, () ) } ) );

declare function local:pos-from-w-h( $x, $y ) { $x + ( $y - 1 ) * $w };
declare function local:w-h-from-pos( $i ) { let $m := $i mod $w return if ( $m ) then ($m, $i idiv $w + 1) else ( $w, $i idiv $w ) };
declare function local:possible-transitions( $x, $y ){ 
	for $dx in ( -1, 0, 1 ) return for $dy in ( -1, 0, 1 ) return if ( $dx != 0 or $dy != 0 ) then ( 
		let $newx := $x + $dx let $newy := $y + $dy return if ( $newx > 0 and $newy > 0 and $newx <= $w and $newy <= $h ) then local:pos-from-w-h($newx, $newy) else () ) else () 
};

declare function local:possible-transitions( $i ){ let $xy := local:w-h-from-pos($i) let $x := $xy[1] let $y := $xy[2] return local:possible-transitions( $x, $y ) };
declare variable $T := map:merge( local:for-each( function( $i ){ map:entry( $i, local:possible-transitions( $i )) } ) );

declare function local:process-transitions( $i as xs:integer, $m as map(*), $r as xs:string, $dict as map(*), $Dice as xs:string* )
{
	let $ch as xs:string := $Dice[ $i ] return
	let $newdict as map(*)?:= $dict($ch) return
	let $newres := $r||$ch return
	if (exists($newdict)) then (
		if ( string-length( (:trace:)( $newres ) ) > 2 and $newdict("#") ) then (:trace:)( $newres(:, "##Word found: ":) ) else (),
		let $newm := map:remove( $m, $i ) return
			for $j in $T($i)[map:contains( $newm, . )] return 
				local:process-transitions( $j, $newm, $newres, $newdict, $Dice ) 
	)
	else 
	( )
};

exists($Dict)[1 - 1],
for $k in ( 0 to 1000 ) return 
	let $Dice := $GenerateDice( $k ) return 
( '&#x0A;', trace($SerializeDice($Dice)), 
 local:for-each( function( $i ){ (:string( $i ),:) local:process-transitions( (:trace:)($i), $M, "", $Dict, $Dice ) } ) => distinct-values() => sort(),'&#x0A;', " =============", '&#x0A;' ),

($M, "=============", $T )! . => serialize(map{'method':'adaptive'}) 
