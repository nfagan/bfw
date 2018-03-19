function out = get_common_lfp_defaults( append_to )

if ( nargin == 1 )
  out = append_to;
else
  out = struct();
end

out.filter = true;
out.reference_subtract = true;
out.f1 = 2.5;
out.f2 = 250;
out.filter_order = 2;

end