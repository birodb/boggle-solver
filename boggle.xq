xquery version "3.1";


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
		string-to-codepoints( $str )[ (:trace:)(head($res)?permute( 1 to 6 )[1])]=>codepoints-to-string() 
	}
 )=>tail() };
 
 declare variable $SerializeDice := function( $dice ){ string-join( 
	 for $i  in ( 1 to $h ) return ( for $j in ( 1 to $w ) return $dice[ ($i - 1) * $w + $j ], '&#x0A;' )
, ' ' ) };

declare variable $Dict := fold-right( $in, map{}, function( $i, $map ){ local:add-chars($map, string-to-codepoints(lower-case($i))!codepoints-to-string(.)) } ); (:=> serialize(map{'method':'adaptive'}), :)


declare function local:add-chars( $map, $ch )
{
	if ( empty( $ch ) ) then
		map:put( $map, 0, 1 )
	else 
		let $head := head( $ch ) return 
			if ( map:contains( $map, $head ) ) then 
				map:put( $map, $head, local:add-chars( $map($head), tail( $ch ) ) )
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

declare function local:process-transitions( $i, $m, $r, $dict, $Dice )
{
	let $ch := $Dice[ $i ] return
	let $newdict := $dict($ch) return
	let $newres := $r||$ch return
	if (exists($newdict)) then (
		if ( string-length( (:trace:)( $newres ) ) > 2 and $newdict(0) ) then (:trace:)( $newres(:, "##Word found: ":) ) else (),
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
