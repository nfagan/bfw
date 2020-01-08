function add_stim_trial_uuids(stim_labels, mask)

if ( nargin < 2 )
  mask = rowmask( stim_labels );
end

addcat( stim_labels, 'stim_trial_uuid' );

for i = 1:numel(mask)
  setcat( stim_labels, 'stim_trial_uuid', shared_utils.general.uuid(), mask(i) );
end

end