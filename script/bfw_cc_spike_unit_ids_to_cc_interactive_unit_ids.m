function m = bfw_cc_spike_unit_ids_to_cc_interactive_unit_ids(to_str)

m = containers.Map( 'keytype', 'double', 'valuetype', 'double' );

m(261) = 1175;
m(1230) = 41;
m(1266) = 111;
m(1276) = 121;
m(2550) = 134;
m(1283) = 136;
m(1289) = 142;
m(2554) = 158;
m(1706) = 165;
m(1730) = 187;
m(1734) = 191;
m(1796) = 366;
m(2727) = 445;
m(353) = 456;
m(371) = 485;
m(1041) = 700;
m(600) = 710;
m(1542) = 790;
m(211) = 948;
m(213) = 977;
m(764) = 1010;
m(1122) = 1018;
m(789) = 1038;

if ( to_str )
  k = cellfun( @(x) sprintf('unit_uuid__%d', x), keys(m), 'un', 0 );
  v = cellfun( @(x) sprintf('unit_uuid__%d', x), values(m), 'un', 0 );
  m = containers.Map( k, v );
end

end