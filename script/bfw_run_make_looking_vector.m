function bfw_run_make_looking_vector(look_outputs, save_p)

if ( nargin < 1 || isempty(look_outputs) )
  look_outputs = bfw_make_looking_vector( ...
    'rois', 'face' ...
  );
end
if ( nargin < 2 || isempty(save_p) )
  save_p = '/Users/Nick/Desktop/look_outputs.mat';
end

mask = fcat.mask( look_outputs.labels ...
  , @find, 'free_viewing' ...
);

look_outputs = keep_look_outputs( look_outputs, mask );
[look_outputs.labels, look_outputs.categories] = convert_labels( look_outputs );

save( save_p, 'look_outputs', '-v7.3' );

end

function look_outputs = keep_look_outputs(look_outputs, ind)

look_outputs.labels = keep( look_outputs.labels', ind );
look_outputs.look_vectors = look_outputs.look_vectors(ind);
look_outputs.t = look_outputs.t(ind);

end

function [labels, categories] = convert_labels(look_outputs)

[labels, categories] = categorical( look_outputs.labels );

end