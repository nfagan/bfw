function [trained_classifier, validation_accuracy] = ...
  bagged_trees_vector_spike_classifier(spikes, labels, predictor_categories, mask, varargin)

defaults = struct();
defaults.holdout_p = 0.75;
defaults.bag_size = 200;
defaults.seed = [];
defaults.label_mask = mask;
params = bfw.parsestruct( defaults, varargin );

label_mask = params.label_mask;

assert_ispair( spikes, labels );
assert_hascat( labels, predictor_categories );
validateattributes( spikes, {'double'}, {'vector'}, mfilename, 'spikes' );
assert( numel(label_mask) == numel(mask), ['Number of elements' ...
  , ' of label mask must match number of elements of spike mask.'] );

x = spikes(mask);
categ = removecats( categorical(labels, predictor_categories, label_mask) );

y = double( categ );

if ( ~isempty(params.seed) )
  prev_state = rng( params.seed );
  cleanup = onCleanup( @() rng(prev_state) );
end

% Train a classifier
trained_classifier = fitensemble( x, y, 'Bag', params.bag_size, 'Tree' ...
  , 'Type', 'Classification' ...
);
 
% Set up holdout validation
cvp = cvpartition( y, 'Holdout', params.holdout_p );
train_x = x(cvp.training, :);
train_y = y(cvp.training, :);
 
% Train a classifier
validation_model = fitensemble( train_x, train_y, 'Bag', params.bag_size, 'Tree' ...
  , 'Type', 'Classification' ...
);

% Compute validation accuracy
test_x = x(cvp.test,:);
test_y = y(cvp.test,:);

validation_accuracy = 1 - loss(validation_model, test_x, test_y ...
  , 'LossFun', 'ClassifError' ...
);

end