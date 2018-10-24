function n = get_stim_protocol_name(id)

%   GET_STIM_PROTOCL_NAME -- Get the string name of an integer stim
%     protocol.
%
%     See also brains.arduino.calino.get_ids
%
%     IN:
%       - `id` (double) |SCALAR|

validateattributes( id, {'double'}, {'real', 'scalar', 'nonnegative', 'integer'} ...
  , 'get_stim_protocol_name', 'id' );

switch ( id )
  case 0
    n = 'mutual_event';
  case 1
    n = 'm1_exclusive_event';
  case 2
    n = 'm2_exclusive_event';
  case 3
    n = 'exclusive_event';
  case 4
    n = 'any_event';
  case 5
    n = 'probabilistic';
  case 6
    n = 'm1_radius_excluding_inner_rect';
  case 7
    n = 'm2_radius_excluding_inner_rect';
  otherwise
    error( 'Unrecognized protocol id: %d.', id );
end

end