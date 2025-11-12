%% train_speaker_model.m — Trains multi-speaker classifier for password verification
clear; clc; close all;

%% === Load configuration paths ===
load('config_paths.mat');  % loads PROJECT_ROOT

%% === Load extracted features ===
featDir = fullfile(PROJECT_ROOT, 'outputs', 'features');
trainFile = fullfile(featDir, 'features_train_speaker.csv');
testFile  = fullfile(featDir, 'features_test_speaker.csv');

if ~isfile(trainFile) || ~isfile(testFile)
    error('Feature CSVs not found! Run extract_features_speaker.m first.');
end

Ttr = readtable(trainFile);
Tte = readtable(testFile);

%% === Prepare features and labels ===
featNames = Ttr.Properties.VariableNames(1:end-1);
Xtr = Ttr{:, featNames};
Ytr = string(Ttr.label);

Xte = Tte{:, featNames};
Yte = string(Tte.label);

fprintf("TRAIN: %d samples | TEST: %d samples | Speakers: %d\n", ...
    numel(Ytr), numel(Yte), numel(unique(Ytr)));

%% === Normalize features ===
mu_s = mean(Xtr, 1);
sig_s = std(Xtr, [], 1);
sig_s(sig_s == 0) = 1;

Ztr = (Xtr - mu_s) ./ sig_s;
Zte = (Xte - mu_s) ./ sig_s;

%% === Train ECOC SVM classifier ===
fprintf("Training multi-class SVM (this might take a few minutes)...\n");

t = templateSVM('KernelFunction', 'rbf', ...
                'KernelScale', 'auto', ...
                'Standardize', false);

speakerMdl = fitcecoc(Ztr, Ytr, ...
    'Learners', t, ...
    'Coding', 'onevsall', ...
    'ClassNames', unique(Ytr));

%% === Cross-validation ===
K = min(5, max(2, floor(size(Ztr,1) / 1000)));  % up to 5 folds
cvMdl = crossval(speakerMdl, 'KFold', K);
cvAcc = 1 - kfoldLoss(cvMdl);
fprintf("Cross-validation (K=%d) Accuracy: %.3f\n", K, cvAcc);

%% === Evaluate on test set ===
[yPred, ~] = predict(speakerMdl, Zte);
testAcc = mean(yPred == Yte);
fprintf("Holdout TEST Accuracy: %.3f (N=%d)\n", testAcc, numel(Yte));

%% === Display confusion matrix safely ===
% Make sure labels are the same type
if iscell(yPred), yPred = string(yPred); end
if ~iscell(Yte), Yte = string(Yte); end

try
    figure('Name','Speaker Confusion Matrix');
    cm = confusionchart(categorical(Yte), categorical(yPred));
    cm.Title = 'Speaker Classification (Test Set)';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';
catch ME
    warning("Could not display confusion matrix: %s", ME.message);
end

%% === Save model and scaler ===
outDir = fullfile(PROJECT_ROOT, 'outputs', 'models');
if ~isfolder(outDir), mkdir(outDir); end

featNames = string(featNames);
save(fullfile(outDir, 'speaker_model.mat'), ...
    "speakerMdl", "mu_s", "sig_s", "featNames");

fprintf("✅ Model saved to:\n  %s\n", fullfile(outDir, 'speaker_model.mat'));
fprintf("🎯 You can now build the enrollment DB using build_enrollment_db.m\n");
%% 
