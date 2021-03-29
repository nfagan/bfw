function spike_labels = bfw_remap_cc_spike_labels(spike_labels, cc_spike_labs)

if ( nargin == 1 )
  cc_spike_file = fullfile( bfw.dataroot, 'public/spike_data_labels07192020.mat' );
  cc_spike_labs = shared_utils.io.fload( cc_spike_file );
end

cc_regs = { cc_spike_labs.region };
cc_regs(strcmp(cc_regs, 'accg')) = {'acc'};

cc_sessions = { cc_spike_labs.date };
cc_uuids = cellfun( @convert_uuid, {cc_spike_labs.uuid}, 'un', 0 );

unique_cc_sessions = unique( cc_sessions );
remapped = false( size(cc_sessions) );

for i = 1:numel(unique_cc_sessions)
  un_ind = strcmp( cc_sessions, unique_cc_sessions{i} );
  cc_regs_this_session = unique( cc_regs(un_ind) );
  
  for j = 1:numel(cc_regs_this_session)
    cc_reg_ind = un_ind & strcmp(cc_regs, cc_regs_this_session{j});
    
    match_ind = find( spike_labels, {unique_cc_sessions{i}, cc_regs_this_session{j}} );
    assert( sum(cc_reg_ind) == numel(match_ind) );

    assert( ~any(remapped(match_ind)) );
    remapped(match_ind) = true;

    setcat( spike_labels, 'unit_uuid', cc_uuids(cc_reg_ind), match_ind );  
  end
end

assert( all(remapped) );

end

function id = convert_uuid(x)

if ( ischar(x) )
 id = sprintf( 'unit_uuid__%s', x );
else
  id = sprintf( 'unit_uuid__%d', x );
end

end