% build_enrollment_db.m
clear; clc; load('config_paths.mat');

ALLOWED_USERS = ["1","7","13"];   % <-- use this style

featDir = fullfile(PROJECT_ROOT,'outputs','features');
Ttr = readtable(fullfile(featDir,'features_train_speaker.csv'));

M  = load(fullfile(PROJECT_ROOT,'outputs','models','speaker_model.mat'));
featNames = string(M.featNames); mu = M.mu_s; sg = M.sig_s;

E = struct(); keep = false(size(ALLOWED_USERS));
for i = 1:numel(ALLOWED_USERS)
    uid = ALLOWED_USERS(i);
    rows = string(Ttr.label) == uid;
    if ~any(rows)
        warning("No TRAIN rows for %s", uid); continue;
    end
    Z = (Ttr{rows,featNames} - mu) ./ sg;
    E.(sprintf('U_%s', uid)) = mean(Z,1);
    keep(i) = true;
end
ALLOWED_USERS = ALLOWED_USERS(keep);

outDir = fullfile(PROJECT_ROOT,'outputs','models');
if ~isfolder(outDir), mkdir(outDir); end
save(fullfile(outDir,'enrollment_db.mat'), "E","ALLOWED_USERS","featNames","mu","sg");
fprintf('✅ Enrollment DB saved for: %s\n', strjoin(ALLOWED_USERS, ", "));
