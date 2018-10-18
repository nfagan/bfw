function n = num2str_zeropad(pref, n)

if ( n < 10 )
  n = sprintf( '%s0%d', pref, n );
else
  n = sprintf( '%s%d', pref, n );
end

end