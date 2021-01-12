function [trainedClassifier, validationAccuracy] = trainBaggedTreesClassifier(datasetTable, predictorNames, responseStr, holdoutPercent)
 
% Extract predictors and response
predictors = datasetTable(:,predictorNames);
predictors = table2array(varfun(@double, predictors));
response = datasetTable.(responseStr);
% Train a classifier
trainedClassifier = fitensemble(predictors, response, 'Bag', 200, 'Tree' ...
  , 'Type', 'Classification' ...
  , 'PredictorNames', predictorNames ...
  , 'ResponseName', responseStr ...
  , 'ClassNames', unique(response) ...
);
 
% Set up holdout validation
cvp = cvpartition(response, 'Holdout', holdoutPercent);
trainingPredictors = predictors(cvp.training,:);
trainingResponse = response(cvp.training,:);
 
% Train a classifier
validationModel = fitensemble(trainingPredictors, trainingResponse, 'Bag', 200, 'Tree' ...
  , 'Type', 'Classification' ...
  , 'PredictorNames', predictorNames ...
  , 'ResponseName', responseStr ...
  , 'ClassNames', unique(response) ...
);
 
% Compute validation accuracy
validationPredictors = predictors(cvp.test,:);
validationResponse = response(cvp.test,:);
validationAccuracy = 1 - loss(validationModel, validationPredictors, validationResponse ...
  , 'LossFun', 'ClassifError' ...
);

end