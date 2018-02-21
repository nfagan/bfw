function str = channel_n_to_str( prefix, n )

if ( n < 10 )
  str = sprintf( '%s0%d', prefix, n );
else
  str = sprintf( '%s%d', prefix, n );
end

end