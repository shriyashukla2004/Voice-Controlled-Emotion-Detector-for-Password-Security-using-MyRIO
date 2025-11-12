% sanity_check_model_on_csv.m
clear; clc; load('config_paths.mat');

featDir = fullfile(PROJECT_ROOT,'outputs','features');
Tte = readtable(fullfile(featDir,'features_test_speaker.csv'));

M = load(fullfile(PROJECT_ROOT,'outputs','models','speaker_model.mat'));
mdl = M.speakerMdl; mu = M.mu_s; sg = M.sig_s; featNames = string(M.featNames);

Xte = Tte{:,featNames};
Yte = string(Tte.label);
Zte = (Xte - mu)./sg;

yhat = string(predict(mdl, Zte));
fprintf("TEST overall acc: %.3f\n", mean(yhat==Yte));

mask13 = (Yte=="13");
if any(mask13)
    fprintf("User 13 acc on CSV: %.3f (N=%d)\n", mean(yhat(mask13)==Yte(mask13)), nnz(mask13));
else
    fprintf("No 13 in TEST CSV.\n");
end
