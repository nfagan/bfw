function f = performance_field_from_kind(kind)

validateattributes( kind, {'char'}, {'scalartext'}, mfilename, 'kind' );

switch ( kind )
  case 'train_gaze_test_reward'
    f = 'gr_outs';
  case 'train_reward_test_gaze'
    f = 'rg_outs';
  case 'train_gaze_test_gaze'
    f = 'gg_outs';
  case 'train_reward_test_reward'
    f = 'rr_outs';
  otherwise
    error( 'Unrecognized kind "%s".', kind );
end

end