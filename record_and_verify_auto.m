%% record_and_verify_auto.m — record if a mic exists; otherwise use a prerecorded WAV
clear; clc; close all;

CLAIMED_USER = "13";   % change as needed
REC_SECONDS  = 1.0;    % record length if mic exists
FS           = 48000;  % must match your training extractor

load('config_paths.mat');  % defines PROJECT_ROOT, AUDIO_MNIST_ROOT
outDir = fullfile(PROJECT_ROOT,'outputs','runtime');
if ~isfolder(outDir), mkdir(outDir); end

% ---------- check mic availability ----------
devInfo = audiodevinfo;
hasMic  = ~isempty(devInfo.input);

if hasMic
    % --------- RECORD FROM MIC ----------
    fprintf("🎙️  Mic detected. Speak now for %.1f s...\n", REC_SECONDS);
    recObj = audiorecorder(FS, 16, 1);
    recordblocking(recObj, REC_SECONDS);
    x = getaudiodata(recObj);
    x = x - mean(x); x = x ./ max(1e-9, max(abs(x)));
    wavFile = fullfile(outDir, sprintf('trial_%s_%s.wav', CLAIMED_USER, datestr(now,'HHMMSS')));
    audiowrite(wavFile, x, FS);
    fprintf("💾 Saved recording: %s (%.2f s)\n", wavFile, numel(x)/FS);
else
    % --------- FALLBACK: USE PRERECORDED WAV ----------
    fprintf("⚠️  No input device found. Using a prerecorded WAV for user %s.\n", CLAIMED_USER);
    S = dir(fullfile(AUDIO_MNIST_ROOT,'**',"*_"+CLAIMED_USER+"_*"+".wav"));
    if isempty(S)
        error("No WAVs found for user %s under %s", CLAIMED_USER, AUDIO_MNIST_ROOT);
    end
    % pick the first file (or random: S(randi(numel(S))))
    wavFile = fullfile(S(1).folder, S(1).name);
    fprintf("🎧 Using file: %s\n", wavFile);
    [x, FS] = audioread(wavFile);  % for plotting
end

% ---------- VERIFY ----------
res = verify_user_minimal(wavFile, CLAIMED_USER);
disp(res);

% ---------- quick plot ----------
try
    if size(x,2)>1, x = mean(x,2); end
    t = (0:numel(x)-1)/FS;
    figure('Color','w','Position',[100,100,900,280]);
    plot(t,x); grid on; xlabel('Time (s)'); ylabel('Amplitude');
    title(sprintf('Claim=%s | Accept=%s | Pred=%s', ...
          res.claimedUser, string(res.accept), res.predictedUser));
catch
    % plotting is optional
end
