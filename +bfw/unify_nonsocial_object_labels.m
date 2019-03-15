function labs = unify_nonsocial_object_labels(labs, roi_cat)

if ( nargin < 2 )
  roi_cat = 'roi';
end

is_nonsocial_obj = find( labs, {'left_nonsocial_object', 'right_nonsocial_object'} );
setcat( labs, roi_cat, 'nonsocial_object', is_nonsocial_obj );
prune( labs );

end